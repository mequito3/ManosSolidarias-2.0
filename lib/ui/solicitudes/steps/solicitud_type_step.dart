import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/solicitud.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';

class SolicitudTypeStep extends StatelessWidget {
  const SolicitudTypeStep({
    super.key,
    required this.configs,
    required this.selectedTipo,
    required this.onTipoChanged,
    required this.onBack,
    required this.onNext,
  });

  final List<SolicitudTypeConfig> configs;
  final SolicitudTipo selectedTipo;
  final ValueChanged<SolicitudTipo> onTipoChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header card ─────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.bluePrimary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.bluePrimary.withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo de iniciativa',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elige si es una campaña de recaudación directa o una kermesse presencial. Esto adapta el formulario a los datos necesarios.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.55),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SolicitudTypeSelector(
          configs: configs,
          selected: selectedTipo,
          onChanged: onTipoChanged,
        ),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Continuar',
          icon: Icons.arrow_forward_rounded,
          expanded: true,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class SolicitudTypeSelector extends StatelessWidget {
  const SolicitudTypeSelector({
    super.key,
    required this.configs,
    required this.selected,
    required this.onChanged,
  });

  final List<SolicitudTypeConfig> configs;
  final SolicitudTipo selected;
  final ValueChanged<SolicitudTipo> onChanged;

  static IconData _iconFor(SolicitudTipo tipo) {
    switch (tipo) {
      case SolicitudTipo.campania:
        return Icons.volunteer_activism_rounded;
      case SolicitudTipo.kermesse:
        return Icons.diversity_3_rounded;
      case SolicitudTipo.rifa:
        return Icons.confirmation_number_rounded;
    }
  }

  static Color _colorFor(SolicitudTipo tipo) {
    switch (tipo) {
      case SolicitudTipo.campania:
        return AppColors.bluePrimary;
      case SolicitudTipo.kermesse:
        return AppColors.orangeAction;
      case SolicitudTipo.rifa:
        return AppColors.grayNeutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: configs
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _TypeCardTile(
                config: entry.value,
                isSelected: entry.value.tipo == selected,
                icon: _iconFor(entry.value.tipo),
                accentColor: _colorFor(entry.value.tipo),
                onTap: () => onChanged(entry.value.tipo),
              ).animate()
                 .fade(duration: 400.ms, delay: (100 * entry.key).ms)
                 .slideY(begin: 0.1, curve: Curves.easeOutQuad, duration: 400.ms),
            ),
          )
          .toList(),
    );
  }
}

class _TypeCardTile extends StatelessWidget {
  const _TypeCardTile({
    required this.config,
    required this.isSelected,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final SolicitudTypeConfig config;
  final bool isSelected;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected ? accentColor.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? accentColor.withValues(alpha: 0.8) : AppColors.bluePrimary.withValues(alpha: 0.08),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ]
            : [
                BoxShadow(
                  color: AppColors.bluePrimary.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                // Icon badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isSelected ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.chipTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isSelected ? accentColor : AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.chipDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.55),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? accentColor : AppColors.dividerColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SolicitudTypeConfig {
  const SolicitudTypeConfig({
    required this.tipo,
    required this.chipTitle,
    required this.chipDescription,
    required this.sectionTitle,
    required this.titleLabel,
    required this.titleHint,
    required this.descriptionLabel,
    required this.descriptionHint,
    this.descriptionHelper,
    required this.goalLabel,
    required this.goalHint,
    required this.extraSectionTitle,
    required this.introTitle,
    required this.introDescription,
    required this.checklist,
    required this.extraFields,
  });

  final SolicitudTipo tipo;
  final String chipTitle;
  final String chipDescription;
  final String sectionTitle;
  final String titleLabel;
  final String titleHint;
  final String descriptionLabel;
  final String descriptionHint;
  final String? descriptionHelper;
  final String goalLabel;
  final String goalHint;
  final String extraSectionTitle;
  final String introTitle;
  final String introDescription;
  final List<String> checklist;
  final List<SolicitudExtraField> extraFields;
}

class SolicitudExtraField {
  const SolicitudExtraField({
    required this.id,
    required this.label,
    this.hint,
    this.isRequired = true,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  final String id;
  final String label;
  final String? hint;
  final bool isRequired;
  final int maxLines;
  final TextInputType keyboardType;
}

const Map<SolicitudTipo, SolicitudTypeConfig> solicitudTypeConfigs = {
  SolicitudTipo.campania: SolicitudTypeConfig(
    tipo: SolicitudTipo.campania,
    chipTitle: 'Campaña solidaria',
    chipDescription: 'Recauda fondos directos para una causa puntual.',
    sectionTitle: 'Información base de la campaña',
    titleLabel: 'Título de la campaña',
    titleHint: 'Ej. Cirugía para Mateo',
    descriptionLabel: 'Historia de la campaña',
    descriptionHint: 'Diagnóstico, costos y uso del dinero',
    descriptionHelper: 'Fechas clave, responsables y pasos. Máx. 300 caracteres.',
    goalLabel: 'Monto a recaudar (Bs)',
    goalHint: 'Ej. 18000',
    extraSectionTitle: '',
    introTitle: 'Antes de enviar tu campaña',
    introDescription:
        'Revisa que la historia sea clara, sube al menos dos evidencias fotográficas y explica con precisión el uso de cada boliviano.',
    checklist: [
      'Resumen médico o social con firma o sello que respalde la necesidad',
      'Presupuesto o cotización que explique el monto solicitado',
      'Cronograma tentativo con hitos principales y responsables de seguimiento',
    ],
  extraFields: [],
  ),
  SolicitudTipo.kermesse: SolicitudTypeConfig(
    tipo: SolicitudTipo.kermesse,
    chipTitle: 'Kermesse solidaria',
    chipDescription: 'Organiza un evento comunitario para recaudar.',
    sectionTitle: 'Información base del evento',
    titleLabel: 'Nombre del evento',
    titleHint: 'Ej. Kermesse pro-clínica',
    descriptionLabel: 'Descripción del evento',
    descriptionHint: 'Actividades y propósito',
    descriptionHelper: 'Resumen e impacto del evento. Máx. 300 caracteres.',
    goalLabel: '',
    goalHint: '',
    extraSectionTitle: 'Agenda, punto de encuentro e impacto',
    introTitle: 'Antes de enviar tu kermesse',
    introDescription:
        'Comparte el punto exacto del evento, la agenda y cómo se beneficiará la comunidad. Estos datos alimentarán el mapa público.',
    checklist: [
      'Coordenadas GPS validadas en Maps',
      'Permisos o aliados confirmados para uso del espacio público',
      'Agenda del evento con horarios de actividades principales',
    ],
    extraFields: [
      SolicitudExtraField(
        id: 'event_date',
        label: 'Fecha y hora del evento',
        hint: 'Toca para elegir día y hora',
      ),
      SolicitudExtraField(
        id: 'event_location_name',
        label: 'Nombre del lugar',
        hint: 'Ej. Plaza 24 de Septiembre',
      ),
      SolicitudExtraField(
        id: 'event_location_lat',
        label: 'Latitud',
        hint: 'Ej. -17.7833',
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
      ),
      SolicitudExtraField(
        id: 'event_location_lng',
        label: 'Longitud',
        hint: 'Ej. -63.1821',
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
      ),
      SolicitudExtraField(
        id: 'event_beneficiaries',
        label: 'Quiénes se benefician',
        hint: 'Ej. 40 niños de la escuela San José',
        maxLines: 3,
      ),
      SolicitudExtraField(
        id: 'event_goal',
        label: 'Destino de los fondos',
        hint: 'Ej. Reparación del techo del aula',
        maxLines: 3,
      ),
      SolicitudExtraField(
        id: 'event_partners',
        label: 'Aliados confirmados',
        hint: 'Ej. Colegio San Calixto, Farmacorp',
        isRequired: false,
        maxLines: 2,
      ),
    ],
  ),
};
