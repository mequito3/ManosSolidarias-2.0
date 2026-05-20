import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Tarjeta hero reutilizable con fondo en gradiente pastel, dos blobs
/// decorativos, icono cuadrado con gradiente, título y subtítulo. Acepta
/// opcionalmente una fila de stats debajo (ej. [PremiumStatPill]).
class PremiumHero extends StatelessWidget {
  const PremiumHero({
    super.key,
    required this.icon,
    required this.iconGradient,
    required this.iconShadowColor,
    required this.title,
    required this.subtitle,
    required this.backgroundColors,
    required this.blobColors,
    this.stats,
  });

  /// Icono dentro del cuadro con gradiente.
  final IconData icon;

  /// Gradiente del cuadro del icono (ej. [AppColors.primaryGradient]).
  final Gradient iconGradient;

  /// Color base para la sombra del cuadro del icono.
  final Color iconShadowColor;

  final String title;
  final String subtitle;

  /// Dos colores que componen el gradiente diagonal del fondo
  /// (van diluidos con alpha bajo para mantener el look suave).
  final List<Color> backgroundColors;

  /// Dos colores para los blobs decorativos (esquina sup-der y inf-izq).
  final List<Color> blobColors;

  /// Pills opcionales debajo del título (típicamente 2-3).
  final List<Widget>? stats;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusXl),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: backgroundColors,
              ),
            ),
          ),
          Positioned(
            top: -28,
            right: -22,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColors[0],
              ),
            ),
          ),
          Positioned(
            bottom: -32,
            left: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColors.length > 1 ? blobColors[1] : blobColors[0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppColors.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppColors.space12),
                      decoration: BoxDecoration(
                        gradient: iconGradient,
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: iconShadowColor.withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppColors.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontSize: AppColors.fontSizeXl,
                              fontWeight: AppColors.fontWeightExtraBold,
                              letterSpacing: -0.4,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.mediumText,
                              fontSize: AppColors.fontSizeSm,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (stats != null && stats!.isNotEmpty) ...[
                  const SizedBox(height: AppColors.space20),
                  Row(
                    children: [
                      for (int i = 0; i < stats!.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppColors.space8),
                        Expanded(child: stats![i]),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill con icono, valor grande y label pequeño. Pensada para vivir dentro
/// de la fila `stats` de [PremiumHero].
class PremiumStatPill extends StatelessWidget {
  const PremiumStatPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space12,
        vertical: AppColors.space12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: AppColors.space8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: AppColors.fontSizeLg,
              fontWeight: AppColors.fontWeightExtraBold,
              letterSpacing: -0.3,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.darkText.withValues(alpha: 0.65),
              fontSize: AppColors.fontSizeXs,
              fontWeight: AppColors.fontWeightSemiBold,
              letterSpacing: 0.2,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Header de sección (barra vertical con gradiente, título, contador opcional).
class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
    super.key,
    required this.title,
    required this.accentGradient,
    this.count,
    this.countColor = AppColors.bluePrimary,
  });

  final String title;
  final Gradient accentGradient;
  final int? count;
  final Color countColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: accentGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusXs),
          ),
        ),
        const SizedBox(width: AppColors.space12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: AppColors.fontSizeMd,
              fontWeight: AppColors.fontWeightExtraBold,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppColors.space12, vertical: 4),
            decoration: BoxDecoration(
              color: countColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: countColor,
                fontSize: AppColors.fontSizeSm,
                fontWeight: AppColors.fontWeightExtraBold,
                letterSpacing: 0.3,
              ),
            ),
          ),
      ],
    );
  }
}
