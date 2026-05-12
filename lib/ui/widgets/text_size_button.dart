import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/text_scale_manager.dart';
import '../settings/text_size_settings_page.dart';

/// Botón flotante para acceder rápido a la configuración de tamaño de texto
class TextSizeButton extends StatelessWidget {
  const TextSizeButton({
    super.key,
    required this.textScaleManager,
  });

  final TextScaleManager textScaleManager;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: textScaleManager,
      builder: (context, _) {
        return IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TextSizeSettingsPage(
                  textScaleManager: textScaleManager,
                ),
              ),
            );
          },
          icon: const Icon(Icons.text_fields),
          tooltip: 'Tamaño de texto',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.lightBackground,
            foregroundColor: AppColors.darkText,
          ),
        );
      },
    );
  }
}

/// Badge indicator para mostrar el tamaño actual
class TextSizeBadge extends StatelessWidget {
  const TextSizeBadge({
    super.key,
    required this.textScaleManager,
  });

  final TextScaleManager textScaleManager;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: textScaleManager,
      builder: (context, _) {
        final preset = textScaleManager.currentPresetName;
        final isCustom = preset == 'Personalizado';
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bluePrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isCustom 
              ? '${(textScaleManager.textScaleFactor * 100).toInt()}%'
              : preset[0], // Primera letra del preset
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.bluePrimary,
            ),
          ),
        );
      },
    );
  }
}
