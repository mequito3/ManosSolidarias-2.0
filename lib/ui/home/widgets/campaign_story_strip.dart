import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/campaign.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_network_image.dart';

/// Strip horizontal estilo Instagram Stories: cada campaña aparece como una
/// burbuja circular con foto, anillo de progreso y título debajo.
/// Diseñado para "Recién lanzadas" — invita al descubrimiento visual rápido.
class CampaignStoryStrip extends StatelessWidget {
  const CampaignStoryStrip({
    super.key,
    required this.campaigns,
    required this.onOpenCampaign,
  });

  final List<CampaignSummary> campaigns;
  final ValueChanged<CampaignSummary> onOpenCampaign;

  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        physics: const BouncingScrollPhysics(),
        itemCount: campaigns.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return _StoryItem(
            campaign: campaign,
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenCampaign(campaign);
            },
          );
        },
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({required this.campaign, required this.onTap});

  final CampaignSummary campaign;
  final VoidCallback onTap;

  Color _ringColor() {
    final pct = campaign.completionPercentage;
    if (pct >= 80) return AppColors.greenSuccess;
    if (pct >= 40) return AppColors.bluePrimary;
    return AppColors.orangeAction;
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _ringColor();
    final isNew = campaign.isNew;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar con anillo de progreso
            Stack(
              alignment: Alignment.center,
              children: [
                // Anillo gradient (efecto "story")
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ringColor,
                        ringColor.withValues(alpha: 0.5),
                        AppColors.orangeAction.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                // Anillo blanco interno (para que la foto destaque)
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                // Foto circular
                ClipOval(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: campaign.coverUrl.isEmpty
                        ? Container(
                            color: AppColors.bluePrimary
                                .withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.volunteer_activism_rounded,
                              color: AppColors.bluePrimary,
                              size: 26,
                            ),
                          )
                        : AppNetworkImage(
                            url: campaign.coverUrl,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color:
                                  AppColors.error.withValues(alpha: 0.08),
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                            ),
                          ),
                  ),
                ),
                // Badge "Nueva" si aplica
                if (isNew)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.greenSuccess,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Text(
                        '✦',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Título debajo (2 líneas máx)
            Text(
              campaign.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText.withValues(alpha: 0.78),
                height: 1.25,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
