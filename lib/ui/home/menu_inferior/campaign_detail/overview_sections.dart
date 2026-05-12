part of 'campaign_detail_page.dart';

class _OrganizerSection extends StatelessWidget {
  const _OrganizerSection({
    required this.detail,
    required this.hasOrganizerBio,
    required this.hasOrganizerAvatar,
    required this.hasLocation,
    required this.onOpenLink,
  });

  final CampaignDetail detail;
  final bool hasOrganizerBio;
  final bool hasOrganizerAvatar;
  final bool hasLocation;
  final Future<bool> Function(String url) onOpenLink;

  @override
  Widget build(BuildContext context) {
    final organizerName = detail.summary.organizerName ?? 'Equipo organizador';
    final location = detail.location?.trim();

    return _SectionCard(
      title: 'Quién está detrás',
      icon: Icons.people_alt_rounded,
      iconColor: AppColors.blueSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bluePrimary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.bluePrimary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.15),
                  backgroundImage: hasOrganizerAvatar ? NetworkImage(detail.organizerAvatarUrl!) : null,
                  child: hasOrganizerAvatar
                      ? null
                      : Text(
                          organizerName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.bluePrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organizerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                    ),
                    if (hasOrganizerBio) ...[
                      const SizedBox(height: 6),
                      Text(
                        detail.organizerBio!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.darkText.withValues(alpha: 0.75),
                              height: 1.4,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasLocation && location != null && location.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(AppColors.space16),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                border: Border.all(
                  color: AppColors.bluePrimary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppColors.space8),
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.bluePrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppColors.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.darkText.withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: AppColors.space12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppColors.radiusSm),
                            boxShadow: AppColors.shadowSm,
                          ),
                          child: TextButton.icon(
                            onPressed: () {
                              final mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}';
                              unawaited(onOpenLink(mapUrl));
                            },
                            icon: const Icon(Icons.map_rounded, size: 18),
                            label: const Text(
                              'Abrir en mapa',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppColors.space16,
                                vertical: AppColors.space8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardsSection extends StatelessWidget {
  const _RewardsSection({required this.rewards});

  final List<CampaignReward> rewards;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recompensas',
      icon: Icons.card_giftcard_rounded,
      iconColor: AppColors.orangeAction,
      child: Column(
        children: rewards
            .map(
              (reward) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _RewardTile(reward: reward),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.reward});

  final CampaignReward reward;

  @override
  Widget build(BuildContext context) {
    final isLowStock = reward.isLimited && 
        reward.availableQuantity != null && 
        reward.availableQuantity! <= 5;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.greenSoft.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: isLowStock 
            ? Border.all(
                color: AppColors.orangeAction.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono y badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.greenHope.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 16,
                  color: AppColors.greenHope,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                    ),
                    if (isLowStock) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orangeAction,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIMITADA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Precio destacado con badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bluePrimary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _formatCurrency(reward.minimumDonation),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reward.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.75),
                  height: 1.4,
                ),
          ),
          if (reward.deliverBy != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.darkText.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Entrega estimada: ${_formatDate(reward.deliverBy!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ],
          if (reward.isLimited && reward.availableQuantity != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: isLowStock 
                      ? AppColors.orangeAction 
                      : AppColors.darkText.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Disponibles: ${reward.availableQuantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLowStock 
                            ? AppColors.orangeAction 
                            : AppColors.darkText.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UpdatesSection extends StatelessWidget {
  const _UpdatesSection({required this.updates});

  final List<CampaignUpdate> updates;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Actualizaciones',
      icon: Icons.campaign_rounded,
      iconColor: AppColors.bluePrimary,
      child: Column(
        children: updates
            .map(
              (update) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _UpdateTile(update: update),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _UpdateTile extends StatelessWidget {
  const _UpdateTile({required this.update});

  final CampaignUpdate update;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, color: AppColors.bluePrimary),
              const SizedBox(width: 8),
              Text(
                _formatDate(update.publishedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.bluePrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            update.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            update.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.75),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _VideoSection extends StatelessWidget {
  const _VideoSection({required this.videoUrl, required this.onOpenLink});

  final String videoUrl;
  final Future<bool> Function(String url) onOpenLink;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Video de la campaña',
      icon: Icons.play_circle_rounded,
      iconColor: AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conoce la historia directamente desde el equipo organizador. Abre el video en tu navegador para verlo en pantalla completa.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.75),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onOpenLink(videoUrl),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Ver video'),
          ),
        ],
      ),
    );
  }
}
