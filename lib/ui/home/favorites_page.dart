import 'package:flutter/material.dart';

import '../../controllers/campaign_controller.dart';
import '../../models/campaign.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/premium_empty_state.dart';
import '../widgets/premium_hero.dart';
import 'widgets/campaign_card.dart';

class FavoriteCampaignsPage extends StatelessWidget {
  const FavoriteCampaignsPage({
    super.key,
    required this.controller,
    required this.onOpenCampaign,
    required this.onToggleFavorite,
    required this.onSupport,
  });

  final CampaignController controller;
  final ValueChanged<CampaignSummary> onOpenCampaign;
  final Future<void> Function(BuildContext context, CampaignSummary campaign)
      onToggleFavorite;
  final ValueChanged<CampaignSummary> onSupport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: const PremiumAppBar(title: 'Mis favoritos'),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final favorites = controller.favoriteCampaigns;

          if (controller.isLoading && favorites.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.bluePrimary),
            );
          }

          if (favorites.isEmpty) {
            return PremiumEmptyState(
              icon: Icons.favorite_border_rounded,
              iconColor: AppColors.orangeAction,
              title: 'Aún no tienes favoritos',
              description:
                  'Toca el corazón en las campañas que quieras seguir y volverán acá para que las revises cuando quieras.',
              blobColors: [
                AppColors.orangeAction.withValues(alpha: 0.10),
                AppColors.bluePrimary.withValues(alpha: 0.08),
              ],
              hintChips: const [
                PremiumHintChip(
                  icon: Icons.touch_app_rounded,
                  label: 'Toca el corazón',
                  color: AppColors.bluePrimary,
                ),
                PremiumHintChip(
                  icon: Icons.bookmark_added_rounded,
                  label: 'Las guardamos',
                  color: AppColors.bluePrimary,
                ),
              ],
              action: AppPrimaryButton(
                label: 'Explorar campañas',
                icon: Icons.explore_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppColors.space20,
                  AppColors.space12,
                  AppColors.space20,
                  AppColors.space16,
                ),
                sliver: SliverToBoxAdapter(
                  child: PremiumHero(
                    icon: Icons.favorite_rounded,
                    iconGradient: AppColors.actionGradient,
                    iconShadowColor: AppColors.orangeAction,
                    title: favorites.length == 1
                        ? '1 causa guardada'
                        : '${favorites.length} causas guardadas',
                    subtitle: 'Volvé cuando quieras apoyar.',
                    backgroundColors: [
                      AppColors.orangeAction.withValues(alpha: 0.10),
                      AppColors.bluePrimary.withValues(alpha: 0.06),
                    ],
                    blobColors: [
                      AppColors.orangeAction.withValues(alpha: 0.14),
                      AppColors.bluePrimary.withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppColors.space20,
                  0,
                  AppColors.space20,
                  AppColors.space12,
                ),
                sliver: SliverToBoxAdapter(
                  child: PremiumSectionHeader(
                    title: 'Tus causas guardadas',
                    accentGradient: AppColors.actionGradient,
                    count: favorites.length,
                    countColor: AppColors.orangeAction,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppColors.space20,
                  AppColors.space4,
                  AppColors.space20,
                  AppColors.space32,
                ),
                sliver: SliverList.separated(
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppColors.space16),
                  itemBuilder: (context, index) {
                    final campaign = favorites[index];
                    return CampaignCard(
                      campaign: campaign,
                      onTap: () => onOpenCampaign(campaign),
                      onSupport: () => onSupport(campaign),
                      onToggleFavorite: () {
                        onToggleFavorite(context, campaign);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
