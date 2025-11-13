import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Tipos de estado para chips
enum ChipStatus {
  success,
  warning,
  error,
  info,
  neutral,
  pending,
  approved,
  rejected,
  completed,
}

/// Chip estandarizado para mostrar estados
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.status = ChipStatus.neutral,
    this.icon,
    this.size = ChipSize.medium,
  });

  final String label;
  final ChipStatus status;
  final IconData? icon;
  final ChipSize size;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    final sizeConfig = _getSizeConfig(size);

    return Container(
      padding: sizeConfig.padding,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: sizeConfig.iconSize,
              color: config.textColor,
            ),
            SizedBox(width: sizeConfig.spacing),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: sizeConfig.fontSize,
              fontWeight: AppColors.fontWeightSemiBold,
              color: config.textColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  _ChipColorConfig _getStatusConfig(ChipStatus status) {
    switch (status) {
      case ChipStatus.success:
      case ChipStatus.approved:
      case ChipStatus.completed:
        return _ChipColorConfig(
          backgroundColor: AppColors.greenSuccess.withValues(alpha: 0.15),
          borderColor: AppColors.greenSuccess.withValues(alpha: 0.3),
          textColor: AppColors.greenSuccess,
        );
      case ChipStatus.warning:
      case ChipStatus.pending:
        return _ChipColorConfig(
          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
          borderColor: AppColors.warning.withValues(alpha: 0.3),
          textColor: AppColors.warning,
        );
      case ChipStatus.error:
      case ChipStatus.rejected:
        return _ChipColorConfig(
          backgroundColor: AppColors.error.withValues(alpha: 0.15),
          borderColor: AppColors.error.withValues(alpha: 0.3),
          textColor: AppColors.error,
        );
      case ChipStatus.info:
        return _ChipColorConfig(
          backgroundColor: AppColors.info.withValues(alpha: 0.15),
          borderColor: AppColors.info.withValues(alpha: 0.3),
          textColor: AppColors.info,
        );
      case ChipStatus.neutral:
        return _ChipColorConfig(
          backgroundColor: AppColors.grayLight,
          borderColor: AppColors.grayNeutral.withValues(alpha: 0.3),
          textColor: AppColors.darkText,
        );
    }
  }

  _ChipSizeConfig _getSizeConfig(ChipSize size) {
    switch (size) {
      case ChipSize.small:
        return _ChipSizeConfig(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space8,
            vertical: AppColors.space4,
          ),
          fontSize: AppColors.fontSizeXs,
          iconSize: 12.0,
          spacing: AppColors.space4,
        );
      case ChipSize.medium:
        return _ChipSizeConfig(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space12,
            vertical: AppColors.space8,
          ),
          fontSize: AppColors.fontSizeSm,
          iconSize: AppColors.iconSizeSm,
          spacing: AppColors.space8,
        );
      case ChipSize.large:
        return _ChipSizeConfig(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space16,
            vertical: AppColors.space12,
          ),
          fontSize: AppColors.fontSizeBase,
          iconSize: AppColors.iconSizeMd,
          spacing: AppColors.space8,
        );
    }
  }
}

/// Chip con gradiente (para estados destacados)
class AppGradientChip extends StatelessWidget {
  const AppGradientChip({
    super.key,
    required this.label,
    this.gradient = AppColors.primaryGradient,
    this.icon,
    this.size = ChipSize.medium,
  });

  final String label;
  final Gradient gradient;
  final IconData? icon;
  final ChipSize size;

  @override
  Widget build(BuildContext context) {
    final sizeConfig = _getSizeConfig(size);

    return Container(
      padding: sizeConfig.padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: sizeConfig.iconSize,
              color: Colors.white,
            ),
            SizedBox(width: sizeConfig.spacing),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: sizeConfig.fontSize,
              fontWeight: AppColors.fontWeightSemiBold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  _ChipSizeConfig _getSizeConfig(ChipSize size) {
    switch (size) {
      case ChipSize.small:
        return _ChipSizeConfig(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space8,
            vertical: AppColors.space4,
          ),
          fontSize: AppColors.fontSizeXs,
          iconSize: 12.0,
          spacing: AppColors.space4,
        );
      case ChipSize.medium:
        return _ChipSizeConfig(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space12,
            vertical: AppColors.space8,
          ),
          fontSize: AppColors.fontSizeSm,
          iconSize: AppColors.iconSizeSm,
          spacing: AppColors.space8,
        );
      case ChipSize.large:
        return _ChipSizeConfig(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space16,
            vertical: AppColors.space12,
          ),
          fontSize: AppColors.fontSizeBase,
          iconSize: AppColors.iconSizeMd,
          spacing: AppColors.space8,
        );
    }
  }
}

/// Chip simple con categoría (para tags/categorías)
class AppCategoryChip extends StatelessWidget {
  const AppCategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.size = ChipSize.medium,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final ChipSize size;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.bluePrimary;
    final sizeConfig = _getSizeConfig(size);

    return Container(
      padding: sizeConfig.padding,
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: sizeConfig.iconSize,
              color: chipColor,
            ),
            SizedBox(width: sizeConfig.spacing),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: sizeConfig.fontSize,
              fontWeight: AppColors.fontWeightSemiBold,
              color: chipColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  _ChipSizeConfig _getSizeConfig(ChipSize size) {
    switch (size) {
      case ChipSize.small:
        return _ChipSizeConfig(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space8,
            vertical: AppColors.space4,
          ),
          fontSize: AppColors.fontSizeXs,
          iconSize: 12.0,
          spacing: AppColors.space4,
        );
      case ChipSize.medium:
        return _ChipSizeConfig(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space12,
            vertical: AppColors.space8,
          ),
          fontSize: AppColors.fontSizeSm,
          iconSize: AppColors.iconSizeSm,
          spacing: AppColors.space8,
        );
      case ChipSize.large:
        return _ChipSizeConfig(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space16,
            vertical: AppColors.space12,
          ),
          fontSize: AppColors.fontSizeBase,
          iconSize: AppColors.iconSizeMd,
          spacing: AppColors.space8,
        );
    }
  }
}

// ============ CLASES PRIVADAS ============

enum ChipSize {
  small,
  medium,
  large,
}

class _ChipColorConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  _ChipColorConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}

class _ChipSizeConfig {
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double spacing;

  _ChipSizeConfig({
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.spacing,
  });
}
