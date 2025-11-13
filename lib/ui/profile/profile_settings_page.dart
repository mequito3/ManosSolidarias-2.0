import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({
    super.key,
    required this.initialProfile,
    required this.profileService,
  });

  final UserProfile initialProfile;
  final ProfileService profileService;

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _documentNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _bankHolderController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountNumberController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String? _selectedDocumentType;
  String? _selectedBank;
  String? _selectedDepartment;
  bool _useCustomBank = false;
  bool _saving = false;
  bool _showValidationErrors = false;
  bool _uploadingAvatar = false;
  bool _uploadingDonationQr = false;
  bool _requestingLocation = false;
  String? _errorMessage;
  String? _currentAvatarUrl;
  String? _currentDonationQrUrl;
  Uint8List? _avatarPreviewBytes;
  Uint8List? _donationQrPreviewBytes;

  static const List<String> _documentTypes = <String>[
    'Cédula de identidad',
  ];

  static const List<String> _boliviaBanks = <String>[
    'Banco Unión',
    'Banco Mercantil Santa Cruz',
    'Banco BISA',
    'Banco Ganadero',
    'Banco Nacional de Bolivia',
    'Banco Fortaleza',
    'Banco Económico',
    'Banco FIE',
    'Banco SOL',
    'BNB Pyme',
    'Prodem',
    'Banco Fassil',
    'Otro',
  ];

  static const List<String> _boliviaDepartments = <String>[
    'La Paz',
    'Cochabamba',
    'Santa Cruz',
    'Chuquisaca',
    'Tarija',
    'Oruro',
    'Potosí',
    'Beni',
    'Pando',
  ];

  static const String _defaultAccountType = 'No especificado';
  static const int _maxImageBytes = 3 * 1024 * 1024; // 3 MB

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _displayNameController.text = profile.displayName ?? '';
    _documentNumberController.text = profile.documentNumber ?? '';
    _phoneController.text = profile.phone ?? '';
    _addressController.text = profile.address ?? '';
    _bioController.text = profile.bio ?? '';
    _bankHolderController.text = profile.bankHolder ?? '';
    _bankNameController.clear();
    _bankAccountNumberController.text = profile.bankAccountNumber ?? '';
    _currentAvatarUrl = profile.avatarUrl;
    _currentDonationQrUrl = profile.donationQrUrl;
    _selectedDocumentType = profile.documentType?.isNotEmpty == true
        ? profile.documentType
        : _documentTypes.first;

    final rawCity = profile.city?.trim() ?? '';
    if (rawCity.contains(' - ')) {
      final parts = rawCity.split(' - ');
      final departmentCandidate = parts.first.trim();
      final matched = _matchDepartment(departmentCandidate);
      if (matched != null) {
        _selectedDepartment = matched;
      }
    } else {
      final matched = _matchDepartment(rawCity);
      if (matched != null) {
        _selectedDepartment = matched;
      }
    }

    final existingBank = profile.bankName?.trim();
    if (existingBank != null && existingBank.isNotEmpty) {
      if (_boliviaBanks.contains(existingBank)) {
        _selectedBank = existingBank;
        _useCustomBank = existingBank == 'Otro';
      } else {
        _selectedBank = 'Otro';
        _useCustomBank = true;
        _bankNameController.text = existingBank;
      }
    }

    if (!_useCustomBank && (_selectedBank == null || _selectedBank == 'Otro')) {
      _bankNameController.text = '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _documentNumberController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _bankHolderController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    super.dispose();
  }

  bool get _hasDonationQr => _currentDonationQrUrl?.trim().isNotEmpty ?? false;

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) {
      return;
    }
    await _handleImageSelection(
      file: file,
      onUploading: () => setState(() => _uploadingAvatar = true),
      onBytesReady: (data) => setState(() => _avatarPreviewBytes = data),
      upload: (bytes, contentType, ext) => widget.profileService.uploadAvatar(
        userId: widget.initialProfile.userId,
        data: bytes,
        contentType: contentType,
        fileExtension: ext,
      ),
      onSuccess: (url) {
        setState(() {
          _currentAvatarUrl = url;
          _avatarPreviewBytes = null;
        });
      },
      onComplete: () => setState(() => _uploadingAvatar = false),
    );
  }

  Future<void> _pickDonationQr() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) {
      return;
    }
    await _handleImageSelection(
      file: file,
      onUploading: () => setState(() => _uploadingDonationQr = true),
      onBytesReady: (data) => setState(() => _donationQrPreviewBytes = data),
      upload: (bytes, contentType, ext) => widget.profileService.uploadDonationQr(
        userId: widget.initialProfile.userId,
        data: bytes,
        contentType: contentType,
        fileExtension: ext,
      ),
      onSuccess: (url) {
        setState(() {
          _currentDonationQrUrl = url;
          _donationQrPreviewBytes = null;
        });
      },
      onComplete: () => setState(() => _uploadingDonationQr = false),
    );
  }

  Future<void> _handleImageSelection({
    required XFile file,
    required VoidCallback onUploading,
    required void Function(Uint8List data) onBytesReady,
    required Future<String> Function(Uint8List data, String contentType, String extension) upload,
    required void Function(String url) onSuccess,
    required VoidCallback onComplete,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      if (!_validateImageSize(bytes.length)) {
        return;
      }
      onUploading();
      onBytesReady(bytes);
      final extension = _resolveExtension(file.name);
      final contentType = _resolveContentType(extension);
      final uploadedUrl = await upload(bytes, contentType, extension);
      if (!mounted) {
        return;
      }
      onSuccess(uploadedUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen subida correctamente.')),
      );
    } on ProfileServiceException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos subir la imagen seleccionada.')),
      );
    } finally {
      if (mounted) {
        onComplete();
      }
    }
  }

  bool _validateImageSize(int length) {
    if (length <= _maxImageBytes) {
      return true;
    }
    if (!mounted) {
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona imágenes de hasta 3 MB.')),
    );
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

  void _removeAvatar() {
    setState(() {
      _currentAvatarUrl = null;
      _avatarPreviewBytes = null;
    });
  }

  void _removeDonationQr() {
    setState(() {
      _currentDonationQrUrl = null;
      _donationQrPreviewBytes = null;
    });
  }

  Future<void> _saveProfile() async {
    final formState = _formKey.currentState;
    if (formState == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _showValidationErrors = true);

    if (!formState.validate()) {
      return;
    }

    final bankHolder = _bankHolderController.text.trim();
    final manualBankName = _bankNameController.text.trim();
    final bankAccountNumber = _bankAccountNumberController.text.trim();
    final bankNameValue = _useCustomBank
        ? manualBankName
        : (_selectedBank == null || _selectedBank == 'Otro')
            ? manualBankName
            : _selectedBank ?? '';

    final hasBankInfo = bankHolder.isNotEmpty && bankNameValue.isNotEmpty && bankAccountNumber.isNotEmpty;
    final hasDonationQr = _hasDonationQr;

    if (!hasBankInfo && !hasDonationQr) {
      setState(() {
        _errorMessage = 'Incluye una cuenta bancaria de Bolivia o sube un QR de donación.';
      });
      return;
    }

    final department = _selectedDepartment;

    if (department == null || department.isEmpty) {
      setState(() {
        _errorMessage = 'Selecciona el departamento donde resides.';
      });
      return;
    }

    final cityValue = department;

    final updatedProfile = widget.initialProfile.copyWith(
      avatarUrl: _currentAvatarUrl,
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      phone: _phoneController.text.trim(),
  city: cityValue,
      address: _addressController.text.trim(),
      documentType: _selectedDocumentType,
      documentNumber: _documentNumberController.text.trim(),
      bankHolder: bankHolder.isEmpty ? null : bankHolder,
      bankName: bankNameValue.isEmpty ? null : bankNameValue,
      bankAccountType: hasBankInfo ? _defaultAccountType : widget.initialProfile.bankAccountType,
      bankAccountNumber: bankAccountNumber.isEmpty ? null : bankAccountNumber,
      donationQrUrl: _currentDonationQrUrl,
    );

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final savedProfile = await widget.profileService.upsertProfile(updatedProfile);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedProfile.meetsCompletionCriteria
                ? 'Perfil verificado. Ahora puedes enviar solicitudes de campaña.'
                : 'Perfil actualizado. Completa los datos pendientes para enviar campañas.',
          ),
        ),
      );
      Navigator.of(context).pop<UserProfile>(savedProfile);
    } on ProfileServiceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'No pudimos guardar tus datos. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _matchDepartment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final lower = value.toLowerCase();
    for (final department in _boliviaDepartments) {
      if (department.toLowerCase() == lower) {
        return department;
      }
    }
    return null;
  }

  Future<void> _fillAddressFromLocation() async {
    setState(() => _requestingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Activa el GPS para detectar tu ubicación.');
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack('Permite el acceso a la ubicación desde los ajustes del sistema.');
        await Geolocator.openAppSettings();
        return;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        _showSnack('Concede permisos de ubicación para autocompletar la dirección.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 12));

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        _showSnack('No pudimos obtener tu dirección automáticamente.');
        return;
      }

      final place = placemarks.first;
      final department = _matchDepartment(
        (place.administrativeArea?.trim().isNotEmpty ?? false)
            ? place.administrativeArea
            : place.subAdministrativeArea,
      );
      final formattedAddress = _formatPlacemark(place);

      if (kDebugMode) {
        debugPrint(
          'Ubicación detectada lat:${position.latitude}, lng:${position.longitude}, '
          'dept:${department ?? 'sin-coincidencia'}, address:$formattedAddress',
        );
      }

      setState(() {
        if (department != null) {
          _selectedDepartment = department;
        }
        if (formattedAddress.isNotEmpty) {
          _addressController.text = formattedAddress;
        } else if (_addressController.text.trim().isEmpty) {
          _addressController.text =
              'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}';
        }
      });

      _showSnack('Ubicación detectada. Revisa los datos antes de guardar.');
    } on TimeoutException {
      _showSnack('La búsqueda tardó demasiado. Revisa tu señal GPS e inténtalo de nuevo.');
    } on PermissionDefinitionsNotFoundException {
      _showSnack('No encontramos permisos de ubicación configurados. Revisa la configuración del dispositivo.');
    } on PermissionDeniedException {
      _showSnack('Necesitamos permiso de ubicación para autocompletar tus datos.');
    } on LocationServiceDisabledException {
      _showSnack('Activa el GPS para usar esta función.');
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error al obtener ubicación: $error');
        debugPrint(stackTrace.toString());
      }
      _showSnack('No pudimos obtener tu ubicación. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _requestingLocation = false);
      }
    }
  }

  String _formatPlacemark(Placemark placemark) {
    final segments = <String>[
      if (placemark.street?.trim().isNotEmpty ?? false) placemark.street!.trim(),
      if (placemark.subLocality?.trim().isNotEmpty ?? false) placemark.subLocality!.trim(),
      if (placemark.locality?.trim().isNotEmpty ?? false) placemark.locality!.trim(),
      if (placemark.administrativeArea?.trim().isNotEmpty ?? false) placemark.administrativeArea!.trim(),
    ];
    return segments.join(', ');
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration(String label, {String? hint, String? helper, int? maxLines}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      alignLabelWithHint: (maxLines ?? 1) > 1,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.grayNeutral, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.grayNeutral, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Configuración del perfil'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode:
              _showValidationErrors ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 480;
                              final iconWidget = const Icon(
                                Icons.verified_user_outlined,
                                color: AppColors.bluePrimary,
                                size: 32,
                              );
                              final content = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verifica tu identidad antes de publicar',
                                    style: (isCompact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                                      color: AppColors.darkText,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Necesitamos validar tu información de contacto y la cuenta donde se acreditarán los fondos. Esto ayuda a prevenir fraudes y nos permite aprobar solicitudes en menos tiempo.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.darkText.withValues(alpha: 0.72),
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                             
                                  const _ChecklistPoint(
                                    text: 'Verifica que tu correo y teléfono estén activos.',
                                  ),
                                  const _ChecklistPoint(
                                    text: 'Prepara un QR o una cuenta bancaria a tu nombre.',
                                  ),
                                ],
                              );

                              if (isCompact) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    iconWidget,
                                    const SizedBox(height: 12),
                                    content,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  iconWidget,
                                  const SizedBox(width: 12),
                                  Expanded(child: content),
                                ],
                              );
                            },
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: _InlineError(message: _errorMessage!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Datos personales',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Foto de perfil',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 420;
                              final avatar = Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.12),
                                    backgroundImage: _avatarPreviewBytes != null
                                        ? MemoryImage(_avatarPreviewBytes!)
                                        : _currentAvatarUrl != null
                                            ? NetworkImage(_currentAvatarUrl!)
                                            : null,
                                    child: _avatarPreviewBytes == null && _currentAvatarUrl == null
                                        ? const Icon(Icons.person_outline, color: AppColors.bluePrimary, size: 48)
                                        : null,
                                  ),
                                  if (_uploadingAvatar)
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                      ),
                                    ),
                                ],
                              );

                              final actions = Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.photo_library_outlined),
                                    label: const Text('Cambiar foto'),
                                    onPressed: _uploadingAvatar || _saving ? null : _pickAvatar,
                                  ),
                                  if (_currentAvatarUrl != null)
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Quitar'),
                                      onPressed: _uploadingAvatar || _saving ? null : _removeAvatar,
                                    ),
                                ],
                              );

                              if (isCompact) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(child: avatar),
                                    const SizedBox(height: 16),
                                    actions,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  avatar,
                                  const SizedBox(width: 20),
                                  Expanded(child: actions),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          const _InfoLine(
                            icon: Icons.photo_camera_outlined,
                            message:
                                'Selecciona una foto nítida donde se reconozca tu rostro. El archivo debe pesar menos de 3 MB.',
                          ),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _displayNameController,
                            enabled: !_saving,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration('Nombre completo'),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Ingresa tu nombre completo.';
                              }
                              if (text.length < 4) {
                                return 'El nombre debe tener al menos 4 caracteres.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            value: _selectedDocumentType,
                            isExpanded: true,
                            decoration: _inputDecoration('Tipo de documento'),
                            items: _documentTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving ? null : (value) => setState(() => _selectedDocumentType = value),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Selecciona el documento con el que te identificas.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _documentNumberController,
                            enabled: !_saving,
                            decoration: _inputDecoration('Número de documento'),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Ingresa el número del documento.';
                              }
                              if (text.length < 6) {
                                return 'Verifica que el número sea correcto.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _phoneController,
                            enabled: !_saving,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration('Teléfono de contacto', hint: '+591 700 00000'),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Necesitamos un teléfono válido para contactarte.';
                              }
                              if (text.length < 8) {
                                return 'Ingresa un teléfono de al menos 8 dígitos.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            value: _selectedDepartment,
                            isExpanded: true,
                            decoration: _inputDecoration('Departamento'),
                            items: _boliviaDepartments
                                .map(
                                  (department) => DropdownMenuItem(
                                    value: department,
                                    child: Text(department),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving ? null : (value) => setState(() => _selectedDepartment = value),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Selecciona tu departamento.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _addressController,
                            enabled: !_saving,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _inputDecoration(
                              'Dirección completa',
                              helper: 'Incluye calle, número y referencias o usa el botón de ubicación.',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Necesitamos una dirección para validar la identidad.';
                              }
                              if (text.length < 10) {
                                return 'Añade calle, número y referencias básicas.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              icon: _requestingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location_outlined),
                              label: Text(_requestingLocation ? 'Buscando ubicación…' : 'Usar mi ubicación'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.bluePrimary,
                                side: const BorderSide(color: AppColors.bluePrimary, width: 1.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _saving || _requestingLocation ? null : _fillAddressFromLocation,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _bioController,
                            enabled: !_saving,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              'Presentación (opcional)',
                              hint: 'Cuéntanos brevemente tu rol o la causa que representas.',
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Datos financieros',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _bankHolderController,
                            enabled: !_saving,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              'Titular de la cuenta',
                              helper: 'Debe coincidir con la cédula registrada en el banco.',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (_hasDonationQr) {
                                return null;
                              }
                              if (text.isEmpty) {
                                return 'Indica el nombre del titular registrado en el banco.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            value: _useCustomBank ? 'Otro' : _selectedBank,
                            isExpanded: true,
                            decoration: _inputDecoration(
                              'Banco (Bolivia)',
                              helper: 'Selecciona un banco regulado por ASFI. Si no aparece, elige "Otro".',
                            ),
                            items: _boliviaBanks
                                .map(
                                  (bank) => DropdownMenuItem(
                                    value: bank,
                                    child: Text(bank),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() {
                                      _selectedBank = value;
                                      _useCustomBank = value == 'Otro';
                                      if (!_useCustomBank) {
                                        _bankNameController.clear();
                                      }
                                    });
                                  },
                            validator: (value) {
                              if (_hasDonationQr) {
                                return null;
                              }
                              if (_useCustomBank) {
                                return null;
                              }
                              if (value == null || value.trim().isEmpty) {
                                return 'Selecciona el banco donde recibirás los fondos.';
                              }
                              return null;
                            },
                          ),
                          if (_useCustomBank) ...[
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _bankNameController,
                              enabled: !_saving,
                              decoration: _inputDecoration(
                                'Nombre del banco',
                                hint: 'Ej. Banco XYZ',
                                helper: 'Ingresa el nombre completo del banco o cooperativa.',
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (_hasDonationQr) {
                                  return null;
                                }
                                if (text.isEmpty) {
                                  return 'Escribe el nombre del banco para validar los depósitos.';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _bankAccountNumberController,
                            enabled: !_saving,
                            decoration: _inputDecoration(
                              'Número de cuenta / CCI / IBAN',
                              hint: '0001234567890',
                              helper: 'Usaremos este número para validar depósitos y auditorías.',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (_hasDonationQr) {
                                return null;
                              }
                              if (text.isEmpty) {
                                return 'Indica el número de la cuenta o código bancario.';
                              }
                              if (text.length < 6) {
                                return 'Verifica que el número de cuenta sea correcto.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'QR de donación (opcional)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AspectRatio(
                            aspectRatio: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.grayNeutral),
                                color: Colors.white,
                              ),
                              child: Stack(
                                children: [
                                  if (_donationQrPreviewBytes != null)
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.memory(
                                          _donationQrPreviewBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else if (_currentDonationQrUrl != null)
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.network(
                                          _currentDonationQrUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.qr_code_2_outlined, size: 48, color: AppColors.grayNeutral),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const Center(
                                      child: Icon(Icons.qr_code_2_outlined, size: 56, color: AppColors.grayNeutral),
                                    ),
                                  if (_uploadingDonationQr)
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.upload_file_outlined),
                                label: Text(_currentDonationQrUrl == null ? 'Subir QR' : 'Actualizar QR'),
                                onPressed: _uploadingDonationQr || _saving ? null : _pickDonationQr,
                              ),
                              if (_currentDonationQrUrl != null)
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Quitar'),
                                  onPressed: _uploadingDonationQr || _saving ? null : _removeDonationQr,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const _InfoLine(
                            icon: Icons.info_outline,
                            message:
                                'Sube el código QR que utilizas para recibir donaciones en apps bancarias o billeteras digitales. Formatos admitidos: JPG, PNG, WEBP (hasta 3 MB).',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: _saving ? 'Guardando...' : 'Guardar y continuar',
                    icon: _saving ? null : Icons.save_outlined,
                    onPressed: _saving ? null : _saveProfile,
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    label: 'Cancelar',
                    expanded: false,
                    onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orangeAction.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.orangeAction),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.orangeAction,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistPoint extends StatelessWidget {
  const _ChecklistPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.greenHope, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.75),
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.bluePrimary.withValues(alpha: 0.85), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.72),
                  height: 1.45,
                ),
          ),
        ),
      ],
    );
  }
}
