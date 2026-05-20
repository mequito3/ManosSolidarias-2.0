import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/organization_registration_controller.dart';
import '../../models/organization.dart';
import '../../models/user_profile.dart';
import '../../services/organization_service.dart';
import '../../theme/app_colors.dart';
import '../../ui/solicitudes/steps/solicitud_form_step.dart'
    show
        SolicitudFormCard,
        SolicitudFormSectionHeader,
        SolicitudInlineInfo,
        solicitudFieldDecoration;
import '../../ui/widgets/app_buttons.dart';
import '../../ui/widgets/app_network_image.dart';
import '../../ui/widgets/app_snackbar.dart';
import '../../ui/widgets/location_picker_dialog.dart';

class CreateOrganizationPage extends StatefulWidget {
  const CreateOrganizationPage({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<CreateOrganizationPage> createState() => _CreateOrganizationPageState();
}

class _CreateOrganizationPageState extends State<CreateOrganizationPage> {
  late final OrganizationRegistrationController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  Uint8List? _logoPreviewBytes;
  String? _uploadedLogoUrl;
  bool _uploadingLogo = false;
  bool _isUploadingGallery = false;
  bool _acceptsVerification = false;
  String? _selectedType;
  LatLng? _selectedLocation;

  static const int _maxLogoBytes = 2 * 1024 * 1024;
  static const int _maxGalleryBytes = 4 * 1024 * 1024;
  static const int _maxGalleryItems = 8;
  static const List<String> _typeOptions = [
    'Fundación',
    'Asociación',
    'Colectivo',
    'Cooperativa',
    'Emprendimiento social',
    'Otro',
  ];

  final List<_OrganizationGalleryItem> _galleryItems = [];
  final List<TextEditingController> _socialControllers = [];

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _controller = OrganizationRegistrationController(OrganizationService(client))
      ..addListener(_handleControllerChange)
      ..loadMyOrganizations();
    _ensureSocialField();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChange)
      ..dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    for (final ctrl in _socialControllers) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isSubmitting = _controller.isSubmitting;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar organización'),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.darkText.withValues(alpha: 0.07),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            child: AppPrimaryButton(
              label: isSubmitting ? 'Publicando…' : 'Publicar',
              icon: isSubmitting ? null : Icons.send_rounded,
              onPressed: isSubmitting ? null : _submitOrganization,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              _buildIntroCard(theme),
              const SizedBox(height: 16),
              if (_controller.loadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _InlineMessage(
                    icon: Icons.error_outline,
                    color: AppColors.orangeAction,
                    message: _controller.loadError!,
                  ),
                ),
              if (_controller.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                )),
              _buildFormFields(theme),
              const SizedBox(height: 24),
              if (_controller.submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _InlineMessage(
                    icon: Icons.info_outline,
                    color: AppColors.bluePrimary,
                    message: _controller.submitError!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.bluePrimary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REGISTRO DE ORGANIZACIÓN',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.bluePrimary,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cuéntanos sobre tu organización',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'El equipo revisará los datos antes de aprobar el perfil.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.60),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Información básica
        SolicitudFormCard(
          children: [
            const SolicitudFormSectionHeader(
              title: 'Información básica',
              subtitle: 'Datos principales de la organización',
              showDivider: false,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: solicitudFieldDecoration(
                label: 'Nombre',
                hint: 'Ej. Fundación Alas Solidarias',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Requerido';
                }
                if (value.trim().length < 4) {
                  return 'Mínimo 4 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              isExpanded: true,
              decoration: solicitudFieldDecoration(label: 'Tipo'),
              hint: Text(
                'Selecciona el tipo',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.darkText.withValues(alpha: 0.40),
                ),
              ),
              items: _typeOptions
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, style: const TextStyle(fontSize: 15)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 4,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: solicitudFieldDecoration(
                label: 'Descripción',
                hint: 'Actividades e impacto social',
                helper: 'Mínimo 40 caracteres.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Requerido';
                }
                if (value.trim().length < 40) {
                  return 'Mínimo 40 caracteres';
                }
                return null;
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Card 2: Contacto
        SolicitudFormCard(
          children: [
            const SolicitudFormSectionHeader(
              title: 'Información de contacto',
              subtitle: 'Cómo pueden ubicarte donantes y equipo',
              accent: AppColors.greenSuccess,
              showDivider: false,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: solicitudFieldDecoration(
                label: 'Teléfono',
                hint: '+591 70000000',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: solicitudFieldDecoration(
                label: 'Correo',
                hint: 'contacto@organizacion.org',
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return null;
                }
                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                if (!emailRegex.hasMatch(trimmed)) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteCtrl,
              keyboardType: TextInputType.url,
              decoration: solicitudFieldDecoration(
                label: 'Web (opcional)',
                hint: 'www.organizacion.org',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: solicitudFieldDecoration(
                label: 'Dirección',
                hint: 'Calle 15 de Abril, La Paz',
              ).copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined, size: 20),
                  onPressed: _openLocationPicker,
                  tooltip: 'Mapa',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const SolicitudInlineInfo(
              icon: Icons.info_outline_rounded,
              message: 'Añade al menos teléfono o correo.',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Card 3: Documentación (galería)
        _buildDocumentationCard(theme),

        const SizedBox(height: 16),

        // Card 4: Redes sociales
        _buildSocialMediaCard(theme),

        const SizedBox(height: 16),

        // Card 5: Logo
        _buildLogoCard(theme),

        const SizedBox(height: 16),

        // Card 6: Confirmación
        _buildConfirmationCard(theme),
      ],
    );
  }

  Widget _buildDocumentationCard(ThemeData theme) {
    return SolicitudFormCard(
      children: [
        const SolicitudFormSectionHeader(
          title: 'Documentación',
          subtitle: 'Fotos del lugar donde operan',
          accent: AppColors.orangeAction,
          showDivider: false,
        ),
        const SizedBox(height: 20),
        if (_galleryItems.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _galleryItems.length,
            itemBuilder: (context, index) {
              return _GalleryPreviewTile(
                item: _galleryItems[index],
                onRemove: () => _removeGalleryItem(index),
              );
            },
          )
        else
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dividerColor, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 30,
                  color: AppColors.darkText.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sin fotos',
                  style: TextStyle(
                    color: AppColors.darkText.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton.icon(
              onPressed: _isUploadingGallery || _galleryItems.length >= _maxGalleryItems
                  ? null
                  : _openGallerySourceSheet,
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: Text(
                _isUploadingGallery ? 'Subiendo…' : 'Agregar',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (_galleryItems.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${_galleryItems.length}/$_maxGalleryItems',
                style: TextStyle(
                  color: AppColors.darkText.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSocialMediaCard(ThemeData theme) {
    return SolicitudFormCard(
      children: [
        const SolicitudFormSectionHeader(
          title: 'Redes sociales',
          subtitle: 'Perfiles oficiales (opcional)',
          showDivider: false,
        ),
        const SizedBox(height: 20),
        for (int index = 0; index < _socialControllers.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == _socialControllers.length - 1 ? 0 : 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _socialControllers[index],
                    keyboardType: TextInputType.url,
                    decoration: solicitudFieldDecoration(
                      label: 'Red ${index + 1}',
                      hint: '@usuario o URL',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return null;
                      }
                      if (!_isValidLink(trimmed)) {
                        return 'Enlace inválido';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: _socialControllers.length > 1
                      ? () => _removeSocialLink(index)
                      : () => _socialControllers[index].clear(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addSocialLink,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar red', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoCard(ThemeData theme) {
    final hasLogo = _logoPreviewBytes != null || (_uploadedLogoUrl?.isNotEmpty ?? false);
    return SolicitudFormCard(
      children: [
        const SolicitudFormSectionHeader(
          title: 'Logo',
          subtitle: 'Imagen identificadora (opcional)',
          showDivider: false,
        ),
        const SizedBox(height: 20),
        if (hasLogo)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _logoPreviewBytes != null
                  ? Image.memory(_logoPreviewBytes!, height: 160, fit: BoxFit.cover)
                  : AppNetworkImage(url: _uploadedLogoUrl!, height: 160, fit: BoxFit.cover),
            ),
          )
        else
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dividerColor, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 30,
                  color: AppColors.darkText.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sin logo',
                  style: TextStyle(
                    color: AppColors.darkText.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton.icon(
              onPressed: _uploadingLogo ? null : _openLogoSourceSheet,
              icon: const Icon(Icons.upload, size: 18),
              label: Text(
                _uploadingLogo ? 'Subiendo…' : hasLogo ? 'Cambiar' : 'Subir',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (hasLogo) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _uploadingLogo ? null : _removeLogo,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Quitar', style: TextStyle(fontSize: 13)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmationCard(ThemeData theme) {
    return SolicitudFormCard(
      children: [
        CheckboxListTile(
          value: _acceptsVerification,
          onChanged: (value) =>
              setState(() => _acceptsVerification = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Autorizo al equipo a validar la información',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialLocation: _selectedLocation,
        initialAddress: _addressCtrl.text,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result['location'] as LatLng?;
        _addressCtrl.text = result['address'] as String? ?? '';
      });
    }
  }

  Future<void> _openLogoSourceSheet() async {
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
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source == null) {
      return;
    }
    await _pickLogoImage(source);
  }

  Future<void> _pickLogoImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 90);
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.lengthInBytes > _maxLogoBytes) {
        AppSnackBar.showWarning(context, 'El logo supera los 2 MB permitidos. Usa una imagen más liviana.');
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() => _uploadingLogo = true);

      final extension = _resolveExtension(file.name);
      final contentType = _resolveContentType(extension);
      final uploadedUrl = await _controller.uploadLogoImage(
        data: bytes,
        contentType: contentType,
        fileExtension: extension,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _logoPreviewBytes = bytes;
        _uploadedLogoUrl = uploadedUrl;
      });
      AppSnackBar.showSuccess(context, 'Logo actualizado correctamente.');
    } on OrganizationServiceException catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'No pudimos subir el logo seleccionado.');
    } finally {
      if (mounted) {
        setState(() => _uploadingLogo = false);
      }
    }
  }

  void _removeLogo() {
    setState(() {
      _logoPreviewBytes = null;
      _uploadedLogoUrl = null;
    });
  }

  Future<void> _openGallerySourceSheet() async {
    final source = await showModalBottomSheet<_GallerySourceChoice>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.of(context).pop(_GallerySourceChoice.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.of(context).pop(_GallerySourceChoice.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    await _pickGalleryImages(source);
  }

  Future<void> _pickGalleryImages(_GallerySourceChoice choice) async {
    if (_galleryItems.length >= _maxGalleryItems) {
      return;
    }

    setState(() => _isUploadingGallery = true);

    try {
      if (choice == _GallerySourceChoice.gallery) {
        final remainingSlots = _maxGalleryItems - _galleryItems.length;
        final files = await _picker.pickMultiImage(imageQuality: 90);
        if (files.isEmpty) {
          return;
        }
        for (final file in files.take(remainingSlots)) {
          await _handleGalleryFile(file);
        }
      } else {
        final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
        if (file != null) {
          await _handleGalleryFile(file);
        }
      }
    } on OrganizationServiceException catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'No pudimos subir la imagen del espacio. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _isUploadingGallery = false);
      }
    }
  }

  Future<void> _handleGalleryFile(XFile file) async {
    if (_galleryItems.length >= _maxGalleryItems) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > _maxGalleryBytes) {
      AppSnackBar.showWarning(context, 'Una de las imágenes supera los 4 MB permitidos. Ajusta su tamaño.');
      return;
    }

    final extension = _resolveExtension(file.name);
    final contentType = _resolveContentType(extension);
    final uploadedUrl = await _controller.uploadGalleryImage(
      data: bytes,
      contentType: contentType,
      fileExtension: extension,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _galleryItems.add(
        _OrganizationGalleryItem(bytes: bytes, remoteUrl: uploadedUrl),
      );
    });

    AppSnackBar.showSuccess(context, 'Imagen añadida correctamente.');
  }

  void _removeGalleryItem(int index) {
    if (index < 0 || index >= _galleryItems.length) {
      return;
    }
    setState(() {
      _galleryItems.removeAt(index);
    });
  }

  Future<void> _submitOrganization() async {
    final form = _formKey.currentState;
    if (form == null) {
      return;
    }
    FocusScope.of(context).unfocus();

    if (!form.validate()) {
      return;
    }

    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (phone.isEmpty && email.isEmpty) {
      AppSnackBar.showWarning(context, 'Añade al menos un medio de contacto (teléfono o correo).');
      return;
    }

    if (_galleryItems.isEmpty) {
      AppSnackBar.showWarning(context, 'Sube al menos una foto del espacio para completar la solicitud.');
      return;
    }

    if (!_acceptsVerification) {
      AppSnackBar.showWarning(context, 'Debes confirmar la veracidad de la información para enviar la solicitud.');
      return;
    }

    final socialLinks = _socialControllers
        .map((ctrl) => ctrl.text.trim())
        .where((link) => link.isNotEmpty)
        .toList();

    final draft = OrganizationDraft(
      name: _nameCtrl.text.trim(),
      type: _selectedType,
      description: _descriptionCtrl.text.trim(),
      phone: phone,
      email: email,
      website: _websiteCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      logoUrl: _uploadedLogoUrl,
      galleryImageUrls: _galleryItems.map((item) => item.remoteUrl).toList(),
      socialLinks: socialLinks,
    );

    final result = await _controller.submitOrganization(draft);
    if (!mounted) {
      return;
    }

    if (result != null) {
      // El home muestra el snackbar de éxito al recibir pop(true).
      Navigator.of(context).pop<bool>(true);
    }
  }

  String _resolveExtension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index == -1 || index == fileName.length - 1) {
      return 'jpg';
    }
    return fileName.substring(index + 1).toLowerCase();
  }

  String _resolveContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  bool _isValidLink(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    final pattern = RegExp(r'^(https?://)?[\w.-]+(\.[\w.-]+)+[/\w@&%?=.-]*$');
    return pattern.hasMatch(trimmed);
  }

  void _ensureSocialField() {
    if (_socialControllers.isEmpty) {
      _socialControllers.add(TextEditingController());
    }
  }

  void _addSocialLink() {
    setState(() {
      _socialControllers.add(TextEditingController());
    });
  }

  void _removeSocialLink(int index) {
    if (index < 0 || index >= _socialControllers.length) {
      return;
    }
    setState(() {
      final controller = _socialControllers.removeAt(index);
      controller.dispose();
      _ensureSocialField();
    });
  }
}

class _OrganizationGalleryItem {
  _OrganizationGalleryItem({required this.bytes, required this.remoteUrl});

  final Uint8List bytes;
  final String remoteUrl;
}

class _GalleryPreviewTile extends StatelessWidget {
  const _GalleryPreviewTile({required this.item, required this.onRemove});

  final _OrganizationGalleryItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            item.bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _GallerySourceChoice { camera, gallery }

class _OrganizationStatusTile extends StatelessWidget {
  const _OrganizationStatusTile({required this.organization});

  final OrganizationSummary organization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = _statusLabel(organization.status);
    final statusColor = _statusColor(organization.status);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: statusColor.withValues(alpha: 0.12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  organization.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              Chip(
                label: Text(statusLabel),
                backgroundColor: statusColor,
                labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (organization.description != null && organization.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              organization.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.darkText.withValues(alpha: 0.7),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'aprobada':
        return 'Aprobada';
      case 'rechazada':
        return 'Rechazada';
      case 'pendiente':
      default:
        return 'Pendiente';
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'aprobada':
        return AppColors.greenHope;
      case 'rechazada':
        return AppColors.orangeAction;
      case 'pendiente':
      default:
        return AppColors.bluePrimary;
    }
  }
}

class _GuidelineChip extends StatelessWidget {
  const _GuidelineChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bluePrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.bluePrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.bluePrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
