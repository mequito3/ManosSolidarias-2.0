import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/solicitud_controller.dart';
import '../../models/solicitud.dart';
import '../../models/user_profile.dart';
import '../../services/face_redaction_service.dart';
import '../../services/solicitud_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/face_redaction_preview.dart';
import 'steps/kermesse_location_picker_page.dart';
import 'steps/solicitud_form_step.dart';
import 'steps/solicitud_profile_review_step.dart';
import 'steps/solicitud_type_step.dart';

enum _SolicitudFlowStep { landing, typeSelection, profileReview, form }
enum _EvidencePickerChoice { camera, gallery }

class CreateSolicitudPage extends StatefulWidget {
  const CreateSolicitudPage({
    super.key,
    required this.profile,
    this.startAtTypeSelection = false,
    this.initialTipo,
  });

  final UserProfile profile;
  final bool startAtTypeSelection;

  /// Si se provee, la pagina inicia con este tipo preseleccionado y salta el
  /// paso de seleccion de tipo. Util para flujos dedicados como "Crear kermesse".
  final SolicitudTipo? initialTipo;

  @override
  State<CreateSolicitudPage> createState() => _CreateSolicitudPageState();
}

class _CreateSolicitudPageState extends State<CreateSolicitudPage> {
  late final SolicitudService _service;
  late final SolicitudController _controller;
  late final FaceRedactionService _faceService;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _goalCtrl = TextEditingController();
  final TextEditingController _beneficiaryNameCtrl = TextEditingController();
  final Map<String, TextEditingController> _extraControllers = {};

  final ImagePicker _picker = ImagePicker();
  Uint8List? _coverPreviewBytes;
  String? _uploadedCoverUrl;
  String? _uploadedCoverOriginalUrl;
  bool _uploadingCover = false;
  static const int _maxCoverBytes = 3 * 1024 * 1024;
  static const int _maxEvidenceItems = 12;

  late _SolicitudFlowStep _currentStep;
  SolicitudTipo _selectedTipo = SolicitudTipo.campania;
  bool _acceptsGuidelines = false;
  bool _esAnonimo = false;
  bool _anonymousWarningShown = false;
  bool _showValidation = false;
  bool _isUploadingEvidence = false;
  final List<SolicitudEvidenceUpload> _evidenceUploads = [];
  String? _beneficiaryRelationship;
  DateTime? _kermesseStartDateTime;
  SolicitudKermesseLocation? _kermesseLocation;
  final List<SolicitudKermesseMenuItem> _kermesseMenuItems = [];
  final List<SolicitudKermesseActivity> _kermesseActivities = [];
  bool _useManualKermesseCoords = false;
  static const List<String> _relationshipOptions = [
    'Soy beneficiario/a directo/a',
    'Familiar directo (madre, padre, hermano/a)',
    'Tutor/a o representante legal',
    'Amigo/a o comunidad cercana',
    'Voluntario/a de la organización',
    'Otro (lo explicaré en la descripción)',
  ];

  @override
  void initState() {
    super.initState();
    assert(
      widget.profile.canCreateCampaign,
      'El perfil debe tener datos personales y financieros antes de crear campañas.',
    );
    _service = SolicitudService(Supabase.instance.client);
    _controller = SolicitudController(_service);
    _faceService = FaceRedactionService();
    _beneficiaryRelationship = _relationshipOptions.first;
    // initialTipo tiene prioridad: pre-selecciona el tipo y salta a profileReview
    if (widget.initialTipo != null) {
      _selectedTipo = widget.initialTipo!;
      _currentStep = _SolicitudFlowStep.profileReview;
    } else {
      _currentStep = widget.startAtTypeSelection
          ? _SolicitudFlowStep.typeSelection
          : _SolicitudFlowStep.landing;
    }
    _controller.addListener(_handleControllerChange);
    _controller.loadInitialData();
  }

  Widget _buildLandingStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero banner
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.bluePrimary.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 24,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Comparte tu causa',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crea una campaña o kermesse solidaria y conecta con personas que quieren apoyarte.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Checklist card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.bluePrimary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.orangeAction.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: AppColors.orangeAction,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Antes de empezar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _LandingCheckItem(
                icon: Icons.image_rounded,
                color: AppColors.bluePrimary,
                text: 'Foto de portada horizontal (máx. 3 MB)',
              ),
              const _LandingCheckItem(
                icon: Icons.monetization_on_rounded,
                color: Color(0xFF4CAF50),
                text: 'Meta económica en bolivianos (Bs)',
              ),
              const _LandingCheckItem(
                icon: Icons.description_rounded,
                color: AppColors.orangeAction,
                text: 'Descripción detallada de cómo usarás lo recaudado',
              ),
              const _LandingCheckItem(
                icon: Icons.photo_library_rounded,
                color: Color(0xFF9C27B0),
                text: 'Al menos 2 fotos de evidencia para validación',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Info note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bluePrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.bluePrimary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.bluePrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tu solicitud será revisada por el equipo antes de publicarse. Te notificaremos por correo con el resultado.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.bluePrimary.withValues(alpha: 0.8),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTypeSelectionStep() {
    // Solo campanas se crean por este flujo. Las kermesses tienen su propio
    // boton en el tab de Kermesses del Home (CreateSolicitudPage(initialTipo: kermesse)).
    return SolicitudTypeStep(
      configs: [
        solicitudTypeConfigs[SolicitudTipo.campania]!,
      ],
      selectedTipo: _selectedTipo,
      onTipoChanged: _onTipoChanged,
      onBack: () => _goToStep(_SolicitudFlowStep.landing),
      onNext: () => _goToStep(_SolicitudFlowStep.profileReview),
    );
  }

  Widget _buildProfileReviewStep() {
    return SolicitudProfileReviewStep(
      profile: widget.profile,
      tipo: _selectedTipo,
      onBack: () => _goToStep(_SolicitudFlowStep.landing),
      onNext: () => _goToStep(_SolicitudFlowStep.form),
    );
  }

  Widget _buildFormStep() {
    final config = solicitudTypeConfigs[_selectedTipo]!;
    for (final field in config.extraFields) {
      _extraControllerFor(field.id);
    }

    return SolicitudFormStep(
      formKey: _formKey,
      autovalidate: _showValidation,
      isSubmitting: _controller.isSubmitting,
      config: config,
      tipo: _selectedTipo,
      titleCtrl: _titleCtrl,
      descriptionCtrl: _descriptionCtrl,
      goalCtrl: _goalCtrl,
      beneficiaryNameCtrl: _beneficiaryNameCtrl,
      extraControllers: _extraControllers,
      evidenceUploads: _evidenceUploads,
      isUploadingEvidence: _isUploadingEvidence,
      maxEvidenceItems: _maxEvidenceItems,
      onAddEvidence: _openEvidenceSourceSheet,
      onRemoveEvidence: _removeEvidenceAt,
      acceptsGuidelines: _acceptsGuidelines,
      onAcceptGuidelinesChanged: (value) =>
          setState(() => _acceptsGuidelines = value ?? false),
      esAnonimo: _esAnonimo,
      onEsAnonimoChanged: _handleEsAnonimoChanged,
      onBack: () => _goToStep(_SolicitudFlowStep.profileReview),
      onSubmit: _submitSolicitud,
      onCancel: () => Navigator.of(context).maybePop(),
      relationshipOptions: _relationshipOptions,
      beneficiaryRelationship: _beneficiaryRelationship,
      onRelationshipChanged: (value) =>
          setState(() => _beneficiaryRelationship = value),
      submitError: _controller.submitError,
      onPickKermesseDate: _pickKermesseDateTime,
      kermesseLocation: _kermesseLocation,
    onPickKermesseLocation: _pickKermesseLocation,
    onClearKermesseLocation: _clearKermesseLocation,
    useManualKermesseCoords: _useManualKermesseCoords,
    onManualKermesseCoordsChanged: _setManualKermesseCoords,
      menuItems: _kermesseMenuItems,
      onAddMenuItem: _addMenuItem,
      onEditMenuItem: _editMenuItem,
      onRemoveMenuItem: _removeMenuItem,
      activityItems: _kermesseActivities,
      onAddActivity: _addActivity,
      onEditActivity: _editActivity,
      onRemoveActivity: _removeActivity,
      onPickCover: _openCoverSourceSheet,
      onRemoveCover: _removeCoverImage,
      coverPreviewBytes: _coverPreviewBytes,
      uploadingCover: _uploadingCover,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    _faceService.close();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _goalCtrl.dispose();
    _beneficiaryNameCtrl.dispose();
    for (final ctrl in _extraControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _handleEsAnonimoChanged(bool value) async {
    if (!value) {
      setState(() => _esAnonimo = false);
      return;
    }
    setState(() => _esAnonimo = true);
    if (_anonymousWarningShown) return;
    _anonymousWarningShown = true;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.orangeAction.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.privacy_tip_rounded,
              color: AppColors.orangeAction, size: 32),
        ),
        title: const Text(
          'Tu solicitud será anónima',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu nombre, contacto y dirección NO aparecerán en la vista pública. '
              'Solo el equipo administrador podrá verlos para validar la solicitud.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_fix_high_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Al subir cada foto, detectamos automáticamente los '
                      'rostros y los tachamos antes de publicar. Vas a poder '
                      'revisar y confirmar el resultado antes de subir.\n\n'
                      'Recuerda cubrir manualmente:\n'
                      '• Nombres, cédulas y direcciones visibles\n'
                      '• Fechas u otros datos personales\n\n'
                      'La detección automática solo cubre caras.',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: AppColors.darkText,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _handleControllerChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _goToStep(_SolicitudFlowStep step) {
    if (!mounted) {
      return;
    }
    setState(() {
      if (step != _SolicitudFlowStep.form) {
        _showValidation = false;
      }
      _currentStep = step;
    });
  }

  TextEditingController _extraControllerFor(String fieldId) {
    return _extraControllers.putIfAbsent(fieldId, () => TextEditingController());
  }

  Future<void> _submitSolicitud() async {
    final formState = _formKey.currentState;
    if (formState == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _showValidation = true);

    if (!formState.validate()) {
      return;
    }
    if (_selectedTipo == SolicitudTipo.campania && _evidenceUploads.length < 2) {
      _showSnack('Sube al menos dos fotos de evidencia para respaldar la campaña.');
      return;
    }
    if (!_acceptsGuidelines) {
      _showSnack('Confirma que asumirás la responsabilidad de la campaña.');
      return;
    }

    final goal = _parseAmount(_goalCtrl.text.trim());
    if (_goalCtrl.text.trim().isNotEmpty && (goal == null || goal <= 0)) {
      _showSnack('Ingresa un monto objetivo válido.');
      return;
    }

    if (_selectedTipo == SolicitudTipo.kermesse) {
      final latText = _extraControllerFor('event_location_lat').text.trim();
      final lngText = _extraControllerFor('event_location_lng').text.trim();
      final hasCoordinates = latText.isNotEmpty && lngText.isNotEmpty;
      if (!hasCoordinates) {
        _showSnack('Selecciona la ubicación en el mapa o ingresa las coordenadas manualmente.');
        return;
      }
    }

    final description = _mergeDescriptionWithExtras();
    final normalizedTitle = _clampTitle(_titleCtrl.text);
    final draft = SolicitudDraft(
      titulo: normalizedTitle,
      descripcion: description,
      tipo: _selectedTipo,
      montoObjetivo: goal,
      portadaUrl: _uploadedCoverUrl,
      esAnonimo: _esAnonimo,
    );

    final solicitud = await _controller.submitSolicitud(draft);
    if (!mounted) {
      return;
    }
    if (_controller.submitError != null) {
      _showSnack(_controller.submitError!);
      return;
    }
    if (solicitud != null) {
      _showSnack('Solicitud enviada. Te avisaremos por correo cuando sea revisada.');
      Navigator.of(context).pop<bool>(true);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  double? _parseAmount(String raw) {
    if (raw.isEmpty) {
      return null;
    }
    final normalized = raw.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _clampTitle(String raw) {
    final words = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return '';
    }
    final limited = words.take(solicitudTitleMaxWords).toList();
    final joined = limited.join(' ');
    if (joined.length <= solicitudTitleMaxCharacters) {
      return joined;
    }
    return joined.substring(0, solicitudTitleMaxCharacters).trimRight();
  }

  Future<void> _openCoverSourceSheet() async {
    if (_controller.isSubmitting) {
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ImageSourceSheet(
          title: 'Foto de portada',
          subtitle: 'Elige la imagen principal de tu campaña',
          cameraLabel: 'Tomar foto',
          galleryLabel: 'Elegir de la galería',
          onCamera: () => Navigator.of(context).pop(ImageSource.camera),
          onGallery: () => Navigator.of(context).pop(ImageSource.gallery),
        );
      },
    );
    if (source == null) {
      return;
    }
    await _pickCoverImage(source);
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) {
        return;
      }
      final originalBytes = await file.readAsBytes();
      if (!_validateImageSize(originalBytes.length)) {
        return;
      }
      if (!mounted) {
        return;
      }

      var bytesToUpload = originalBytes;
      if (_esAnonimo) {
        final result = await FaceRedactionPreview.show(
          context,
          imageBytes: originalBytes,
          imagePath: file.path,
          service: _faceService,
          sensitiveNames: _collectSensitiveNames(),
        );
        if (!mounted) return;
        if (result == null) {
          return;
        }
        bytesToUpload = result.redactedBytes;
      }

      setState(() => _uploadingCover = true);

      final extension = _resolveExtension(file.name);
      final contentType = _resolveContentType(extension);
      final uploadedUrl = await _controller.uploadCoverImage(
        data: bytesToUpload,
        contentType: contentType,
        fileExtension: extension,
      );

      // Si era anónima, también subimos el cover original para que el
      // admin pueda revisarlo durante la moderación.
      String? originalCoverUrl;
      if (_esAnonimo && !identical(bytesToUpload, originalBytes)) {
        try {
          originalCoverUrl = await _controller.uploadCoverImage(
            data: originalBytes,
            contentType: contentType,
            fileExtension: extension,
          );
        } catch (_) {
          originalCoverUrl = null;
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _coverPreviewBytes = bytesToUpload;
        _uploadedCoverUrl = uploadedUrl;
        _uploadedCoverOriginalUrl = originalCoverUrl;
      });
      _showSnack('Imagen subida correctamente.');
    } on SolicitudServiceException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('No pudimos subir la imagen seleccionada.');
    } finally {
      if (mounted) {
        setState(() => _uploadingCover = false);
      }
    }
  }

  Future<void> _openEvidenceSourceSheet() async {
    if (_controller.isSubmitting || _isUploadingEvidence) {
      return;
    }
    final remainingSlots = _maxEvidenceItems - _evidenceUploads.length;
    if (remainingSlots <= 0) {
      _showSnack('Ya subiste el máximo de evidencias permitidas.');
      return;
    }

    final _EvidencePickerChoice? choice = await showModalBottomSheet<_EvidencePickerChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ImageSourceSheet(
          title: 'Agregar evidencia',
          subtitle: 'Fotos que respaldan tu solicitud ($remainingSlots restantes)',
          cameraLabel: 'Tomar foto',
          galleryLabel: 'Elegir varias de la galería',
          onCamera: () => Navigator.of(context).pop(_EvidencePickerChoice.camera),
          onGallery: () => Navigator.of(context).pop(_EvidencePickerChoice.gallery),
        );
      },
    );

    if (choice == null) {
      return;
    }

    switch (choice) {
      case _EvidencePickerChoice.camera:
        await _pickEvidenceFromCamera();
        break;
      case _EvidencePickerChoice.gallery:
        await _pickEvidenceFromGallery();
        break;
    }
  }

  Future<void> _pickEvidenceFromCamera() async {
    if (!mounted) {
      return;
    }
    try {
      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file == null) {
        return;
      }
      setState(() => _isUploadingEvidence = true);
      await _handleEvidenceFile(file);
      if (mounted) {
        _showSnack('Evidencia subida correctamente.');
      }
    } on SolicitudServiceException catch (error) {
      if (mounted) {
        _showSnack(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('No pudimos subir la evidencia seleccionada.');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingEvidence = false);
      }
    }
  }

  Future<void> _pickEvidenceFromGallery() async {
    final remainingSlots = _maxEvidenceItems - _evidenceUploads.length;
    if (remainingSlots <= 0) {
      _showSnack('Ya subiste el máximo de evidencias permitidas.');
      return;
    }

    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      if (files.isEmpty) {
        return;
      }
      final selected = files.take(remainingSlots);
      if (mounted) {
        setState(() => _isUploadingEvidence = true);
      }
      for (final file in selected) {
        await _handleEvidenceFile(file);
      }
      if (mounted) {
        _showSnack('Evidencias subidas correctamente.');
      }
    } on SolicitudServiceException catch (error) {
      if (mounted) {
        _showSnack(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('No pudimos subir una de las evidencias seleccionadas.');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingEvidence = false);
      }
    }
  }

  Future<void> _handleEvidenceFile(XFile file) async {
    final originalBytes = await file.readAsBytes();
    if (!_validateImageSize(originalBytes.length)) {
      return;
    }
    if (!mounted) {
      return;
    }

    var bytesToUpload = originalBytes;
    if (_esAnonimo) {
      final result = await FaceRedactionPreview.show(
        context,
        imageBytes: originalBytes,
        imagePath: file.path,
        service: _faceService,
        sensitiveNames: _collectSensitiveNames(),
      );
      if (!mounted) return;
      if (result == null) {
        return; // usuario canceló desde el preview
      }
      bytesToUpload = result.redactedBytes;
    }

    final extension = _resolveExtension(file.name);
    final contentType = _resolveContentType(extension);
    final uploadedUrl = await _controller.uploadEvidenceImage(
      data: bytesToUpload,
      contentType: contentType,
      fileExtension: extension,
    );
    if (!mounted) {
      return;
    }

    // Cuando es anónima, subimos también el original aparte para que el
    // admin pueda verificar identidad sin que se publique en el feed.
    String? originalUploadUrl;
    if (_esAnonimo && !identical(bytesToUpload, originalBytes)) {
      try {
        originalUploadUrl = await _controller.uploadEvidenceImage(
          data: originalBytes,
          contentType: contentType,
          fileExtension: extension,
        );
      } catch (_) {
        // Si falla el upload del original, conservamos al menos el público.
        originalUploadUrl = null;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _evidenceUploads.add(SolicitudEvidenceUpload(
        bytes: bytesToUpload,
        url: uploadedUrl,
        originalUrl: originalUploadUrl,
      ));
    });
  }

  /// Strings que tratamos como PII al hacer OCR sobre las evidencias.
  /// Incluye el nombre del usuario que está creando la solicitud y el
  /// nombre del beneficiario (si se ingresó) para campañas.
  List<String> _collectSensitiveNames() {
    final names = <String>[];
    final userName = widget.profile.displayName?.trim() ?? '';
    if (userName.isNotEmpty) {
      names.add(userName);
      // También cada palabra del nombre por separado (>= 3 chars) para
      // que coincida con apariciones parciales como apellido suelto.
      for (final part in userName.split(RegExp(r'\s+'))) {
        if (part.length >= 3 && !names.contains(part)) {
          names.add(part);
        }
      }
    }
    final beneficiary = _beneficiaryNameCtrl.text.trim();
    if (beneficiary.isNotEmpty) {
      names.add(beneficiary);
      for (final part in beneficiary.split(RegExp(r'\s+'))) {
        if (part.length >= 3 && !names.contains(part)) {
          names.add(part);
        }
      }
    }
    return names;
  }

  Future<void> _pickKermesseDateTime() async {
    if (_controller.isSubmitting) {
      return;
    }
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final initialDate = _kermesseStartDateTime ?? now;
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      helpText: 'Selecciona la fecha de inicio',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (selectedDate == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final initialTime = TimeOfDay.fromDateTime(_kermesseStartDateTime ?? now);
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Selecciona la hora de inicio',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (selectedTime == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final combined = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final localizations = MaterialLocalizations.of(context);
    final formattedDate = localizations.formatFullDate(selectedDate);
    final formattedTime = localizations.formatTimeOfDay(
      selectedTime,
      alwaysUse24HourFormat: true,
    );

    setState(() {
      _kermesseStartDateTime = combined;
      _extraControllerFor('event_date').text = '$formattedDate · $formattedTime';
    });
  }

  Future<void> _pickKermesseLocation() async {
    if (_controller.isSubmitting) {
      return;
    }
    FocusScope.of(context).unfocus();

    try {
      final location = await Navigator.of(context).push<SolicitudKermesseLocation>(
        MaterialPageRoute(
          builder: (_) => KermesseLocationPickerPage(initialLocation: _kermesseLocation),
          fullscreenDialog: true,
        ),
      );
      if (location == null || !mounted) {
        return;
      }

      setState(() {
        _kermesseLocation = location;
        _useManualKermesseCoords = false;
        _extraControllerFor('event_location_lat').text = location.latitude.toStringAsFixed(6);
        _extraControllerFor('event_location_lng').text = location.longitude.toStringAsFixed(6);
        if ((location.address?.isNotEmpty ?? false) &&
            _extraControllerFor('event_location_name').text.trim().isEmpty) {
          _extraControllerFor('event_location_name').text = location.address!;
        }
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack('No pudimos abrir el mapa (${error.code}). Ingresa las coordenadas manualmente.');
      _setManualKermesseCoords(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('No pudimos abrir el mapa. Intenta de nuevo o ingresa las coordenadas manualmente.');
      _setManualKermesseCoords(true);
    }
  }

  void _clearKermesseLocation() {
    if (_controller.isSubmitting) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _kermesseLocation = null;
      if (!_useManualKermesseCoords) {
        _useManualKermesseCoords = true;
      }
      _extraControllerFor('event_location_lat').clear();
      _extraControllerFor('event_location_lng').clear();
    });
  }

  void _setManualKermesseCoords(bool enable) {
    if (!mounted) {
      return;
    }
    setState(() {
      _useManualKermesseCoords = enable;
      if (!enable && _kermesseLocation == null) {
        _extraControllerFor('event_location_lat').clear();
        _extraControllerFor('event_location_lng').clear();
      }
    });
  }

  Future<void> _addMenuItem() async {
    final item = await _promptMenuItem();
    if (item == null || !mounted) {
      return;
    }
    setState(() => _kermesseMenuItems.add(item));
  }

  Future<void> _editMenuItem(int index) async {
    if (index < 0 || index >= _kermesseMenuItems.length) {
      return;
    }
    final current = _kermesseMenuItems[index];
    final updated = await _promptMenuItem(initial: current);
    if (updated == null || !mounted) {
      return;
    }
    setState(() => _kermesseMenuItems[index] = updated);
  }

  void _removeMenuItem(int index) {
    if (_controller.isSubmitting || _isUploadingEvidence) {
      return;
    }
    if (index < 0 || index >= _kermesseMenuItems.length) {
      return;
    }
    setState(() => _kermesseMenuItems.removeAt(index));
  }

  Future<SolicitudKermesseMenuItem?> _promptMenuItem({SolicitudKermesseMenuItem? initial}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: initial?.name ?? '');
    final priceCtrl = TextEditingController(
      text: initial?.price != null ? initial!.price!.toStringAsFixed(2) : '',
    );

    return showDialog<SolicitudKermesseMenuItem>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(initial == null ? 'Añadir plato' : 'Editar plato'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del plato o puesto',
                    hintText: 'Ej.: Sopa de maní',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Indica el nombre del plato.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Precio sugerido (Bs)',
                    hintText: 'Ej.: 15.50',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return null;
                    }
                    final parsed = _parseAmount(text);
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un precio válido o déjalo vacío.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                final priceText = priceCtrl.text.trim();
                final parsedPrice = priceText.isEmpty ? null : _parseAmount(priceText);
                Navigator.of(context).pop(
                  SolicitudKermesseMenuItem(
                    name: nameCtrl.text.trim(),
                    price: parsedPrice,
                  ),
                );
              },
              child: Text(initial == null ? 'Añadir' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addActivity() async {
    final activity = await _promptActivity();
    if (activity == null || !mounted) {
      return;
    }
    setState(() => _kermesseActivities.add(activity));
  }

  Future<void> _editActivity(int index) async {
    if (index < 0 || index >= _kermesseActivities.length) {
      return;
    }
    final current = _kermesseActivities[index];
    final updated = await _promptActivity(initial: current);
    if (updated == null || !mounted) {
      return;
    }
    setState(() => _kermesseActivities[index] = updated);
  }

  void _removeActivity(int index) {
    if (_controller.isSubmitting || _isUploadingEvidence) {
      return;
    }
    if (index < 0 || index >= _kermesseActivities.length) {
      return;
    }
    setState(() => _kermesseActivities.removeAt(index));
  }

  Future<SolicitudKermesseActivity?> _promptActivity({SolicitudKermesseActivity? initial}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: initial?.name ?? '');
    final detailCtrl = TextEditingController(text: initial?.detail ?? '');

    return showDialog<SolicitudKermesseActivity>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(initial == null ? 'Añadir show o actividad' : 'Editar show o actividad'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del grupo o actividad',
                    hintText: 'Ej.: Banda Juventud Alegre',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Indica el nombre del show o actividad.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: detailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Horario, costo u otro detalle',
                    hintText: 'Ej.: 20:30 - Escenario principal',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.of(context).pop(
                  SolicitudKermesseActivity(
                    name: nameCtrl.text.trim(),
                    detail: detailCtrl.text.trim(),
                  ),
                );
              },
              child: Text(initial == null ? 'Añadir' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _removeEvidenceAt(int index) {
    if (_controller.isSubmitting || _isUploadingEvidence) {
      return;
    }
    if (index < 0 || index >= _evidenceUploads.length) {
      return;
    }
    setState(() {
      _evidenceUploads.removeAt(index);
    });
  }

  bool _validateImageSize(int length) {
    if (length <= _maxCoverBytes) {
      return true;
    }
    _showSnack('Selecciona imágenes de hasta 3 MB.');
    return false;
  }

  String _resolveExtension(String filename) {
    final index = filename.lastIndexOf('.');
    if (index == -1) {
      return 'jpg';
    }
    return filename.substring(index + 1).toLowerCase();
  }

  String _resolveContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  void _removeCoverImage() {
    if (_controller.isSubmitting) {
      return;
    }
    setState(() {
      _coverPreviewBytes = null;
      _uploadedCoverUrl = null;
      _uploadedCoverOriginalUrl = null;
    });
  }

  String _mergeDescriptionWithExtras() {
    final base = _descriptionCtrl.text.trim();
    final config = solicitudTypeConfigs[_selectedTipo];
    if (config == null) {
      return base;
    }
    final filledExtras = <String>[];
    for (final field in config.extraFields) {
      if (_selectedTipo == SolicitudTipo.kermesse &&
          (field.id == 'event_location_lat' || field.id == 'event_location_lng')) {
        continue;
      }
      final text = _extraControllerFor(field.id).text.trim();
      if (text.isEmpty) {
        continue;
      }
      filledExtras.add('${field.label}: $text');
    }
    final evidenceUrls = _evidenceUploads.map((item) => item.url).toList();
    final evidenceOriginals = _evidenceUploads
        .where((item) => item.originalUrl != null)
        .map((item) => item.originalUrl!)
        .toList();

    if (filledExtras.isEmpty &&
        evidenceUrls.isEmpty &&
        _uploadedCoverOriginalUrl == null) {
      return base;
    }

    final buffer = StringBuffer();
    if (base.isNotEmpty) {
      buffer.writeln(base);
      buffer.writeln();
    }

    if (_selectedTipo == SolicitudTipo.campania) {
      final beneficiaryName = _beneficiaryNameCtrl.text.trim();
      final relationship = _beneficiaryRelationship?.trim() ?? '';
      if (beneficiaryName.isNotEmpty || relationship.isNotEmpty) {
        buffer.writeln('Datos del beneficiario:');
        if (beneficiaryName.isNotEmpty) {
          buffer.writeln('- Nombre: $beneficiaryName');
        }
        if (relationship.isNotEmpty) {
          buffer.writeln('- Relacion: $relationship');
        }
        buffer.writeln();
      }
    } else if (_selectedTipo == SolicitudTipo.kermesse) {
      final location = _kermesseLocation;
      if (location != null) {
        buffer.writeln('Ubicacion confirmada en mapa:');
        if (location.address != null && location.address!.isNotEmpty) {
          buffer.writeln('- Direccion: ${location.address}');
        }
        buffer.writeln('- Coordenadas: ${location.coordinatesLabel}');
        buffer.writeln();
      } else {
        final latText = _extraControllerFor('event_location_lat').text.trim();
        final lngText = _extraControllerFor('event_location_lng').text.trim();
        if (latText.isNotEmpty && lngText.isNotEmpty) {
          buffer.writeln('Coordenadas de referencia:');
          buffer.writeln('- Latitud: $latText');
          buffer.writeln('- Longitud: $lngText');
          buffer.writeln();
        }
      }

      if (_kermesseMenuItems.isNotEmpty) {
        buffer.writeln('Menu y precios sugeridos:');
        for (final item in _kermesseMenuItems) {
          final priceText = item.price != null ? ' (Bs ${item.price!.toStringAsFixed(2)})' : '';
          buffer.writeln('- ${item.name}$priceText');
        }
        buffer.writeln();
      }

      if (_kermesseActivities.isNotEmpty) {
        buffer.writeln('Shows y actividades confirmadas:');
        for (final activity in _kermesseActivities) {
          final detail = activity.detail?.trim();
          if (detail != null && detail.isNotEmpty) {
            buffer.writeln('- ${activity.name} · $detail');
          } else {
            buffer.writeln('- ${activity.name}');
          }
        }
        buffer.writeln();
      }
    }

    if (filledExtras.isNotEmpty) {
      final sectionTitle = config.extraSectionTitle.isEmpty
          ? 'Detalles adicionales'
          : config.extraSectionTitle;
      buffer.writeln('$sectionTitle:');
      for (final line in filledExtras) {
        buffer.writeln('- $line');
      }
      buffer.writeln();
    }

    if (evidenceUrls.isNotEmpty) {
      buffer.writeln('Evidencias fotográficas:');
      for (final url in evidenceUrls) {
        buffer.writeln('- $url');
      }
      buffer.writeln();
    }

    if (evidenceOriginals.isNotEmpty || _uploadedCoverOriginalUrl != null) {
      buffer.writeln('--- VERIFICACION ADMIN (no publicar) ---');
      if (_uploadedCoverOriginalUrl != null) {
        buffer.writeln('Portada original sin tachar:');
        buffer.writeln('- $_uploadedCoverOriginalUrl');
      }
      if (evidenceOriginals.isNotEmpty) {
        buffer.writeln('Evidencias originales sin tachar:');
        for (final url in evidenceOriginals) {
          buffer.writeln('- $url');
        }
      }
    }

    return buffer.toString().trim();
  }

  void _onTipoChanged(SolicitudTipo tipo) {
    if (_selectedTipo == tipo) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedTipo = tipo;
      if (tipo == SolicitudTipo.kermesse) {
        _goalCtrl.clear();
        if (_kermesseLocation == null) {
          _useManualKermesseCoords = false;
        }
      } else {
        _kermesseStartDateTime = null;
        final controller = _extraControllers['event_date'];
        controller?.clear();
        _extraControllers['event_location_lat']?.clear();
        _extraControllers['event_location_lng']?.clear();
        _kermesseLocation = null;
        _kermesseMenuItems.clear();
        _kermesseActivities.clear();
        _useManualKermesseCoords = false;
      }
    });
  }

  /// Si el usuario entró con un tipo preseleccionado (ej. FAB de kermesse),
  /// el wizard arranca en profileReview saltando landing. En ese caso
  /// mostramos un counter de 2 pasos en vez de 3.
  bool get _isShortFlow => widget.initialTipo != null;

  int get _displayStepIndex {
    if (_isShortFlow) {
      switch (_currentStep) {
        case _SolicitudFlowStep.profileReview:
          return 0;
        case _SolicitudFlowStep.form:
          return 1;
        case _SolicitudFlowStep.landing:
        case _SolicitudFlowStep.typeSelection:
          return 0;
      }
    }
    switch (_currentStep) {
      case _SolicitudFlowStep.landing:
        return 0;
      case _SolicitudFlowStep.typeSelection:
      case _SolicitudFlowStep.profileReview:
        return 1;
      case _SolicitudFlowStep.form:
        return 2;
    }
  }

  int get _displayStepTotal => _isShortFlow ? 2 : 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _SolicitudAppBar(
        stepIndex: _displayStepIndex,
        stepTotal: _displayStepTotal,
        tipo: _selectedTipo,
        isShortFlow: _isShortFlow,
      ),
      floatingActionButton: _currentStep == _SolicitudFlowStep.landing
          ? Container(
              decoration: BoxDecoration(
                gradient: AppColors.actionGradient,
                borderRadius: BorderRadius.circular(AppColors.radiusRound),
                boxShadow: AppColors.shadowLg,
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _goToStep(_SolicitudFlowStep.profileReview),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                label: const Text(
                  'Comenzar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading && !_controller.hasLoaded) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.bluePrimary),
              );
            }
            if (_controller.loadError != null && !_controller.hasLoaded) {
              return _LoadErrorView(
                message: _controller.loadError!,
                onRetry: () => _controller.loadInitialData(forceRefresh: true),
              );
            }
            Widget stepContent;
            switch (_currentStep) {
              case _SolicitudFlowStep.landing:
                stepContent = _buildLandingStep(theme);
                break;
              case _SolicitudFlowStep.typeSelection:
                stepContent = _buildTypeSelectionStep();
                break;
              case _SolicitudFlowStep.profileReview:
                stepContent = _buildProfileReviewStep();
                break;
              case _SolicitudFlowStep.form:
                stepContent = _buildFormStep();
                break;
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: _currentStep == _SolicitudFlowStep.landing ? 100 : 24,
                  ),
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: stepContent,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Styled app bar with step progress ────────────────────────────────────────

class _SolicitudAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SolicitudAppBar({
    required this.stepIndex,
    required this.stepTotal,
    required this.tipo,
    required this.isShortFlow,
  });

  final int stepIndex;
  final int stepTotal;
  final SolicitudTipo tipo;
  final bool isShortFlow;

  static const _stepLabelsLong = ['Inicio', 'Perfil', 'Formulario'];
  static const _stepLabelsShort = ['Perfil', 'Formulario'];

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final labels = isShortFlow ? _stepLabelsShort : _stepLabelsLong;
    final safeIndex = stepIndex.clamp(0, labels.length - 1);
    final titleText =
        tipo == SolicitudTipo.kermesse ? 'Nueva kermesse' : 'Nueva campaña';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: AppColors.darkText,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Volver',
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                'Paso ${safeIndex + 1} de $stepTotal · ${labels[safeIndex]}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkText.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          centerTitle: false,
        ),
        // Step progress bar
        Container(
          height: 3,
          color: AppColors.dividerColor.withValues(alpha: 0.4),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (safeIndex + 1) / stepTotal,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.orangeAction),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Reintentar',
              expanded: false,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Landing checklist item ────────────────────────────────────────────────────

class _LandingCheckItem extends StatelessWidget {
  const _LandingCheckItem({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkText,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image source bottom sheet ─────────────────────────────────────────────────

class _ImageSourceSheet<T> extends StatelessWidget {
  const _ImageSourceSheet({
    required this.title,
    required this.subtitle,
    required this.cameraLabel,
    required this.galleryLabel,
    required this.onCamera,
    required this.onGallery,
  });

  final String title;
  final String subtitle;
  final String cameraLabel;
  final String galleryLabel;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkText.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _SheetOptionTile(
                    icon: Icons.photo_camera_rounded,
                    color: AppColors.bluePrimary,
                    label: cameraLabel,
                    onTap: onCamera,
                  ),
                  const SizedBox(height: 8),
                  _SheetOptionTile(
                    icon: Icons.photo_library_rounded,
                    color: AppColors.orangeAction,
                    label: galleryLabel,
                    onTap: onGallery,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SheetOptionTile extends StatelessWidget {
  const _SheetOptionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
