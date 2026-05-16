import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/solicitud.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import 'solicitud_type_step.dart';

const int solicitudTitleMinWords = 2;
const int solicitudTitleMaxWords = 4;
const int solicitudTitleMaxCharacters = 48;
const int solicitudDescriptionMinLength = 80;
const int solicitudDescriptionMaxLength = 300;

class SolicitudFormStep extends StatelessWidget {
  const SolicitudFormStep({
    super.key,
    required this.formKey,
    required this.autovalidate,
    required this.isSubmitting,
    required this.config,
    required this.tipo,
    required this.titleCtrl,
    required this.descriptionCtrl,
    required this.goalCtrl,
    required this.beneficiaryNameCtrl,
    required this.extraControllers,
    required this.evidenceUploads,
    required this.isUploadingEvidence,
    required this.maxEvidenceItems,
    required this.onAddEvidence,
    required this.onRemoveEvidence,
    required this.acceptsGuidelines,
    required this.onAcceptGuidelinesChanged,
    required this.esAnonimo,
    required this.onEsAnonimoChanged,
    required this.onBack,
    required this.onSubmit,
    required this.onCancel,
    required this.relationshipOptions,
    required this.beneficiaryRelationship,
    required this.onRelationshipChanged,
    required this.submitError,
    required this.onPickKermesseDate,
    required this.kermesseLocation,
    required this.onPickKermesseLocation,
    required this.onClearKermesseLocation,
  required this.useManualKermesseCoords,
  required this.onManualKermesseCoordsChanged,
    required this.menuItems,
    required this.onAddMenuItem,
    required this.onEditMenuItem,
    required this.onRemoveMenuItem,
    required this.activityItems,
    required this.onAddActivity,
    required this.onEditActivity,
    required this.onRemoveActivity,
    required this.onPickCover,
    required this.onRemoveCover,
    required this.coverPreviewBytes,
    required this.uploadingCover,
  });

  final GlobalKey<FormState> formKey;
  final bool autovalidate;
  final bool isSubmitting;
  final SolicitudTypeConfig config;
  final SolicitudTipo tipo;
  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController goalCtrl;
  final TextEditingController beneficiaryNameCtrl;
  final Map<String, TextEditingController> extraControllers;
  final List<SolicitudEvidenceUpload> evidenceUploads;
  final bool isUploadingEvidence;
  final int maxEvidenceItems;
  final VoidCallback onAddEvidence;
  final void Function(int index) onRemoveEvidence;
  final bool acceptsGuidelines;
  final ValueChanged<bool?> onAcceptGuidelinesChanged;
  final bool esAnonimo;
  final ValueChanged<bool> onEsAnonimoChanged;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final List<String> relationshipOptions;
  final String? beneficiaryRelationship;
  final ValueChanged<String?> onRelationshipChanged;
  final String? submitError;
  final VoidCallback onPickKermesseDate;
  final SolicitudKermesseLocation? kermesseLocation;
  final VoidCallback onPickKermesseLocation;
  final VoidCallback onClearKermesseLocation;
  final bool useManualKermesseCoords;
  final ValueChanged<bool> onManualKermesseCoordsChanged;
  final List<SolicitudKermesseMenuItem> menuItems;
  final VoidCallback onAddMenuItem;
  final void Function(int index) onEditMenuItem;
  final void Function(int index) onRemoveMenuItem;
  final List<SolicitudKermesseActivity> activityItems;
  final VoidCallback onAddActivity;
  final void Function(int index) onEditActivity;
  final void Function(int index) onRemoveActivity;
  final VoidCallback onPickCover;
  final VoidCallback onRemoveCover;
  final Uint8List? coverPreviewBytes;
  final bool uploadingCover;

  bool get _isCampania => tipo == SolicitudTipo.campania;
  bool get _isKermesse => tipo == SolicitudTipo.kermesse;

  TextEditingController _extraController(String id) {
    final controller = extraControllers[id];
    if (controller == null) {
      throw ArgumentError('Missing controller for extra field "$id"');
    }
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
    autovalidateMode: autovalidate ? AutovalidateMode.always : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SolicitudIntroCard(config: config, submitError: submitError),
          const SizedBox(height: 16),
          SolicitudFormCard(
            children: [
              _FormSectionHeader(
                icon: Icons.edit_note_rounded,
                title: config.sectionTitle,
                subtitle: config.chipTitle,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleCtrl,
                enabled: !isSubmitting,
                maxLength: solicitudTitleMaxCharacters,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textCapitalization: TextCapitalization.words,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                decoration: solicitudFieldDecoration(
                  label: config.titleLabel,
                  hint: config.titleHint,
                  helper: 'Ej.: "Cirugía para Mateo" o "Medicinas para Sofía".',
                  helperMaxLines: 2,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Indica un título breve para tu solicitud.';
                  }
                  final words = text
                      .split(RegExp(r'\s+'))
                      .where((word) => word.isNotEmpty)
                      .toList();
                  if (words.length < solicitudTitleMinWords) {
                    return 'Añade una palabra más para que el título tenga sentido completo.';
                  }
                  if (words.length > solicitudTitleMaxWords) {
                    return 'El título debe tener máximo $solicitudTitleMaxWords palabras.';
                  }
                  return null;
                },
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: titleCtrl,
                builder: (context, value, _) {
                  final wordCount = value.text
                      .trim()
                      .split(RegExp(r'\s+'))
                      .where((word) => word.isNotEmpty)
                      .length;
                  final isOverLimit = wordCount > solicitudTitleMaxWords;
                  final isOk = wordCount >= solicitudTitleMinWords && !isOverLimit;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOverLimit
                                ? AppColors.error.withValues(alpha: 0.10)
                                : isOk
                                    ? AppColors.greenSuccess.withValues(alpha: 0.10)
                                    : AppColors.bluePrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOverLimit
                                    ? Icons.warning_amber_rounded
                                    : isOk
                                        ? Icons.check_circle_rounded
                                        : Icons.short_text_rounded,
                                size: 13,
                                color: isOverLimit
                                    ? AppColors.error
                                    : isOk
                                        ? AppColors.greenSuccess
                                        : AppColors.bluePrimary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Palabras: $wordCount / $solicitudTitleMaxWords',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isOverLimit
                                      ? AppColors.error
                                      : isOk
                                          ? AppColors.greenSuccess
                                          : AppColors.bluePrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionCtrl,
                enabled: !isSubmitting,
                maxLines: 6,
                maxLength: solicitudDescriptionMaxLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textCapitalization: TextCapitalization.sentences,
                decoration: solicitudFieldDecoration(
                  label: config.descriptionLabel,
                  hint: config.descriptionHint,
                  helper: config.descriptionHelper ?? 'Resume la necesidad esencial en un máximo de $solicitudDescriptionMaxLength caracteres.',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Describe la situación para que podamos evaluarla.';
                  }
                  if (text.length < solicitudDescriptionMinLength) {
                    return 'Amplía un poco más la historia (mínimo $solicitudDescriptionMinLength caracteres).';
                  }
                  if (text.length > solicitudDescriptionMaxLength) {
                    return 'Máximo $solicitudDescriptionMaxLength caracteres para la descripción.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const SolicitudInlineInfo(
                icon: Icons.auto_awesome_rounded,
                message: 'El equipo asignará la categoría solidaria al revisar tu solicitud.',
              ),
              if (!_isKermesse) ...[
                const SizedBox(height: 20),
                const _FormSectionHeader(
                  icon: Icons.payments_rounded,
                  title: 'Meta económica',
                  subtitle: 'Monto en bolivianos',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: goalCtrl,
                  enabled: !isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                  ],
                  decoration: solicitudFieldDecoration(
                    label: config.goalLabel,
                    hint: config.goalHint,
                    helper: 'Ingresa el monto en bolivianos. Deja vacío si no aplica.',
                  ).copyWith(
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bs',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.bluePrimary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    suffixIcon: const Icon(Icons.monetization_on_rounded, color: AppColors.bluePrimary, size: 20),
                  ),
                ),
              ],
              if (_isCampania) ...[
                const SizedBox(height: 24),
                const _FormSectionHeader(
                  icon: Icons.person_rounded,
                  title: 'Datos del beneficiario',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: beneficiaryNameCtrl,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  decoration: solicitudFieldDecoration(
                    label: 'Nombre completo del beneficiario',
                    hint: 'Ejemplo: Mateo Flores Vargas',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Indica a nombre de quién se recauda.';
                    }
                    final words = text
                        .split(RegExp(r'\s+'))
                        .where((word) => word.isNotEmpty)
                        .toList();
                    if (words.length < 2) {
                      return 'Indica nombre y al menos un apellido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: beneficiaryRelationship,
                  items: relationshipOptions
                      .map((option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: isSubmitting ? null : onRelationshipChanged,
                  isExpanded: true,
                  decoration: solicitudFieldDecoration(
                    label: 'Relación con el beneficiario',
                    hint: 'Selecciona la opción que corresponda',
                    helper: 'Si eliges "Otro", detállalo en la descripción.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Selecciona la relación con el beneficiario.';
                    }
                    return null;
                  },
                ),
              ],
              if (_isKermesse) ...[
                ..._buildKermesseSections(theme),
              ] else if (!_isCampania && config.extraFields.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  config.extraSectionTitle,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...config.extraFields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _extraController(field.id),
                      enabled: !isSubmitting,
                      maxLines: field.maxLines,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: field.keyboardType,
                      decoration: solicitudFieldDecoration(
                        label: field.label,
                        hint: field.hint,
                      ),
                      validator: field.isRequired
                          ? (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Completa este dato para continuar.';
                              }
                              return null;
                            }
                          : null,
                    ),
                  );
                }),
              ],
              if (_isCampania || _isKermesse) ...[
                const SizedBox(height: 24),
                _FormSectionHeader(
                  icon: Icons.photo_library_rounded,
                  title: _isCampania
                      ? 'Evidencias fotográficas'
                      : 'Galería del evento',
                  subtitle: _isCampania ? 'Mínimo 2 imágenes' : 'Opcional',
                ),
                const SizedBox(height: 16),
                SolicitudEvidencePicker(
                  items: evidenceUploads,
                  uploading: isUploadingEvidence,
                  onAdd: onAddEvidence,
                  onRemove: onRemoveEvidence,
                  maxItems: maxEvidenceItems,
                  counterLabel:
                      _isCampania ? 'Evidencias cargadas' : 'Imágenes cargadas',
                  helperText: _isCampania
                      ? 'Sugerencia: comparte diagnósticos, facturas y fotos que respalden la historia.'
                      : 'Sugerencia: añade fotos del espacio, del equipo y de actividades previas para motivar la asistencia.',
                ),
              ],
              const SizedBox(height: 24),
              _FormSectionHeader(
                icon: Icons.image_rounded,
                title: 'Portada de la campaña',
                subtitle: 'Opcional · JPG, PNG · máx. 3 MB',
              ),
              const SizedBox(height: 16),
              _CoverPickerCard(
                previewBytes: coverPreviewBytes,
                uploading: uploadingCover,
                onPick: onPickCover,
                onRemove: onRemoveCover,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SolicitudFormCard(
            children: [
              // ─ Guidelines checkbox inside tinted container
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.12)),
                ),
                child: CheckboxListTile(
                  value: acceptsGuidelines,
                  onChanged: isSubmitting ? null : onAcceptGuidelinesChanged,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  activeColor: AppColors.bluePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  title: Text(
                    'Confirmo que la información es verificable y subiré evidencias del uso de fondos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // ─ Switch de privacidad: publicar como anónimo
              Container(
                decoration: BoxDecoration(
                  color: esAnonimo
                      ? AppColors.orangeAction.withValues(alpha: 0.08)
                      : AppColors.grayLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: esAnonimo
                        ? AppColors.orangeAction.withValues(alpha: 0.35)
                        : AppColors.dividerColor,
                  ),
                ),
                child: SwitchListTile.adaptive(
                  value: esAnonimo,
                  onChanged: isSubmitting ? null : onEsAnonimoChanged,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  activeColor: AppColors.orangeAction,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  secondary: Icon(
                    esAnonimo ? Icons.lock_rounded : Icons.lock_outline_rounded,
                    color: esAnonimo
                        ? AppColors.orangeAction
                        : AppColors.darkText.withValues(alpha: 0.5),
                  ),
                  title: Text(
                    'Publicar como anónimo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  subtitle: Text(
                    esAnonimo
                        ? 'Tu nombre y contacto no aparecerán en la vista pública. Solo el equipo admin podrá verlos.'
                        : 'Tu nombre aparecerá como creador de la solicitud.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const SolicitudInlineInfo(
                icon: Icons.notifications_rounded,
                message:
                    'Te enviaremos una notificación cuando cambie el estado de tu solicitud o se requiera información adicional.',
              ),
              const SizedBox(height: 24),
              // ─ Divider
              Container(
                height: 1,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Row(
                children: [
                  AppSecondaryButton(
                    label: 'Volver',
                    expanded: false,
                    onPressed: isSubmitting ? null : onBack,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      label: isSubmitting ? 'Enviando...' : 'Enviar solicitud',
                      icon: isSubmitting ? null : Icons.send_rounded,
                      onPressed: isSubmitting ? null : onSubmit,
                    ),
                  ),
                ],
              ),
              if (!isSubmitting)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Center(
                    child: TextButton(
                      onPressed: onCancel,
                      child: Text(
                        'Cancelar y cerrar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.40),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildKermesseSections(ThemeData theme) {
    SolicitudExtraField fieldById(String id) {
      return config.extraFields.firstWhere((field) => field.id == id);
    }

    final dateField = fieldById('event_date');
  final locationNameField = fieldById('event_location_name');
  final latField = fieldById('event_location_lat');
  final lngField = fieldById('event_location_lng');
    final beneficiariesField = fieldById('event_beneficiaries');
    final goalField = fieldById('event_goal');
    final partnersField = fieldById('event_partners');

    final dateController = _extraController(dateField.id);
    final locationNameController = _extraController(locationNameField.id);
    final latController = _extraController(latField.id);
    final lngController = _extraController(lngField.id);
    final beneficiariesController = _extraController(beneficiariesField.id);
    final goalController = _extraController(goalField.id);
    final partnersController = _extraController(partnersField.id);

    String? requiredValidator(String? value, String message) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    }

    Widget buildField({
      required SolicitudExtraField field,
      required TextEditingController controller,
      String? helper,
      String? Function(String?)? validator,
      bool readOnly = false,
      VoidCallback? onTap,
      List<TextInputFormatter>? inputFormatters,
      TextCapitalization textCapitalization = TextCapitalization.sentences,
      TextInputType? keyboardType,
      int? maxLines,
      Widget? suffixIcon,
    }) {
      final effectiveValidator = validator ?? (field.isRequired
          ? (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return 'Completa este dato para continuar.';
              }
              return null;
            }
          : null);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          enabled: !isSubmitting,
          readOnly: readOnly,
          onTap: readOnly && (isSubmitting || onTap == null)
              ? null
              : () {
                  if (isSubmitting) {
                    return;
                  }
                  onTap?.call();
                },
          maxLines: maxLines ?? field.maxLines,
          textCapitalization: textCapitalization,
          keyboardType: keyboardType ?? field.keyboardType,
          inputFormatters: inputFormatters,
          decoration: solicitudFieldDecoration(
            label: field.label,
            hint: field.hint,
            helper: helper,
          ).copyWith(suffixIcon: suffixIcon),
          validator: effectiveValidator,
        ),
      );
    }

    return [
      const SizedBox(height: 20),
      const _FormSectionHeader(
        icon: Icons.schedule_rounded,
        title: 'Agenda y horario',
        subtitle: 'Fecha y hora de inicio del evento',
      ),
      const SizedBox(height: 16),
      buildField(
        field: dateField,
        controller: dateController,
        helper: 'Selecciona la fecha y hora exacta en la que arranca la kermesse.',
        readOnly: true,
        onTap: onPickKermesseDate,
        suffixIcon: const Icon(Icons.event_outlined),
        validator: (value) => requiredValidator(
          value,
          'Define cuándo inicia la kermesse.',
        ),
      ),
      const SizedBox(height: 24),
      const _FormSectionHeader(
        icon: Icons.place_rounded,
        title: 'Ubicación del evento',
        subtitle: 'Punto visible en el mapa público',
      ),
      const SizedBox(height: 16),
      buildField(
        field: locationNameField,
        controller: locationNameController,
        helper: 'Puedes incluir referencias cercanas o el nombre del espacio comunitario.',
        textCapitalization: TextCapitalization.words,
        validator: (value) => requiredValidator(
          value,
          'Indica el nombre del lugar donde se realizará.',
        ),
      ),
      SolicitudKermesseLocationSelector(
        location: kermesseLocation,
        onPick: isSubmitting ? null : onPickKermesseLocation,
        onClear: isSubmitting || kermesseLocation == null ? null : onClearKermesseLocation,
        helperText: 'El punto seleccionado alimentará el mapa público y se guardará junto con la solicitud.',
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: CheckboxListTile(
          value: useManualKermesseCoords,
          onChanged: isSubmitting
              ? null
              : (value) => onManualKermesseCoordsChanged(value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Ingresar coordenadas manualmente'),
          subtitle: const Text('Marca esta opción si no puedes abrir Google Maps en tu dispositivo.'),
        ),
      ),
      if (useManualKermesseCoords) ...[
        Row(
          children: [
            Expanded(
              child: buildField(
                field: latField,
                controller: latController,
                helper: 'Copia la latitud desde Google Maps (ej. -17.7833).',
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]'))],
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                textCapitalization: TextCapitalization.none,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Ingresa la latitud en formato decimal.';
                  }
                  final parsed = double.tryParse(text.replaceAll(' ', '').replaceAll(',', '.'));
                  if (parsed == null) {
                    return 'Usa un número válido para la latitud.';
                  }
                  if (parsed < -90 || parsed > 90) {
                    return 'La latitud debe estar entre -90 y 90.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildField(
                field: lngField,
                controller: lngController,
                helper: 'Asegura que la longitud corresponda al mismo punto (ej. -63.1821).',
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]'))],
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                textCapitalization: TextCapitalization.none,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Ingresa la longitud en formato decimal.';
                  }
                  final parsed = double.tryParse(text.replaceAll(' ', '').replaceAll(',', '.'));
                  if (parsed == null) {
                    return 'Usa un número válido para la longitud.';
                  }
                  if (parsed < -180 || parsed > 180) {
                    return 'La longitud debe estar entre -180 y 180.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SolicitudInlineInfo(
            icon: Icons.info_outline_rounded,
            message: 'Obtén las coordenadas en Google Maps: toca y mantén presionado sobre el punto deseado.',
          ),
        ),
      ] else if (kermesseLocation != null) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SolicitudInlineInfo(
            icon: Icons.check_circle_rounded,
            message: 'Coordenadas guardadas: ${kermesseLocation!.coordinatesLabel}',
          ),
        ),
      ] else ...[
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SolicitudInlineInfo(
            icon: Icons.map_outlined,
            message: 'Selecciona el punto exacto en Google Maps para mostrarlo a los asistentes.',
          ),
        ),
      ],
      const SizedBox(height: 24),
      const _FormSectionHeader(
        icon: Icons.event_note_rounded,
        title: 'Programación y actividades',
        subtitle: 'Menú, shows y entretenimiento',
      ),
      const SizedBox(height: 16),
      SolicitudKermesseMenuList(
        items: menuItems,
        enabled: !isSubmitting,
        onAdd: onAddMenuItem,
        onEdit: onEditMenuItem,
        onRemove: onRemoveMenuItem,
      ),
      const SizedBox(height: 12),
      SolicitudKermesseActivityList(
        items: activityItems,
        enabled: !isSubmitting,
        onAdd: onAddActivity,
        onEdit: onEditActivity,
        onRemove: onRemoveActivity,
      ),
      const SizedBox(height: 24),
      const _FormSectionHeader(
        icon: Icons.people_rounded,
        title: 'Impacto social esperado',
        subtitle: 'Beneficiarios y destino de fondos',
      ),
      const SizedBox(height: 16),
      buildField(
        field: beneficiariesField,
        controller: beneficiariesController,
        helper: 'Cuenta quiénes se beneficiarán directamente del evento.',
        maxLines: beneficiariesField.maxLines,
      ),
      buildField(
        field: goalField,
        controller: goalController,
        helper: 'Explica a qué proyecto o causa se destinarán los fondos recaudados.',
        maxLines: goalField.maxLines,
      ),
      const SizedBox(height: 24),
      const _FormSectionHeader(
        icon: Icons.handshake_rounded,
        title: 'Aliados y patrocinadores',
        subtitle: 'Opcional',
      ),
      const SizedBox(height: 16),
      buildField(
        field: partnersField,
        controller: partnersController,
        helper: 'Menciona instituciones, empresas o voluntarios que ya confirmaron apoyo.',
        maxLines: partnersField.maxLines,
      ),
    ];
  }
}

class SolicitudFormCard extends StatelessWidget {
  const SolicitudFormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class SolicitudInlineInfo extends StatelessWidget {
  const SolicitudInlineInfo({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.bluePrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.darkText.withValues(alpha: 0.70),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SolicitudIntroCard extends StatelessWidget {
  const SolicitudIntroCard({super.key, required this.config, this.submitError});

  final SolicitudTypeConfig config;
  final String? submitError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKermesse = config.tipo == SolicitudTipo.kermesse;
    final accent =
        isKermesse ? AppColors.orangeAction : AppColors.bluePrimary;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
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
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
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
                      isKermesse
                          ? 'PASO 2 — DETALLES DEL EVENTO'
                          : 'PASO 2 — DETALLES DE LA CAMPAÑA',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: accent,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      config.introTitle,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      config.introDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.60),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    if (config.checklist.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: AppColors.darkText.withValues(alpha: 0.06),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'CHECKLIST RECOMENDADO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText.withValues(alpha: 0.45),
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...config.checklist.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 7),
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (submitError != null) ...[
                      const SizedBox(height: 14),
                      SolicitudInlineError(message: submitError!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SolicitudInlineError extends StatelessWidget {
  const SolicitudInlineError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orangeAction.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.orangeAction),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class SolicitudCoverImagePicker extends StatelessWidget {
  const SolicitudCoverImagePicker({
    super.key,
    required this.previewBytes,
    required this.imageUrl,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? previewBytes;
  final String? imageUrl;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = previewBytes != null || (imageUrl?.isNotEmpty ?? false);

    Widget imageWidget;
    if (previewBytes != null) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          previewBytes!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } else {
      imageWidget = Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.bluePrimary.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 28,
                color: AppColors.bluePrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sube una imagen de portada',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Formato horizontal · JPG o PNG',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.darkText.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            imageWidget,
            if (uploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                label: hasImage ? 'Reemplazar imagen' : 'Subir imagen',
                icon: Icons.upload_rounded,
                onPressed: uploading ? null : onPick,
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 12),
              AppSecondaryButton(
                label: 'Quitar',
                expanded: false,
                onPressed: uploading ? null : onRemove,
              ),
            ],
          ],
        ),
        if (hasImage)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.bluePrimary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Esta portada se mostrará en la lista pública de campañas.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.grayNeutral),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class SolicitudEvidencePicker extends StatelessWidget {
  const SolicitudEvidencePicker({
    super.key,
    required this.items,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
    required this.maxItems,
    this.counterLabel = 'Evidencias cargadas',
    this.helperText =
        'Sugerencia: comparte diagnósticos, facturas y fotos que respalden la historia.',
  });

  final List<SolicitudEvidenceUpload> items;
  final bool uploading;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final int maxItems;
  final String counterLabel;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < items.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      items[i].bytes,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: uploading ? null : () => onRemove(i),
                      ),
                    ),
                  ),
                ],
              ),
            if (items.length < maxItems)
              SizedBox(
                width: 120,
                height: 120,
                child: GestureDetector(
                  onTap: uploading ? null : onAdd,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.bluePrimary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.bluePrimary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            uploading
                                ? Icons.hourglass_top_rounded
                                : Icons.add_photo_alternate_rounded,
                            size: 19,
                            color: AppColors.bluePrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          uploading ? 'Subiendo...' : 'Agregar',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.bluePrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$counterLabel: ${items.length} / $maxItems',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.bluePrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          helperText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.darkText.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class SolicitudEvidenceUpload {
  const SolicitudEvidenceUpload({
    required this.bytes,
    required this.url,
    this.originalUrl,
  });

  /// Bytes que se muestran en el form (siempre la versión pública/tachada
  /// cuando es anónima, original cuando no).
  final Uint8List bytes;

  /// URL de la versión que se publica en el feed.
  final String url;

  /// URL del original sin tachar, solo para el admin. Null cuando la
  /// solicitud no es anónima (en ese caso `url` ya es el original).
  final String? originalUrl;
}

InputDecoration solicitudFieldDecoration({
  required String label,
  String? hint,
  String? helper,
  int helperMaxLines = 2,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: helperMaxLines,
    filled: true,
    fillColor: AppColors.lightBackground,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.dividerColor, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.dividerColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.bluePrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
  );
}

// ──────────────── Cover picker card ────────────────────────────────
class _CoverPickerCard extends StatelessWidget {
  const _CoverPickerCard({
    required this.previewBytes,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? previewBytes;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  bool get _hasImage => previewBytes != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppColors.radiusLg);

    if (uploading) {
      return Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: radius,
          border: Border.all(color: AppColors.dividerColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppColors.bluePrimary),
              ),
            ),
            const SizedBox(height: AppColors.space8),
            Text(
              'Subiendo portada…',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.bluePrimary,
                fontWeight: AppColors.fontWeightSemiBold,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasImage) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: double.infinity,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(previewBytes!, fit: BoxFit.cover),
              // scrim
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
                  ),
                ),
              ),
              Positioned(
                bottom: AppColors.space8,
                right: AppColors.space8,
                child: Row(
                  children: [
                    _CoverActionChip(icon: Icons.edit_rounded, label: 'Cambiar', onTap: onPick),
                    const SizedBox(width: AppColors.space8),
                    Material(
                      color: AppColors.error.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(AppColors.radiusRound),
                      child: InkWell(
                        onTap: onRemove,
                        borderRadius: BorderRadius.circular(AppColors.radiusRound),
                        child: const SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state — tappable area
    return Material(
      color: AppColors.lightBackground,
      borderRadius: radius,
      child: InkWell(
        onTap: onPick,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.dividerColor, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppColors.iconSizeXl,
                height: AppColors.iconSizeXl,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  boxShadow: AppColors.shadowSm,
                ),
                child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: AppColors.iconSizeMd),
              ),
              const SizedBox(height: AppColors.space12),
              Text(
                'Toca para elegir portada',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: AppColors.fontWeightBold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: AppColors.space4),
              Text(
                'Una imagen atractiva genera más donaciones',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.grayNeutral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverActionChip extends StatelessWidget {
  const _CoverActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppColors.radiusRound),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space12,
            vertical: AppColors.space8 - 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppColors.iconSizeSm - 3, color: AppColors.darkText),
              const SizedBox(width: AppColors.space4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: AppColors.fontWeightBold,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────── Form section header ────────────────────────────────
class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({
    // ignore: unused_element_parameter
    required this.icon,
    required this.title,
    this.subtitle,
    // ignore: unused_element_parameter
    this.accent = AppColors.bluePrimary,
  });

  /// Retenido por compatibilidad con call sites antiguos; ya no se renderiza.
  // ignore: unused_element
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barrita pequeña + eyebrow del título (mismo lenguaje que profile review)
        Row(
          children: [
            Container(
              width: 14,
              height: 2,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkText.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class SolicitudKermesseMenuItem {
  const SolicitudKermesseMenuItem({required this.name, this.price});

  final String name;
  final double? price;
}

class SolicitudKermesseActivity {
  const SolicitudKermesseActivity({required this.name, this.detail});

  final String name;
  final String? detail;
}

class SolicitudKermesseLocation {
  const SolicitudKermesseLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? address;

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

class SolicitudKermesseLocationSelector extends StatelessWidget {
  const SolicitudKermesseLocationSelector({
    super.key,
    required this.location,
    required this.onPick,
    required this.onClear,
    this.helperText,
  });

  final SolicitudKermesseLocation? location;
  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                label: location == null ? 'Elegir en Google Maps' : 'Cambiar punto en mapa',
                icon: Icons.map_outlined,
                onPressed: onPick,
              ),
            ),
            if (location != null) ...[
              const SizedBox(width: 12),
              AppSecondaryButton(
                label: 'Limpiar',
                expanded: false,
                icon: Icons.delete_outline,
                onPressed: onClear,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (location != null)
          Text(
            (location!.address != null && location!.address!.isNotEmpty)
                ? location!.address!
                : 'Punto seleccionado: ${location!.coordinatesLabel}',
            style: theme.textTheme.bodySmall,
          )
        else if (helperText != null)
          Text(
            helperText!,
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

class SolicitudKermesseMenuList extends StatelessWidget {
  const SolicitudKermesseMenuList({
    super.key,
    required this.items,
    required this.enabled,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<SolicitudKermesseMenuItem> items;
  final bool enabled;
  final VoidCallback onAdd;
  final void Function(int) onEdit;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FormSectionHeader(
          icon: Icons.restaurant_menu_rounded,
          title: 'Platos y precios',
          subtitle: 'Menú del evento',
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: SolicitudInlineInfo(
              icon: Icons.info_outline_rounded,
              message: 'Detalla cada plato con su precio para facilitar la difusión.',
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.dividerColor),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.orangeAction.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fastfood_rounded, size: 18, color: AppColors.orangeAction),
                    ),
                    title: Text(items[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: items[i].price != null
                        ? Text('Bs ${items[i].price!.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.greenSuccess, fontWeight: FontWeight.w600))
                        : const Text('Precio pendiente', style: TextStyle(color: AppColors.grayDark)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: AppColors.bluePrimary,
                          onPressed: enabled ? () => onEdit(i) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: AppColors.error,
                          onPressed: enabled ? () => onRemove(i) : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 4),
        AppSecondaryButton(
          label: 'Añadir plato',
          icon: Icons.add_rounded,
          onPressed: enabled ? onAdd : null,
        ),
      ],
    );
  }
}

class SolicitudKermesseActivityList extends StatelessWidget {
  const SolicitudKermesseActivityList({
    super.key,
    required this.items,
    required this.enabled,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<SolicitudKermesseActivity> items;
  final bool enabled;
  final VoidCallback onAdd;
  final void Function(int) onEdit;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FormSectionHeader(
          icon: Icons.music_note_rounded,
          title: 'Shows y entretenimiento',
          subtitle: 'Actividades del evento',
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: SolicitudInlineInfo(
              icon: Icons.info_outline_rounded,
              message: 'Registra grupos musicales, academias o juegos con su horario o costo.',
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.dividerColor),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.star_rounded, size: 18, color: AppColors.bluePrimary),
                    ),
                    title: Text(items[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: items[i].detail != null && items[i].detail!.isNotEmpty
                        ? Text(items[i].detail!, style: const TextStyle(color: AppColors.grayDark))
                        : const Text('Detalle pendiente', style: TextStyle(color: AppColors.grayNeutral)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: AppColors.bluePrimary,
                          onPressed: enabled ? () => onEdit(i) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: AppColors.error,
                          onPressed: enabled ? () => onRemove(i) : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 4),
        AppSecondaryButton(
          label: 'Añadir show o actividad',
          icon: Icons.add_rounded,
          onPressed: enabled ? onAdd : null,
        ),
      ],
    );
  }
}
