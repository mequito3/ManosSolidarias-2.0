import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../../models/campaign.dart';
import '../../../theme/app_colors.dart';

/// Banner de campaña patrocinada. Empresa con RSE corporativa "impulsa" una
/// causa: paga visibilidad y la campaña recibe más donaciones.
/// Modelo monetización ético defendible en tesis.
class PromotedCampaignBanner extends StatelessWidget {
  const PromotedCampaignBanner({
    super.key,
    required this.campaign,
    required this.sponsorName,
    required this.sponsorColor,
    required this.onTap,
  });

  final CampaignSummary campaign;
  final String sponsorName;
  final Color sponsorColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = campaign.completionPercentage;
    final pctColor = pct >= 90
        ? AppColors.greenSuccess
        : (pct >= 70 ? AppColors.bluePrimary : AppColors.orangeAction);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: sponsorColor.withValues(alpha: 0.32),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: sponsorColor.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header "IMPULSADO POR X" ─────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      sponsorColor.withValues(alpha: 0.13),
                      sponsorColor.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(19),
                    topRight: Radius.circular(19),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: sponsorColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.darkText.withValues(alpha: 0.65),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            const TextSpan(text: 'IMPULSADO POR  '),
                            TextSpan(
                              text: sponsorName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: sponsorColor,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: sponsorColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'RSE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: sponsorColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Body — foto + info ───────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: campaign.coverUrl.isEmpty
                            ? Container(
                                color: pctColor.withValues(alpha: 0.08),
                                child: Icon(
                                  Icons.volunteer_activism_rounded,
                                  color: pctColor,
                                  size: 30,
                                ),
                              )
                            : Image.network(
                                campaign.coverUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Shimmer.fromColors(
                                    baseColor: sponsorColor
                                        .withValues(alpha: 0.06),
                                    highlightColor: sponsorColor
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          Text(
                            campaign.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.darkText,
                              height: 1.3,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                    duration:
                                        const Duration(milliseconds: 1000),
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
                                  fontSize: 15,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${campaign.donorCount} donantes apoyan esta causa',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.darkText.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
}
