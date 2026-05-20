import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/solicitud.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_network_image.dart';
import 'solicitud_type_step.dart';

const int solicitudTitleMinCharacters = 8;
const int solicitudTitleMaxCharacters = 55;
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
          // El switch anónimo solo aplica a campañas. Kermesses son eventos
          // públicos por naturaleza (mapa + agenda visible).
          if (_isCampania) ...[
            _AnonymousSwitchCard(
              value: esAnonimo,
              enabled: !isSubmitting,
              onChanged: onEsAnonimoChanged,
            ),
            const SizedBox(height: 16),
          ],
          SolicitudFormCard(
            children: [
              SolicitudFormSectionHeader(
                title: config.sectionTitle,
                subtitle: config.chipTitle,
                showDivider: false,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: titleCtrl,
                enabled: !isSubmitting,
                maxLength: solicitudTitleMaxCharacters,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textCapitalization: TextCapitalization.sentences,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                decoration: solicitudFieldDecoration(
                  label: config.titleLabel,
                  hint: 'Ej. Cirugía para Mateo',
                  helper: 'Aparecerá en la lista pública.',
                  helperMaxLines: 2,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Indica un título breve para tu solicitud.';
                  }
                  if (text.length < solicitudTitleMinCharacters) {
                    return 'El título es demasiado corto, añade un poco más de contexto.';
                  }
                  return null;
                },
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: titleCtrl,
                builder: (context, value, _) {
                  final length = value.text.length;
                  final remaining = solicitudTitleMaxCharacters - length;
                  // Sólo mostramos el contador cuando empieza a importar.
                  if (length == 0 || remaining > 15) {
                    return const SizedBox(height: 4);
                  }
                  final color = remaining <= 0
                      ? AppColors.error
                      : remaining <= 5
                          ? AppColors.orangeAction
                          : AppColors.darkText.withValues(alpha: 0.45);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6, right: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$length / $solicitudTitleMaxCharacters',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
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
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
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
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: descriptionCtrl,
                builder: (context, value, _) {
                  final length = value.text.length;
                  final remaining = solicitudDescriptionMaxLength - length;
                  if (length == 0 || remaining > 50) {
                    return const SizedBox(height: 4);
                  }
                  final color = remaining <= 0
                      ? AppColors.error
                      : remaining <= 20
                          ? AppColors.orangeAction
                          : AppColors.darkText.withValues(alpha: 0.45);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6, right: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$length / $solicitudDescriptionMaxLength',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const SolicitudInlineInfo(
                icon: Icons.auto_awesome_rounded,
                message: 'El equipo asignará la categoría solidaria al revisar tu solicitud.',
              ),
              if (!_isKermesse) ...[
                const SizedBox(height: 24),
                const SolicitudFormSectionHeader(
                  icon: Icons.payments_rounded,
                  title: 'Meta económica',
                  subtitle: 'Monto que necesitas recaudar en bolivianos',
                  accent: AppColors.greenSuccess,
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
                    helper: 'En bolivianos. Déjalo vacío si no aplica.',
                  ).copyWith(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 6),
                      child: Text(
                        'Bs',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.darkText.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
              ],
              if (_isCampania) ...[
                const SizedBox(height: 28),
                const SolicitudFormSectionHeader(
                  icon: Icons.favorite_rounded,
                  title: 'Datos del beneficiario',
                  subtitle: 'A nombre de quién se recauda',
                  accent: AppColors.orangeAction,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: beneficiaryNameCtrl,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  decoration: solicitudFieldDecoration(
                    label: 'Nombre del beneficiario',
                    hint: 'Ej. Mateo Flores Vargas',
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
                            child: Text(
                              option,
                              softWrap: true,
                              maxLines: 2,
                            ),
                          ))
                      .toList(),
                  onChanged: isSubmitting ? null : onRelationshipChanged,
                  isExpanded: true,
                  itemHeight: 64,
                  menuMaxHeight: 480,
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
                const SizedBox(height: 28),
                SolicitudFormSectionHeader(
                  icon: Icons.photo_library_rounded,
                  title: _isCampania
                      ? 'Evidencias fotográficas'
                      : 'Galería del evento',
                  subtitle: _isCampania
                      ? 'Sube al menos 2 imágenes que respalden la historia'
                      : 'Opcional · fotos del espacio y del equipo',
                  accent: AppColors.bluePrimary,
                ),
                const SizedBox(height: 16),
                SolicitudEvidencePicker(
                  items: evidenceUploads,
                  uploading: isUploadingEvidence,
                  onAdd: onAddEvidence,
                  onRemove: onRemoveEvidence,
                  maxItems: maxEvidenceItems,
                  helperText: _isCampania
                      ? 'Comparte diagnósticos, facturas o fotos que respalden la historia.'
                      : 'Añade fotos del espacio, del equipo y de actividades previas.',
                ),
              ],
              const SizedBox(height: 28),
              SolicitudFormSectionHeader(
                icon: Icons.wallpaper_rounded,
                title: _isKermesse ? 'Portada del evento' : 'Portada de la campaña',
                subtitle: 'Opcional · JPG o PNG · máx. 3 MB',
                accent: AppColors.blueSecondary,
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
              CheckboxListTile(
                value: acceptsGuidelines,
                onChanged: isSubmitting ? null : onAcceptGuidelinesChanged,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppColors.bluePrimary,
                title: Text(
                  'Confirmo que la información es verificable y subiré evidencias del uso de fondos.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SolicitudInlineInfo(
                icon: Icons.notifications_none_rounded,
                message:
                    'Te avisaremos cuando cambie el estado de tu solicitud o necesitemos más información.',
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
    final beneficiariesField = fieldById('event_beneficiaries');
    final goalField = fieldById('event_goal');
    final partnersField = fieldById('event_partners');

    final dateController = _extraController(dateField.id);
    final locationNameController = _extraController(locationNameField.id);
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

      // Mismo patrón que el form de Campaña: TextFormField directo, sin
      // wrapper Padding. El spacing se controla con SizedBox entre fields.
      return TextFormField(
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
      );
    }

    return [
      // ── Sección 3: Agenda y horario ─────────────────────────────────
      const SizedBox(height: 28),
      const SolicitudFormSectionHeader(
        icon: Icons.event_rounded,
        title: 'Agenda y horario',
        subtitle: 'Fecha y hora de inicio del evento',
        accent: AppColors.orangeAction,
      ),
      const SizedBox(height: 16),
      buildField(
        field: dateField,
        controller: dateController,
        helper: 'Toca para elegir día y hora.',
        readOnly: true,
        onTap: onPickKermesseDate,
        suffixIcon: Icon(
          Icons.event_outlined,
          size: 20,
          color: AppColors.bluePrimary.withValues(alpha: 0.75),
        ),
        validator: (value) => requiredValidator(
          value,
          'Define cuándo inicia la kermesse.',
        ),
      ),
      // ── Sección 4: Ubicación del evento ─────────────────────────────
      const SizedBox(height: 28),
      const SolicitudFormSectionHeader(
        icon: Icons.place_rounded,
        title: 'Ubicación del evento',
        subtitle: 'Punto visible en el mapa público',
        accent: AppColors.bluePrimary,
      ),
      const SizedBox(height: 16),
      buildField(
        field: locationNameField,
        controller: locationNameController,
        textCapitalization: TextCapitalization.words,
        validator: (value) => requiredValidator(
          value,
          'Indica el nombre del lugar donde se realizará.',
        ),
      ),
      const SizedBox(height: 16),
      SolicitudKermesseLocationSelector(
        location: kermesseLocation,
        onPick: isSubmitting ? null : onPickKermesseLocation,
        onClear: isSubmitting || kermesseLocation == null ? null : onClearKermesseLocation,
      ),
      // ── Sección 5: Impacto social esperado ──────────────────────────
      const SizedBox(height: 28),
      const SolicitudFormSectionHeader(
        icon: Icons.volunteer_activism_rounded,
        title: 'Impacto social esperado',
        subtitle: 'Beneficiarios y destino de los fondos',
        accent: AppColors.greenSuccess,
      ),
      const SizedBox(height: 16),
      buildField(
        field: beneficiariesField,
        controller: beneficiariesController,
        maxLines: beneficiariesField.maxLines,
        validator: (value) => requiredValidator(
          value,
          'Cuéntanos a quiénes beneficiará la kermesse.',
        ),
      ),
      const SizedBox(height: 16),
      buildField(
        field: goalField,
        controller: goalController,
        maxLines: goalField.maxLines,
        validator: (value) => requiredValidator(
          value,
          'Indica el destino de lo que se recaude.',
        ),
      ),
      // ── Sección 6: Programación y oferta ────────────────────────────
      const SizedBox(height: 28),
      const SolicitudFormSectionHeader(
        icon: Icons.restaurant_menu_rounded,
        title: 'Programación y oferta',
        subtitle: 'Lo que ofrecerás a los asistentes',
        accent: AppColors.orangeAction,
      ),
      const SizedBox(height: 16),
      _SubsectionLabel(
        label: menuItems.isEmpty
            ? 'Menú y platos'
            : 'Menú y platos · ${menuItems.length} agregados',
      ),
      const SizedBox(height: 8),
      SolicitudKermesseMenuList(
        items: menuItems,
        enabled: !isSubmitting,
        onAdd: onAddMenuItem,
        onEdit: onEditMenuItem,
        onRemove: onRemoveMenuItem,
      ),
      const SizedBox(height: 20),
      _SubsectionLabel(
        label: activityItems.isEmpty
            ? 'Shows y actividades'
            : 'Shows y actividades · ${activityItems.length} agregadas',
      ),
      const SizedBox(height: 8),
      SolicitudKermesseActivityList(
        items: activityItems,
        enabled: !isSubmitting,
        onAdd: onAddActivity,
        onEdit: onEditActivity,
        onRemove: onRemoveActivity,
      ),
      if (menuItems.isEmpty || activityItems.isEmpty) ...[
        const SizedBox(height: 12),
        const SolicitudInlineInfo(
          icon: Icons.info_outline_rounded,
          message: 'Los asistentes ven mejor tu evento con al menos 2 platos y 1 show.',
        ),
      ],
      // ── Sección 7: Aliados y patrocinadores ─────────────────────────
      const SizedBox(height: 28),
      const SolicitudFormSectionHeader(
        icon: Icons.handshake_rounded,
        title: 'Aliados y patrocinadores',
        subtitle: 'Opcional · suma confianza al evento',
        accent: AppColors.blueSecondary,
      ),
      const SizedBox(height: 16),
      buildField(
        field: partnersField,
        controller: partnersController,
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
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 14,
            color: AppColors.darkText.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.darkText.withValues(alpha: 0.60),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnonymousSwitchCard extends StatelessWidget {
  const _AnonymousSwitchCard({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = value ? AppColors.orangeAction : AppColors.darkText;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            value ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: accent,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Publicar como anónimo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value
                      ? 'Al subir cada foto, abrirás el editor para tachar caras y datos.'
                      : 'Tu nombre aparecerá como creador de la solicitud.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.darkText.withValues(alpha: 0.60),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.orangeAction,
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
      imageWidget = AppNetworkImage(
        url: imageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(16),
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
    this.helperText =
        'Comparte diagnósticos, facturas o fotos que respalden la historia.',
  });

  final List<SolicitudEvidenceUpload> items;
  final bool uploading;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final int maxItems;
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
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.darkText.withValues(alpha: 0.14),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          uploading
                              ? Icons.hourglass_top_outlined
                              : Icons.add_outlined,
                          size: 24,
                          color: AppColors.darkText.withValues(alpha: 0.45),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          uploading ? 'Subiendo…' : 'Agregar',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.darkText.withValues(alpha: 0.65),
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
        Text(
          '${items.length} de $maxItems · $helperText',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.darkText.withValues(alpha: 0.55),
            fontSize: 12.5,
            height: 1.4,
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
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
    ),
    hintStyle: TextStyle(
      fontSize: 15,
      color: AppColors.darkText.withValues(alpha: 0.40),
    ),
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

    // Empty state — tappable area, dashed-feel border, sin badge gradient.
    return Material(
      color: AppColors.lightBackground,
      borderRadius: radius,
      child: InkWell(
        onTap: onPick,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: AppColors.darkText.withValues(alpha: 0.14),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.darkText.withValues(alpha: 0.40),
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                'Toca para elegir una portada',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Opcional · ayuda a generar más donaciones',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.45),
                  fontSize: 12,
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
//
// Jerarquía puramente tipográfica: número de paso pequeño + título grande
// + subtítulo. Sin badges ni iconos para no saturar el formulario.
class SolicitudFormSectionHeader extends StatelessWidget {
  const SolicitudFormSectionHeader({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.showDivider = true,
    this.accent = AppColors.bluePrimary,
  });

  /// Mantenido por compatibilidad con call sites; ya no se renderiza.
  // ignore: unused_element
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool showDivider;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider) ...[
          Container(
            height: 1,
            color: AppColors.darkText.withValues(alpha: 0.07),
          ),
          const SizedBox(height: 16),
        ],
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                margin: const EdgeInsets.only(top: 3, right: 10),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.darkText.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel({
    // ignore: unused_element_parameter
    this.icon,
    required this.label,
    // ignore: unused_element_parameter
    this.accent = AppColors.bluePrimary,
  });

  // ignore: unused_element
  final IconData? icon;
  final String label;
  // ignore: unused_element
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
        letterSpacing: -0.1,
      ),
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
  });

  final SolicitudKermesseLocation? location;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (location == null) {
      // Empty state — card grande tappable estilo "elegir foto"
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.bluePrimary.withValues(alpha: 0.30),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.bluePrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tocar para elegir en el mapa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Marca el punto exacto del evento.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.darkText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.bluePrimary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Filled state — punto seleccionado con detalle + acciones
    final addressLine = (location!.address != null && location!.address!.isNotEmpty)
        ? location!.address!
        : 'Punto seleccionado en el mapa';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.greenSuccess.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greenSuccess.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.greenSuccess.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.greenSuccess,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Punto confirmado',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenSuccess,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  addressLine,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.darkText,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: onPick,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit_location_alt_outlined,
                                size: 16, color: AppColors.bluePrimary),
                            SizedBox(width: 4),
                            Text(
                              'Cambiar',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.bluePrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onClear != null) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onClear,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete_outline_rounded,
                                  size: 16, color: AppColors.darkText),
                              const SizedBox(width: 4),
                              Text(
                                'Quitar',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText
                                      .withValues(alpha: 0.70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          _EmptyListHint(
            icon: Icons.restaurant_menu_rounded,
            accent: AppColors.orangeAction,
            message: 'Aún no agregaste platos. Detalla cada uno con su precio.',
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _KermesseListItem(
                  icon: Icons.fastfood_rounded,
                  accent: AppColors.orangeAction,
                  title: items[i].name,
                  subtitle: items[i].price != null
                      ? 'Bs ${items[i].price!.toStringAsFixed(2)}'
                      : 'Precio pendiente',
                  subtitleColor: items[i].price != null
                      ? AppColors.greenSuccess
                      : AppColors.darkText.withValues(alpha: 0.50),
                  onEdit: enabled ? () => onEdit(i) : null,
                  onRemove: enabled ? () => onRemove(i) : null,
                ),
            ],
          ),
        const SizedBox(height: 10),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          _EmptyListHint(
            icon: Icons.music_note_rounded,
            accent: AppColors.bluePrimary,
            message: 'Aún no agregaste shows. Grupos, juegos o actividades con horario.',
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _KermesseListItem(
                  icon: Icons.star_rounded,
                  accent: AppColors.bluePrimary,
                  title: items[i].name,
                  subtitle: items[i].detail != null && items[i].detail!.isNotEmpty
                      ? items[i].detail!
                      : 'Detalle pendiente',
                  subtitleColor: items[i].detail != null && items[i].detail!.isNotEmpty
                      ? AppColors.darkText.withValues(alpha: 0.60)
                      : AppColors.darkText.withValues(alpha: 0.40),
                  onEdit: enabled ? () => onEdit(i) : null,
                  onRemove: enabled ? () => onRemove(i) : null,
                ),
            ],
          ),
        const SizedBox(height: 10),
        AppSecondaryButton(
          label: 'Añadir show',
          icon: Icons.add_rounded,
          onPressed: enabled ? onAdd : null,
        ),
      ],
    );
  }
}

/// Card vacía con icono + mensaje, para listas sin items.
class _EmptyListHint extends StatelessWidget {
  const _EmptyListHint({
    required this.icon,
    required this.accent,
    required this.message,
  });

  final IconData icon;
  final Color accent;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
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

/// Item de lista (plato o actividad): icono accent, título, subtítulo y
/// acciones editar/quitar. Card unificada para los 2 listas de kermesse.
class _KermesseListItem extends StatelessWidget {
  const _KermesseListItem({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.onEdit,
    required this.onRemove,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.darkText.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.bluePrimary,
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.darkText.withValues(alpha: 0.55),
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
