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
import '../widgets/app_network_image.dart';
import '../widgets/premium_app_bar.dart';

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
  static const int _maxImageBytes = 3 * 1024 * 1024;

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
    if (file == null) return;
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
    if (file == null) return;
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
      if (!mounted) return;
      onSuccess(uploadedUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen subida correctamente.')),
      );
    } on ProfileServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
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
    if (length <= _maxImageBytes) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona imágenes de hasta 3 MB.')),
    );
    return false;
  }

  String _resolveExtension(String filename) {
    final index = filename.lastIndexOf('.');
    if (index == -1) return 'jpg';
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
    if (formState == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _showValidationErrors = true);

    if (!formState.validate()) return;

    final bankHolder = _bankHolderController.text.trim();
    final manualBankName = _bankNameController.text.trim();
    final bankAccountNumber = _bankAccountNumberController.text.trim();
    final bankNameValue = _useCustomBank
        ? manualBankName
        : (_selectedBank == null || _selectedBank == 'Otro')
            ? manualBankName
            : _selectedBank ?? '';

    final hasBankInfo =
        bankHolder.isNotEmpty && bankNameValue.isNotEmpty && bankAccountNumber.isNotEmpty;
    final hasDonationQr = _hasDonationQr;

    if (!hasBankInfo && !hasDonationQr) {
      setState(() {
        _errorMessage =
            'Incluye una cuenta bancaria de Bolivia o sube un QR de donación.';
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
      bankAccountType: hasBankInfo
          ? _defaultAccountType
          : widget.initialProfile.bankAccountType,
      bankAccountNumber: bankAccountNumber.isEmpty ? null : bankAccountNumber,
      donationQrUrl: _currentDonationQrUrl,
    );

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final savedProfile =
          await widget.profileService.upsertProfile(updatedProfile);
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _errorMessage = 'No pudimos guardar tus datos. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _matchDepartment(String? value) {
    if (value == null || value.trim().isEmpty) return null;
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
        _showSnack(
            'Permite el acceso a la ubicación desde los ajustes del sistema.');
        await Geolocator.openAppSettings();
        return;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        _showSnack(
            'Concede permisos de ubicación para autocompletar la dirección.');
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
      _showSnack(
          'La búsqueda tardó demasiado. Revisa tu señal GPS e inténtalo de nuevo.');
    } on PermissionDefinitionsNotFoundException {
      _showSnack(
          'No encontramos permisos de ubicación configurados. Revisa la configuración del dispositivo.');
    } on PermissionDeniedException {
      _showSnack(
          'Necesitamos permiso de ubicación para autocompletar tus datos.');
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
      if (placemark.subLocality?.trim().isNotEmpty ?? false)
        placemark.subLocality!.trim(),
      if (placemark.locality?.trim().isNotEmpty ?? false)
        placemark.locality!.trim(),
      if (placemark.administrativeArea?.trim().isNotEmpty ?? false)
        placemark.administrativeArea!.trim(),
    ];
    return segments.join(', ');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    String? helper,
    IconData? prefixIcon,
    int? maxLines,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 3,
      alignLabelWithHint: (maxLines ?? 1) > 1,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(
                  left: AppColors.space16, right: AppColors.space12),
              child: Icon(prefixIcon,
                  color: AppColors.bluePrimary, size: 20),
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      labelStyle: const TextStyle(
        color: AppColors.mediumText,
        fontWeight: AppColors.fontWeightMedium,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.bluePrimary,
        fontWeight: AppColors.fontWeightSemiBold,
      ),
      helperStyle: const TextStyle(
        color: AppColors.lightText,
        fontSize: AppColors.fontSizeSm,
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppColors.space20, vertical: AppColors.space16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        borderSide:
            const BorderSide(color: AppColors.dividerColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        borderSide:
            const BorderSide(color: AppColors.dividerColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        borderSide:
            const BorderSide(color: AppColors.bluePrimary, width: 2.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 2.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: PremiumAppBar(
        title: 'Editar perfil',
        onBack: _saving ? () {} : () => Navigator.of(context).maybePop(),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _showValidationErrors
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(
            AppColors.space20,
            AppColors.space12,
            AppColors.space20,
            AppColors.space32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsHero(
                    avatarBytes: _avatarPreviewBytes,
                    avatarUrl: _currentAvatarUrl,
                    uploading: _uploadingAvatar,
                    onPick: _uploadingAvatar || _saving ? null : _pickAvatar,
                    onRemove:
                        _uploadingAvatar || _saving || _currentAvatarUrl == null
                            ? null
                            : _removeAvatar,
                  ),
                  const SizedBox(height: AppColors.space16),
                  _InfoCard(
                            icon: Icons.verified_user_rounded,
                            iconColor: AppColors.bluePrimary,
                            title: 'Verifica tu identidad',
                            body:
                                'Validamos tu información para prevenir fraudes y aprobar tus solicitudes más rápido.',
                            checklist: const [
                              'Mantén tu correo y teléfono activos.',
                              'Adjunta QR o cuenta bancaria a tu nombre.',
                            ],
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: AppColors.space12),
                            _InlineError(message: _errorMessage!),
                          ],
                          const SizedBox(height: AppColors.space16),
                          _FormSection(
                            icon: Icons.person_rounded,
                            iconColor: AppColors.bluePrimary,
                            title: 'Datos personales',
                            children: [
                              TextFormField(
                                controller: _displayNameController,
                                enabled: !_saving,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDecoration(
                                  'Nombre completo',
                                  prefixIcon: Icons.badge_rounded,
                                ),
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
                              const SizedBox(height: AppColors.space16),
                              DropdownButtonFormField<String>(
                                value: _selectedDocumentType,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  'Tipo de documento',
                                  prefixIcon: Icons.contact_page_rounded,
                                ),
                                items: _documentTypes
                                    .map((t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        ))
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (v) =>
                                        setState(() => _selectedDocumentType = v),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Selecciona el documento con el que te identificas.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppColors.space16),
                              TextFormField(
                                controller: _documentNumberController,
                                enabled: !_saving,
                                decoration: _inputDecoration(
                                  'Número de documento',
                                  prefixIcon: Icons.numbers_rounded,
                                ),
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
                              const SizedBox(height: AppColors.space16),
                              TextFormField(
                                controller: _phoneController,
                                enabled: !_saving,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                  'Teléfono de contacto',
                                  hint: '+591 700 00000',
                                  prefixIcon: Icons.phone_iphone_rounded,
                                ),
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
                              const SizedBox(height: AppColors.space16),
                              DropdownButtonFormField<String>(
                                value: _selectedDepartment,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  'Departamento',
                                  prefixIcon: Icons.map_rounded,
                                ),
                                items: _boliviaDepartments
                                    .map((d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d),
                                        ))
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (v) =>
                                        setState(() => _selectedDepartment = v),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Selecciona tu departamento.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppColors.space16),
                              TextFormField(
                                controller: _addressController,
                                enabled: !_saving,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: _inputDecoration(
                                  'Dirección completa',
                                  prefixIcon: Icons.home_rounded,
                                  helper:
                                      'Incluye calle, número y referencias o usa el botón de ubicación.',
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
                              const SizedBox(height: AppColors.space12),
                              _LocationButton(
                                loading: _requestingLocation,
                                onPressed: _saving || _requestingLocation
                                    ? null
                                    : _fillAddressFromLocation,
                              ),
                              const SizedBox(height: AppColors.space16),
                              TextFormField(
                                controller: _bioController,
                                enabled: !_saving,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  'Presentación (opcional)',
                                  hint:
                                      'Cuéntanos brevemente tu rol o la causa que representas.',
                                  maxLines: 3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppColors.space16),
                          _FormSection(
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: AppColors.orangeAction,
                            title: 'Datos financieros',
                            subtitle:
                                'Necesitamos al menos una cuenta bancaria o un QR de donación.',
                            children: [
                              TextFormField(
                                controller: _bankHolderController,
                                enabled: !_saving,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDecoration(
                                  'Titular de la cuenta',
                                  prefixIcon: Icons.person_outline_rounded,
                                  helper:
                                      'Debe coincidir con la cédula registrada en el banco.',
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (_hasDonationQr) return null;
                                  if (text.isEmpty) {
                                    return 'Indica el nombre del titular registrado en el banco.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppColors.space16),
                              DropdownButtonFormField<String>(
                                value: _useCustomBank ? 'Otro' : _selectedBank,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  'Banco (Bolivia)',
                                  prefixIcon: Icons.account_balance_rounded,
                                  helper:
                                      'Selecciona un banco regulado por ASFI. Si no aparece, elige "Otro".',
                                ),
                                items: _boliviaBanks
                                    .map((b) => DropdownMenuItem(
                                          value: b,
                                          child: Text(b),
                                        ))
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _selectedBank = value;
                                          _useCustomBank = value == 'Otro';
                                          if (!_useCustomBank) {
                                            _bankNameController.clear();
                                          }
                                        });
                                      },
                                validator: (value) {
                                  if (_hasDonationQr) return null;
                                  if (_useCustomBank) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Selecciona el banco donde recibirás los fondos.';
                                  }
                                  return null;
                                },
                              ),
                              if (_useCustomBank) ...[
                                const SizedBox(height: AppColors.space16),
                                TextFormField(
                                  controller: _bankNameController,
                                  enabled: !_saving,
                                  decoration: _inputDecoration(
                                    'Nombre del banco',
                                    prefixIcon: Icons.edit_note_rounded,
                                    hint: 'Ej. Banco XYZ',
                                    helper:
                                        'Ingresa el nombre completo del banco o cooperativa.',
                                  ),
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (_hasDonationQr) return null;
                                    if (text.isEmpty) {
                                      return 'Escribe el nombre del banco para validar los depósitos.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: AppColors.space16),
                              TextFormField(
                                controller: _bankAccountNumberController,
                                enabled: !_saving,
                                decoration: _inputDecoration(
                                  'Número de cuenta',
                                  prefixIcon: Icons.tag_rounded,
                                  hint: '0001234567890',
                                  helper:
                                      'Usaremos este número para validar depósitos y auditorías.',
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (_hasDonationQr) return null;
                                  if (text.isEmpty) {
                                    return 'Indica el número de la cuenta o código bancario.';
                                  }
                                  if (text.length < 6) {
                                    return 'Verifica que el número de cuenta sea correcto.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppColors.space24),
                              _QrUploader(
                                bytes: _donationQrPreviewBytes,
                                url: _currentDonationQrUrl,
                                uploading: _uploadingDonationQr,
                                onPick: _uploadingDonationQr || _saving
                                    ? null
                                    : _pickDonationQr,
                                onRemove: _uploadingDonationQr ||
                                        _saving ||
                                        _currentDonationQrUrl == null
                                    ? null
                                    : _removeDonationQr,
                              ),
                            ],
                          ),
                  const SizedBox(height: AppColors.space24),
                  AppPrimaryButton(
                    label: _saving ? 'Guardando...' : 'Guardar cambios',
                    icon: _saving ? null : Icons.save_rounded,
                    onPressed: _saving ? null : _saveProfile,
                  ),
                  const SizedBox(height: AppColors.space12),
                  AppSecondaryButton(
                    label: 'Cancelar',
                    onPressed:
                        _saving ? null : () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Compact avatar uploader card (soft, white, no blue dominante) ──────────

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.avatarBytes,
    required this.avatarUrl,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? avatarBytes;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.bluePrimary.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grayLight,
                  ),
                  child: ClipOval(child: _buildAvatarImage()),
                ),
              ),
              if (uploading)
                Container(
                  width: 78,
                  height: 78,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: AppColors.orangeAction,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onPick,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.photo_camera_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppColors.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Foto de perfil',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeMd,
                    fontWeight: AppColors.fontWeightExtraBold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Imagen nítida, máx. 3 MB.',
                  style: TextStyle(
                    color: AppColors.mediumText,
                    fontSize: AppColors.fontSizeSm,
                  ),
                ),
                const SizedBox(height: AppColors.space12),
                Wrap(
                  spacing: AppColors.space8,
                  runSpacing: AppColors.space8,
                  children: [
                    _SoftPillButton(
                      icon: Icons.photo_library_rounded,
                      label: avatarUrl == null ? 'Subir' : 'Cambiar',
                      onPressed: onPick,
                      color: AppColors.bluePrimary,
                    ),
                    if (avatarUrl != null)
                      _SoftPillButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Quitar',
                        onPressed: onRemove,
                        color: AppColors.error,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (avatarBytes != null) {
      return Image.memory(avatarBytes!, fit: BoxFit.cover);
    }
    if (avatarUrl != null) {
      return AppNetworkImage(
        url: avatarUrl!,
        fit: BoxFit.cover,
        errorWidget: const _AvatarPlaceholder(),
      );
    }
    return const _AvatarPlaceholder();
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bluePrimary.withValues(alpha: 0.10),
      child: const Center(
        child: Icon(Icons.person_rounded,
            color: AppColors.bluePrimary, size: 36),
      ),
    );
  }
}

class _SoftPillButton extends StatelessWidget {
  const _SoftPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: color.withValues(alpha: disabled ? 0.05 : 0.10),
      borderRadius: BorderRadius.circular(AppColors.radiusRound),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppColors.space12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: color.withValues(alpha: disabled ? 0.5 : 1.0),
                  size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: disabled ? 0.5 : 1.0),
                  fontSize: AppColors.fontSizeSm,
                  fontWeight: AppColors.fontWeightBold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Info card (top tip) ─────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.checklist,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<String> checklist;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppColors.space12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeLg,
                    fontWeight: AppColors.fontWeightExtraBold,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space12),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.mediumText,
              fontSize: AppColors.fontSizeBase,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppColors.space12),
          for (final item in checklist)
            Padding(
              padding: const EdgeInsets.only(top: AppColors.space8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.greenHope, size: 18),
                  const SizedBox(width: AppColors.space8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: AppColors.fontSizeBase,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Form section ────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppColors.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: AppColors.fontSizeLg,
                        fontWeight: AppColors.fontWeightBold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.mediumText,
                            fontSize: AppColors.fontSizeSm,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space16),
          const Divider(height: 1, color: AppColors.grayLight),
          const SizedBox(height: AppColors.space20),
          ...children,
        ],
      ),
    );
  }
}

// ─── QR uploader inside finance section ──────────────────────────────────────

class _QrUploader extends StatelessWidget {
  const _QrUploader({
    required this.bytes,
    required this.url,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final String? url;
  final bool uploading;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border:
            Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded,
                  color: AppColors.bluePrimary, size: 22),
              const SizedBox(width: AppColors.space8),
              const Expanded(
                child: Text(
                  'QR de donación (opcional)',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeMd,
                    fontWeight: AppColors.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space8),
          const Text(
            'Sube el QR que recibes en apps bancarias o billeteras digitales. Formatos JPG, PNG o WEBP (máx. 3 MB).',
            style: TextStyle(
              color: AppColors.mediumText,
              fontSize: AppColors.fontSizeSm,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppColors.space16),
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                color: Colors.white,
                border: Border.all(
                  color: AppColors.bluePrimary.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  if (bytes != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusMd),
                        child: Image.memory(bytes!, fit: BoxFit.cover),
                      ),
                    )
                  else if (url != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusMd),
                        child: AppNetworkImage(
                          url: url!,
                          fit: BoxFit.cover,
                          errorWidget: const Center(
                            child: Icon(Icons.qr_code_2_rounded,
                                size: 56, color: AppColors.grayNeutral),
                          ),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2_rounded,
                              size: 56, color: AppColors.grayNeutral),
                          SizedBox(height: AppColors.space4),
                          Text(
                            'Sin QR cargado',
                            style: TextStyle(
                              color: AppColors.lightText,
                              fontWeight: AppColors.fontWeightSemiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (uploading)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusMd),
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
          const SizedBox(height: AppColors.space12),
          Wrap(
            spacing: AppColors.space12,
            runSpacing: AppColors.space8,
            children: [
              FilledButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_rounded, size: 20),
                label: Text(url == null ? 'Subir QR' : 'Actualizar QR'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppColors.space20,
                      vertical: AppColors.space12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: AppColors.fontWeightSemiBold,
                    fontSize: AppColors.fontSizeBase,
                  ),
                ),
              ),
              if (url != null)
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Quitar QR'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.space16,
                        vertical: AppColors.space12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location_rounded, size: 20),
        label: Text(loading ? 'Buscando ubicación…' : 'Usar mi ubicación'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.bluePrimary,
          side: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(
              horizontal: AppColors.space16, vertical: AppColors.space12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: AppColors.fontWeightSemiBold,
            fontSize: AppColors.fontSizeBase,
          ),
        ),
      ),
    );
  }
}

// ─── Inline error ────────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.space12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: AppColors.fontSizeBase,
                fontWeight: AppColors.fontWeightSemiBold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
