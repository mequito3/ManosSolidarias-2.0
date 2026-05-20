import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Hint chip pequeño (icono + texto) usado en empty states premium.
class PremiumHintChip extends StatelessWidget {
  const PremiumHintChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.space12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppColors.fontSizeXs,
              fontWeight: AppColors.fontWeightBold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state premium reutilizable: tarjeta blanca con blobs decorativos,
/// icono en capas (círculo de gradiente + círculo blanco con sombra +
/// icono coloreado), título, descripción, hint chips y acción opcional.
class PremiumEmptyState extends StatelessWidget {
  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.blobColors,
    this.hintChips,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  /// Dos colores para los blobs (esquina sup-der y inf-izq), bien diluidos.
  final List<Color> blobColors;

  /// Chips de pista debajo de la descripción (típicamente 2).
  final List<PremiumHintChip>? hintChips;

  /// Botón principal de acción (típicamente un AppPrimaryButton).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.space24),
        physics: const BouncingScrollPhysics(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.radiusXl),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  boxShadow: AppColors.shadowMd,
                ),
              ),
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: blobColors[0],
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: blobColors.length > 1 ? blobColors[1] : blobColors[0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppColors.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                iconColor.withValues(alpha: 0.18),
                                iconColor.withValues(alpha: 0.06),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: iconColor.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 40, color: iconColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppColors.space20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: AppColors.fontSizeXl,
                        fontWeight: AppColors.fontWeightExtraBold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppColors.space8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.mediumText,
                        fontSize: AppColors.fontSizeBase,
                        height: 1.45,
                      ),
                    ),
                    if (hintChips != null && hintChips!.isNotEmpty) ...[
                      const SizedBox(height: AppColors.space20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppColors.space8,
                        runSpacing: AppColors.space8,
                        children: hintChips!,
                      ),
                    ],
                    if (action != null) ...[
                      const SizedBox(height: AppColors.space24),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
