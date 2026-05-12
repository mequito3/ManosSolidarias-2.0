import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/text_scale_manager.dart';

/// Página de configuración de tamaño de texto
class TextSizeSettingsPage extends StatefulWidget {
  const TextSizeSettingsPage({
    super.key,
    required this.textScaleManager,
  });

  final TextScaleManager textScaleManager;

  @override
  State<TextSizeSettingsPage> createState() => _TextSizeSettingsPageState();
}

class _TextSizeSettingsPageState extends State<TextSizeSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Tamaño de texto'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              await widget.textScaleManager.resetScale();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tamaño restaurado a Normal'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.textScaleManager,
        builder: (context, _) {
          final manager = widget.textScaleManager;
          final currentScale = manager.textScaleFactor;
          final presetName = manager.currentPresetName;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Banner informativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.bluePrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.bluePrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ajusta el tamaño de texto según tu preferencia. Los cambios se aplican en toda la aplicación.',
                        style: TextStyle(
                          color: AppColors.bluePrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Presets rápidos
              Text(
                'Tamaños predefinidos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
              ),
              const SizedBox(height: 16),

              ...TextScaleManager.presetScales.entries.map((entry) {
                final isSelected = (entry.value - currentScale).abs() < 0.01;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PresetTile(
                    label: entry.key,
                    scale: entry.value,
                    isSelected: isSelected,
                    onTap: () => manager.setPresetScale(entry.key),
                  ),
                );
              }).toList(),

              const SizedBox(height: 32),

              // Control deslizante
              Text(
                'Ajuste personalizado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Actual: $presetName (${(currentScale * 100).toInt()}%)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mediumText,
                    ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  IconButton(
                    onPressed: manager.canDecrease
                        ? () => manager.decreaseScale()
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.bluePrimary,
                    iconSize: 32,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.bluePrimary,
                        inactiveTrackColor: AppColors.grayLight,
                        thumbColor: AppColors.bluePrimary,
                        overlayColor: AppColors.bluePrimary.withValues(alpha: 0.1),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: currentScale,
                        min: 0.8,
                        max: 1.5,
                        divisions: 14,
                        onChanged: (value) => manager.setTextScale(value),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: manager.canIncrease
                        ? () => manager.increaseScale()
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.bluePrimary,
                    iconSize: 32,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Vista previa
              Text(
                'Vista previa',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
              ),
              const SizedBox(height: 16),

              _PreviewCard(),
            ],
          );
        },
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.label,
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final double scale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.bluePrimary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.bluePrimary
                : AppColors.grayLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.bluePrimary : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(scale * 100).toInt()}% del tamaño base',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mediumText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.bluePrimary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.campaign,
                  color: AppColors.bluePrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Campaña de ejemplo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Este es un texto de ejemplo para mostrar cómo se verá el contenido con el tamaño seleccionado.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mediumText,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.favorite,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                '150 apoyos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumText,
                    ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.comment,
                size: 16,
                color: AppColors.bluePrimary,
              ),
              const SizedBox(width: 4),
              Text(
                '23 comentarios',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumText,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
