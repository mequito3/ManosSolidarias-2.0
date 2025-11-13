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
    required this.onPickCover,
    required this.onRemoveCover,
    required this.coverPreviewBytes,
    required this.uploadedCoverUrl,
    required this.uploadingCover,
    required this.acceptsGuidelines,
    required this.onAcceptGuidelinesChanged,
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
  final VoidCallback onPickCover;
  final VoidCallback onRemoveCover;
  final Uint8List? coverPreviewBytes;
  final String? uploadedCoverUrl;
  final bool uploadingCover;
  final bool acceptsGuidelines;
  final ValueChanged<bool?> onAcceptGuidelinesChanged;
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
              Text(
                config.sectionTitle,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Tipo seleccionado: ${config.chipTitle}',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleCtrl,
                enabled: !isSubmitting,
                maxLength: solicitudTitleMaxCharacters,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textCapitalization: TextCapitalization.words,
                decoration: solicitudFieldDecoration(
                  label: config.titleLabel,
                  hint: config.titleHint,
                  helper:
                      'Ejemplos de títulos inspiradores: Cirugía para Mateo · Medicinas para Sofía · Techo para la familia Pérez.',
                  helperMaxLines: 3,
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
                    return 'Reduce el título: procura no superar $solicitudTitleMaxWords palabras.';
                  }
                  if (text.length > solicitudTitleMaxCharacters) {
                    return 'Máximo $solicitudTitleMaxCharacters caracteres para mantenerlo legible.';
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
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Palabras: $wordCount/$solicitudTitleMaxWords',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverLimit
                            ? theme.colorScheme.error
                            : AppColors.darkText.withOpacity(0.6),
                      ),
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
                icon: Icons.category_outlined,
                message: 'El equipo asignará la categoría solidaria al revisar tu solicitud.',
              ),
              const SizedBox(height: 16),
              if (!_isKermesse)
                TextFormField(
                  controller: goalCtrl,
                  enabled: !isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: solicitudFieldDecoration(
                    label: config.goalLabel,
                    hint: config.goalHint,
                    helper: 'Ingresa el monto en bolivianos. Deja vacío si no aplica.',
                  ).copyWith(
                    prefixText: 'Bs ',
                    prefixStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    suffixIcon: const Icon(Icons.payments_outlined),
                  ),
                ),
              if (_isCampania) ...[
                const SizedBox(height: 20),
                Text(
                  'Datos del beneficiario',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
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
                    if (text.length < 6) {
                      return 'Usa al menos nombre y primer apellido.';
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
                const SizedBox(height: 20),
                Text(
                  _isCampania
                      ? 'Evidencias fotográficas (mínimo 2)'
                      : 'Galería de imágenes del evento (opcional)',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
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
              const SizedBox(height: 20),
              Text(
                'Portada principal',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SolicitudCoverImagePicker(
                previewBytes: coverPreviewBytes,
                imageUrl: uploadedCoverUrl,
                uploading: uploadingCover,
                onPick: onPickCover,
                onRemove: onRemoveCover,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SolicitudFormCard(
            children: [
              CheckboxListTile(
                value: acceptsGuidelines,
                onChanged: isSubmitting ? null : onAcceptGuidelinesChanged,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Confirmo que la información es verificable y subiré evidencias del uso de fondos.',
                ),
              ),
              const SizedBox(height: 12),
              const SolicitudInlineInfo(
                icon: Icons.notifications_active_outlined,
                message:
                    'Te enviaremos una notificación cuando cambie el estado de tu solicitud o se requiera información adicional.',
              ),
              const SizedBox(height: 20),
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
              TextButton(
                onPressed: isSubmitting ? null : onCancel,
                child: const Text('Cancelar y cerrar'),
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
      Text(
        'Agenda y horario del evento',
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
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
      const SizedBox(height: 20),
      Text(
        'Ubicación para el mapa público',
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
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
      CheckboxListTile(
        value: useManualKermesseCoords,
        onChanged: isSubmitting
            ? null
            : (value) => onManualKermesseCoordsChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: const Text('Ingresar coordenadas manualmente'),
        subtitle: const Text('Marca esta opción si no puedes abrir Google Maps en tu dispositivo.'),
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
                  return null;
                },
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Puedes obtener las coordenadas desde Google Maps tocando y manteniendo presionado sobre el punto.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.darkText.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ] else if (kermesseLocation != null) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Coordenadas guardadas automáticamente: ${kermesseLocation!.coordinatesLabel}',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.darkText.withValues(alpha: 0.7)),
          ),
        ),
      ] else ...[
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Selecciona el punto exacto en Google Maps para mostrarlo a los asistentes.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.darkText.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      Text(
        'Programación y actividades',
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
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
      const SizedBox(height: 12),
      Text(
        'Impacto social esperado',
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
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
      const SizedBox(height: 12),
      Text(
        'Aliados y patrocinadores (opcional)',
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.bluePrimary.withValues(alpha: 0.85)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.introTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              config.introDescription,
              style: theme.textTheme.bodySmall,
            ),
            if (config.checklist.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Checklist recomendado', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...config.checklist.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: AppColors.greenSuccess),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (submitError != null) ...[
              const SizedBox(height: 16),
              SolicitudInlineError(message: submitError!),
            ],
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
          border: Border.all(color: AppColors.grayNeutral),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.image_outlined, size: 44, color: AppColors.grayNeutral),
            SizedBox(height: 8),
            Text('Añade una imagen en formato horizontal'),
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
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Esta portada se mostrará en la lista pública de campañas.',
              style: TextStyle(fontSize: 12),
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
                child: OutlinedButton(
                  onPressed: uploading ? null : onAdd,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.grayNeutral.withValues(alpha: 0.8)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        uploading ? Icons.hourglass_top_outlined : Icons.add_photo_alternate_outlined,
                        size: 26,
                        color: AppColors.bluePrimary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        uploading ? 'Subiendo...' : 'Agregar',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$counterLabel: ${items.length} de $maxItems',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class SolicitudEvidenceUpload {
  const SolicitudEvidenceUpload({required this.bytes, required this.url});

  final Uint8List bytes;
  final String url;
}

InputDecoration solicitudFieldDecoration({
  required String label,
  String? hint,
  String? helper,
  int helperMaxLines = 1,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: helperMaxLines,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.grayNeutral, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.grayNeutral, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
    ),
  );
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
        if (location != null) ...[
          if (location!.address != null && location!.address!.isNotEmpty)
            Text(
              location!.address!,
              style: theme.textTheme.bodySmall,
            ),
        ]
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
        Text(
          'Platos y precios',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Detalla cada plato con su precio para facilitar la difusión.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(items[i].name),
                    subtitle: items[i].price != null
                        ? Text('Costo sugerido: Bs ${items[i].price!.toStringAsFixed(2)}')
                        : const Text('Costo sugerido: pendiente'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: enabled ? () => onEdit(i) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: enabled ? () => onRemove(i) : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        AppSecondaryButton(
          label: 'Añadir plato',
          icon: Icons.add_outlined,
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
        Text(
          'Shows y entretenimiento',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Registra grupos musicales, academias o juegos con su horario o costo.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(items[i].name),
                    subtitle: items[i].detail != null && items[i].detail!.isNotEmpty
                        ? Text(items[i].detail!)
                        : const Text('Detalle pendiente'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: enabled ? () => onEdit(i) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: enabled ? () => onRemove(i) : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        AppSecondaryButton(
          label: 'Añadir show o actividad',
          icon: Icons.add_outlined,
          onPressed: enabled ? onAdd : null,
        ),
      ],
    );
  }
}
