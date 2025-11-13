import 'package:flutter/material.dart';

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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona el tipo de solicitud',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Elige si tu iniciativa es una campaña de recaudación directa o una kermesse presencial. Esto adaptará el formulario a los datos necesarios.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SolicitudTypeSelector(
          configs: configs,
          selected: selectedTipo,
          onChanged: onTipoChanged,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
           
            const SizedBox(width: 12),
            AppPrimaryButton(
              label: 'Continuar',
              icon: Icons.arrow_forward_rounded,
              expanded: false,
              onPressed: onNext,
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige el tipo de solicitud',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: configs.map((config) {
                final isSelected = config.tipo == selected;
                return ChoiceChip(
                  label: SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          config.chipTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.darkText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          config.chipDescription,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Colors.white.withOpacity(0.9)
                                : AppColors.darkText.withOpacity(0.75),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onChanged(config.tipo),
                  showCheckmark: false,
                  selectedColor: AppColors.bluePrimary,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isSelected ? AppColors.bluePrimary : AppColors.grayNeutral,
                      width: 1.3,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
    titleHint: 'Ingresa un título preciso y fácil de recordar.',
    descriptionLabel: 'Historia completa de la campaña',
    descriptionHint: 'Describe el diagnóstico, los costos principales y cómo se usará cada aporte.',
    descriptionHelper:
        'Incluye fechas clave, responsables y pasos previstos en un máximo de 300 caracteres.',
    goalLabel: 'Meta económica estimada (Bs)',
    goalHint:
        'Ej.: 18000 para cubrir cirugía, medicamentos y rehabilitación. Déjalo vacío si lo definirás luego.',
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
    titleHint: 'Ingresa un nombre claro que represente el evento.',
    descriptionLabel: 'Descripción general del evento',
    descriptionHint: 'Indica actividades, dinámica de recaudación y propósito social.',
    descriptionHelper: 'Resume el evento y su impacto en un máximo de 300 caracteres.',
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
        label: 'Fecha y horario de inicio',
        hint: 'Ejemplo: 24 de agosto de 2025 · 09:00',
      ),
      SolicitudExtraField(
        id: 'event_location_name',
        label: 'Nombre del lugar',
        hint: 'Plaza central, colegio, salón comunitario, etc.',
      ),
      SolicitudExtraField(
        id: 'event_location_lat',
        label: 'Latitud del punto GPS',
        hint: 'Ingresa la coordenada decimal (ej. -25.34321).',
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
      ),
      SolicitudExtraField(
        id: 'event_location_lng',
        label: 'Longitud del punto GPS',
        hint: 'Ingresa la coordenada decimal (ej. -57.64120).',
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
      ),
      SolicitudExtraField(
        id: 'event_beneficiaries',
        label: '¿Quiénes se beneficiarán?',
        hint: 'Describe a la comunidad, institución o personas destinatarias.',
        maxLines: 3,
      ),
      SolicitudExtraField(
        id: 'event_goal',
        label: '¿Para qué se usa lo recaudado?',
        hint: 'Explica el proyecto específico que financiarán los fondos.',
        maxLines: 3,
      ),
      SolicitudExtraField(
        id: 'event_partners',
        label: 'Aliados o patrocinadores (opcional)',
        hint: 'Empresas, instituciones o voluntarios confirmados.',
        isRequired: false,
        maxLines: 2,
      ),
    ],
  ),
};
