import 'package:flutter/material.dart';

import '../../controllers/campaign_controller.dart';
import '../../models/campaign.dart';
import '../../theme/app_colors.dart';
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
  final Future<void> Function(BuildContext context, CampaignSummary campaign) onToggleFavorite;
  final ValueChanged<CampaignSummary> onSupport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritos')),
      backgroundColor: AppColors.lightBackground,
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final favorites = controller.favoriteCampaigns;

          if (controller.isLoading && favorites.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favorites.isEmpty) {
            return _EmptyFavorites(onExplore: () => Navigator.of(context).pop());
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
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
          );
        },
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 64, color: AppColors.orangeAction),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes campañas guardadas.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el corazón en las campañas que quieras seguir de cerca y volverán a aparecer aquí.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.7),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onExplore,
            child: const Text('Explorar campañas'),
          ),
        ],
      ),
    );
  }
}
