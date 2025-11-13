import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    // MEJORA: Botón primary con gradiente y sombra profesional
    final isDisabled = onPressed == null;

    final ButtonStyle style = FilledButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.transparent,
      disabledForegroundColor: Colors.white.withValues(alpha: AppColors.opacityDisabled),
      padding: const EdgeInsets.symmetric(
        vertical: AppColors.space16,
        horizontal: AppColors.space24,
      ),
      textStyle: const TextStyle(
        fontWeight: AppColors.fontWeightBold,
        fontSize: AppColors.fontSizeMd,
        letterSpacing: AppColors.letterSpacingWide,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
      ),
      elevation: 0,
    );

    final Widget buttonContent = icon != null
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: AppColors.iconSizeMd),
            label: Text(label),
            style: style,
          )
        : FilledButton(
            onPressed: onPressed,
            style: style,
            child: Text(label),
          );

    final Widget styledButton = Container(
      decoration: BoxDecoration(
        gradient: isDisabled
            ? LinearGradient(
                colors: [
                  AppColors.grayNeutral.withValues(alpha: AppColors.opacityDisabled),
                  AppColors.grayNeutral.withValues(alpha: AppColors.opacitySecondary),
                ],
              )
            : AppColors.actionGradient,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.orangeAction.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: buttonContent,
    );

    if (!expanded) {
      return styledButton;
    }
    return SizedBox(width: double.infinity, child: styledButton);
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expanded = true,
    this.icon,
    this.iconWidget,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final IconData? icon;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    // MEJORA: Botón secondary con mejor diseño
    final isDisabled = onPressed == null;

    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.bluePrimary,
      disabledForegroundColor: AppColors.grayNeutral,
      side: BorderSide(
        color: isDisabled
            ? AppColors.grayNeutral.withValues(alpha: AppColors.opacityDisabled)
            : AppColors.bluePrimary,
        width: 2,
      ),
      backgroundColor: isDisabled
          ? Colors.transparent
          : AppColors.bluePrimary.withValues(alpha: AppColors.opacityOverlay),
      padding: const EdgeInsets.symmetric(
        vertical: AppColors.space16,
        horizontal: AppColors.space24,
      ),
      textStyle: const TextStyle(
        fontWeight: AppColors.fontWeightSemiBold,
        fontSize: AppColors.fontSizeMd,
        letterSpacing: AppColors.letterSpacingWide,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
      ),
    );

    final hasIcon = icon != null || iconWidget != null;

    final button = hasIcon
        ? OutlinedButton.icon(
            onPressed: onPressed,
            style: buttonStyle,
            icon: iconWidget ?? Icon(icon, size: AppColors.iconSizeMd),
            label: Text(label),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: Text(label),
          );

    // MEJORA: Añadir sombra sutil cuando está enabled
    final styledButton = isDisabled
        ? button
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              boxShadow: AppColors.shadowSm, // MEJORA: Sombra sutil
            ),
            child: button,
          );

    if (!expanded) {
      return styledButton;
    }
    return SizedBox(width: double.infinity, child: styledButton);
  }
}
