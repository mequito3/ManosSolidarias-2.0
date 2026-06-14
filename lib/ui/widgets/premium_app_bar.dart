import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// AppBar estándar de la app: fondo claro, sin elevación, flecha de volver
/// y título en darkText. Reemplaza al `AppBar` directo en pantallas
/// secundarias para mantener consistencia visual.
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final List<Widget>? actions;

  /// Callback al tocar la flecha de volver. Si es null, hace `Navigator.pop()`.
  final VoidCallback? onBack;

  /// Si es false oculta la flecha de volver (útil para pantallas root).
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.lightBackground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.darkText,
      iconTheme: const IconThemeData(color: AppColors.darkText),
      leading: showBack
          ? IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.darkText,
            fontWeight: AppColors.fontWeightBold,
            letterSpacing: -0.3,
          ),
        ),
      ),
      actions: actions == null
          ? null
          : [
              ...actions!,
              const SizedBox(width: AppColors.space4),
            ],
    );
  }
}

/// Botón de acción para usar dentro del `actions:` del [PremiumAppBar].
/// Mantiene tamaño y color consistentes (azul de marca).
class PremiumAppBarAction extends StatelessWidget {
  const PremiumAppBarAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 22),
      color: AppColors.bluePrimary,
      onPressed: onPressed,
    );
  }
}
