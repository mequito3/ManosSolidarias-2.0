import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Banner para mostrar mensajes de error
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({
    super.key,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onDismiss,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.space16),
      margin: const EdgeInsets.only(bottom: AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.errorLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.error,
            size: AppColors.iconSizeMd,
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontSize: AppColors.fontSizeBase,
                fontWeight: AppColors.fontWeightMedium,
                height: AppColors.lineHeightNormal,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppColors.space8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              child: Padding(
                padding: const EdgeInsets.all(AppColors.space4),
                child: Icon(
                  Icons.close_rounded,
                  size: AppColors.iconSizeSm,
                  color: AppColors.error.withValues(alpha: AppColors.opacitySecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner para mostrar mensajes informativos
class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.onDismiss,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.space16),
      margin: const EdgeInsets.only(bottom: AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.infoLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.infoLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.info,
            size: AppColors.iconSizeMd,
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.info,
                fontSize: AppColors.fontSizeBase,
                fontWeight: AppColors.fontWeightMedium,
                height: AppColors.lineHeightNormal,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppColors.space8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              child: Padding(
                padding: const EdgeInsets.all(AppColors.space4),
                child: Icon(
                  Icons.close_rounded,
                  size: AppColors.iconSizeSm,
                  color: AppColors.info.withValues(alpha: AppColors.opacitySecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner para mostrar mensajes de éxito
class AppSuccessBanner extends StatelessWidget {
  const AppSuccessBanner({
    super.key,
    required this.message,
    this.icon = Icons.check_circle_outline_rounded,
    this.onDismiss,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.space16),
      margin: const EdgeInsets.only(bottom: AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.greenSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.greenSuccess.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.greenSuccess,
            size: AppColors.iconSizeMd,
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.greenSuccess,
                fontSize: AppColors.fontSizeBase,
                fontWeight: AppColors.fontWeightMedium,
                height: AppColors.lineHeightNormal,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppColors.space8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              child: Padding(
                padding: const EdgeInsets.all(AppColors.space4),
                child: Icon(
                  Icons.close_rounded,
                  size: AppColors.iconSizeSm,
                  color: AppColors.greenSuccess.withValues(alpha: AppColors.opacitySecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner para mostrar mensajes de advertencia
class AppWarningBanner extends StatelessWidget {
  const AppWarningBanner({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.onDismiss,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.space16),
      margin: const EdgeInsets.only(bottom: AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.warningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.warningLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.warning,
            size: AppColors.iconSizeMd,
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.warning,
                fontSize: AppColors.fontSizeBase,
                fontWeight: AppColors.fontWeightMedium,
                height: AppColors.lineHeightNormal,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppColors.space8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              child: Padding(
                padding: const EdgeInsets.all(AppColors.space4),
                child: Icon(
                  Icons.close_rounded,
                  size: AppColors.iconSizeSm,
                  color: AppColors.warning.withValues(alpha: AppColors.opacitySecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
