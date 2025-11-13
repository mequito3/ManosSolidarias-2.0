import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/solicitud_controller.dart';
import '../../models/solicitud.dart';
import '../../models/user_profile.dart';
import '../../services/solicitud_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
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
  });

  final UserProfile profile;
  final bool startAtTypeSelection;

  @override
  State<CreateSolicitudPage> createState() => _CreateSolicitudPageState();
}

class _CreateSolicitudPageState extends State<CreateSolicitudPage> {
  late final SolicitudService _service;
  late final SolicitudController _controller;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _goalCtrl = TextEditingController();
  final TextEditingController _beneficiaryNameCtrl = TextEditingController();
  final Map<String, TextEditingController> _extraControllers = {};

  final ImagePicker _picker = ImagePicker();
  Uint8List? _coverPreviewBytes;
  String? _uploadedCoverUrl;
  bool _uploadingCover = false;
  static const int _maxCoverBytes = 3 * 1024 * 1024;
  static const int _maxEvidenceItems = 12;

  late _SolicitudFlowStep _currentStep;
  SolicitudTipo _selectedTipo = SolicitudTipo.campania;
  bool _acceptsGuidelines = false;
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
    _beneficiaryRelationship = _relationshipOptions.first;
    _currentStep = widget.startAtTypeSelection
        ? _SolicitudFlowStep.typeSelection
        : _SolicitudFlowStep.landing;
    _controller.addListener(_handleControllerChange);
    _controller.loadInitialData();
  }

  Widget _buildLandingStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antes de empezar',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reúne la información clave de tu iniciativa solidaria y prepara evidencias para que el equipo pueda validarla.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                const SolicitudInlineInfo(
                  icon: Icons.info_outline,
                  message:
                      'Necesitarás una portada en formato horizontal, meta económica en bolivianos y el detalle completo de cómo utilizarás lo recaudado.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Cuando estés listo, toca el botón flotante “Crear solicitud” para avanzar.',
          textAlign: TextAlign.right,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTypeSelectionStep() {
    return SolicitudTypeStep(
      configs: [
        solicitudTypeConfigs[SolicitudTipo.campania]!,
        solicitudTypeConfigs[SolicitudTipo.kermesse]!,
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
      onBack: () => _goToStep(_SolicitudFlowStep.typeSelection),
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
      onPickCover: _openCoverSourceSheet,
      onRemoveCover: _removeCoverImage,
      coverPreviewBytes: _coverPreviewBytes,
      uploadedCoverUrl: _uploadedCoverUrl,
      uploadingCover: _uploadingCover,
      acceptsGuidelines: _acceptsGuidelines,
      onAcceptGuidelinesChanged: (value) =>
          setState(() => _acceptsGuidelines = value ?? false),
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
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _goalCtrl.dispose();
    _beneficiaryNameCtrl.dispose();
    for (final ctrl in _extraControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
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
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 4),
            ],
          ),
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
      final bytes = await file.readAsBytes();
      if (!_validateImageSize(bytes.length)) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() => _uploadingCover = true);

      final extension = _resolveExtension(file.name);
      final contentType = _resolveContentType(extension);
      final uploadedUrl = await _controller.uploadCoverImage(
        data: bytes,
        contentType: contentType,
        fileExtension: extension,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _coverPreviewBytes = bytes;
        _uploadedCoverUrl = uploadedUrl;
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
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.of(context).pop(_EvidencePickerChoice.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir varias de la galería'),
                onTap: () => Navigator.of(context).pop(_EvidencePickerChoice.gallery),
              ),
              const SizedBox(height: 4),
            ],
          ),
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
    final bytes = await file.readAsBytes();
    if (!_validateImageSize(bytes.length)) {
      return;
    }
    if (!mounted) {
      return;
    }

    final extension = _resolveExtension(file.name);
    final contentType = _resolveContentType(extension);
    final uploadedUrl = await _controller.uploadEvidenceImage(
      data: bytes,
      contentType: contentType,
      fileExtension: extension,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _evidenceUploads.add(SolicitudEvidenceUpload(bytes: bytes, url: uploadedUrl));
    });
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

    if (filledExtras.isEmpty && evidenceUrls.isEmpty) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar solicitud solidaria')),
      backgroundColor: AppColors.lightBackground,
      floatingActionButton: _currentStep == _SolicitudFlowStep.landing
          ? FloatingActionButton.extended(
              onPressed: () => _goToStep(_SolicitudFlowStep.typeSelection),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Crear solicitud'),
              backgroundColor: AppColors.orangeAction,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading && !_controller.hasLoaded) {
              return const Center(child: CircularProgressIndicator());
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

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: stepContent,
                ),
              ),
            );
          },
        ),
      ),
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
