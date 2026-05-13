import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../../models/campaign.dart';
import '../../../theme/app_colors.dart';

/// Card premium para campañas "Cerca de la meta".
/// Diseño: foto grande izquierda + título arriba + porcentaje gigante +
/// barra de progreso animada + "Faltan Bs X" prominente.
///
/// Vibra urgencia y momentum sin gritar.
class CampaignNearGoalCard extends StatelessWidget {
  const CampaignNearGoalCard({
    super.key,
    required this.campaign,
    required this.onTap,
  });

  final CampaignSummary campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = campaign.completionPercentage;
    final pctColor = pct >= 90
        ? AppColors.greenSuccess
        : (pct >= 70 ? AppColors.bluePrimary : AppColors.orangeAction);
    final remaining = (campaign.goalAmount - campaign.raisedAmount).clamp(
      0.0,
      double.infinity,
    );
    final isAlmostThere = pct >= 90;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAlmostThere
                  ? AppColors.greenSuccess.withValues(alpha: 0.25)
                  : AppColors.dividerColor.withValues(alpha: 0.7),
              width: isAlmostThere ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isAlmostThere
                    ? AppColors.greenSuccess.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── FOTO 96x96 ─────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: campaign.coverUrl.isEmpty
                      ? Container(
                          color: pctColor.withValues(alpha: 0.08),
                          child: Icon(
                            Icons.volunteer_activism_rounded,
                            color: pctColor,
                            size: 32,
                          ),
                        )
                      : Image.network(
                          campaign.coverUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Shimmer.fromColors(
                              baseColor: AppColors.bluePrimary
                                  .withValues(alpha: 0.06),
                              highlightColor: AppColors.bluePrimary
                                  .withValues(alpha: 0.14),
                              child: Container(color: Colors.white),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.error.withValues(alpha: 0.08),
                            child: const Icon(
                              Icons.broken_image_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // ── INFO derecha ────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Categoría (sutil)
                    if (campaign.category.isNotEmpty)
                      Text(
                        campaign.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: pctColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    const SizedBox(height: 3),

                    // Título 2 líneas
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.darkText,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Barra de progreso + porcentaje al final
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0.0,
                                end: campaign.normalizedProgress,
                              ),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  color: pctColor,
                                  backgroundColor:
                                      pctColor.withValues(alpha: 0.12),
                                  minHeight: 7,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: pctColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // "Faltan Bs X" prominente — wrap natural sin truncar
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.darkText.withValues(alpha: 0.6),
                        ),
                        children: [
                          const TextSpan(text: 'Faltan '),
                          TextSpan(
                            text: _formatBs(remaining),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: pctColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const TextSpan(text: ' para la meta'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Stats discretos (wrap natural si no caben)
                    Text(
                      '${campaign.donorCount} donantes  ·  Bs ${_thousandSep(campaign.raisedAmount.round())} recaudados',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.darkText.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _thousandSep(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatBs(double v) {
    if (v >= 1000000) return 'Bs ${(v / 1000000).toStringAsFixed(1)}M';
    return 'Bs ${_thousandSep(v.round())}';
  }
}
