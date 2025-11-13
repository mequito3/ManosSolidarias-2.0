import 'package:flutter/material.dart';

import '../../../controllers/campaign_controller.dart';
import '../../../controllers/donor_trophy_controller.dart';
import '../../../models/campaign.dart';
import '../../../models/donor_trophy_entry.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../widgets/campaign_card.dart';
import '../widgets/home_section.dart';
import 'shared_states.dart';

class CampaignTabView extends StatelessWidget {
  const CampaignTabView({
    super.key,
    required this.controller,
    required this.profile,
    required this.sortOption,
    required this.onSortSelected,
    required this.onRefresh,
    required this.onToggleFavorite,
    required this.onOpenCampaign,
    required this.onSupportCampaign,
    required this.onCompleteProfile,
    this.donorTrophyController,
    this.onViewLeaderboard,
    this.categoryFilter,
    this.onClearCategoryFilter,
  });

  final CampaignController controller;
  final UserProfile profile;
  final CampaignSortOption sortOption;
  final ValueChanged<CampaignSortOption> onSortSelected;
  final RetryCallback onRefresh;
  final Future<void> Function(CampaignSummary campaign) onToggleFavorite;
  final ValueChanged<CampaignSummary> onOpenCampaign;
  final ValueChanged<CampaignSummary> onSupportCampaign;
  final RetryCallback onCompleteProfile;
  final DonorTrophyController? donorTrophyController;
  final VoidCallback? onViewLeaderboard;
  final String? categoryFilter;
  final VoidCallback? onClearCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final isLoading = controller.isLoading;
    final error = controller.errorMessage;
    var campaigns = controller.campaigns;
    
    // Aplicar filtro de categoría si está activo
    if (categoryFilter != null && categoryFilter!.isNotEmpty) {
      campaigns = campaigns.where((c) => c.category == categoryFilter).toList();
    }
    
    final featured = List<CampaignSummary>.from(
      categoryFilter != null 
        ? controller.featuredCampaigns.where((c) => c.category == categoryFilter).toList()
        : controller.featuredCampaigns
    );
    final nearGoal = List<CampaignSummary>.from(
      categoryFilter != null 
        ? controller.nearGoalCampaigns.where((c) => c.category == categoryFilter).toList()
        : controller.nearGoalCampaigns
    );
    final recent = (categoryFilter != null 
        ? controller.recentCampaigns.where((c) => c.category == categoryFilter).toList()
        : controller.recentCampaigns
    ).take(2).toList();

  const double featuredCarouselHeight = 480;

    if (isLoading && campaigns.isEmpty) {
      return const HomeTabLoadingState();
    }

    if (error != null && campaigns.isEmpty) {
      return HomeTabErrorState(
        message: error,
        onRetry: onRefresh,
      );
    }

    if (campaigns.isEmpty) {
      // Si hay filtro activo y no hay resultados
      if (categoryFilter != null) {
        return _buildNoResultsForCategory(context);
      }
      return CampaignEmptyState(sortOption: sortOption);
    }

    final sorted = _applySort(campaigns, sortOption);
    final visibleCampaigns = sorted.take(20).toList();
    final profileComplete = profile.meetsCompletionCriteria;

    return RefreshIndicator(
      color: AppColors.bluePrimary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          if (!profileComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ProfileIncompleteBanner(onCompleteProfile: onCompleteProfile),
            ),
          // Chip de filtro activo
          if (categoryFilter != null && categoryFilter!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CategoryFilterChip(
                category: categoryFilter!,
                onClear: onClearCategoryFilter,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SortToggleBar(
              selectedOption: sortOption,
              onSelected: onSortSelected,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 8),
            child: _ResultCounter(
              count: sorted.length,
              sortOption: sortOption,
            ),
          ),
          if (donorTrophyController != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _DonorLeaderboardPreview(
                controller: donorTrophyController!,
                onViewLeaderboard: onViewLeaderboard,
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HomeTabInlineError(message: error, onRetry: onRefresh),
            ),
          if (featured.isNotEmpty)
            HomeSection(
              title: 'Campañas destacadas',
              subtitle: 'Proyectos verificados con alto impacto comunitario.',
              child: SizedBox(
                height: featuredCarouselHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: featured.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final campaign = featured[index];
                    return SizedBox(
                      width: 320,
                      child: CampaignCard(
                        campaign: campaign,
                        onTap: () => onOpenCampaign(campaign),
                        onSupport: () => onSupportCampaign(campaign),
                        onToggleFavorite: () => onToggleFavorite(campaign),
                        showSupportButton: false,
                      ),
                    );
                  },
                ),
              ),
            ),
          if (nearGoal.isNotEmpty)
            HomeSection(
              title: 'Cerca de la meta',
              subtitle: 'Estas campañas están a punto de alcanzar su objetivo.',
              child: Column(
                children: nearGoal
                    .take(4)
                    .map(
                      (campaign) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CampaignProgressTile(
                          campaign: campaign,
                          onTap: () => onOpenCampaign(campaign),
                          onSupport: () => onSupportCampaign(campaign),
                          onToggleFavorite: () => onToggleFavorite(campaign),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (recent.isNotEmpty)
            HomeSection(
              title: 'Recién lanzadas',
              subtitle: 'Ideas frescas que necesitan sus primeros aliados.',
              child: Column(
                children: recent
                    .map(
                      (campaign) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CampaignHeadlineTile(
                          campaign: campaign,
                          onTap: () => onOpenCampaign(campaign),
                          onToggleFavorite: () => onToggleFavorite(campaign),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (visibleCampaigns.isNotEmpty)
            HomeSection(
              title: 'Todas las campañas',
              subtitle: 'Explora la base completa de iniciativas activas.',
              child: Column(
                children: visibleCampaigns
                    .map(
                      (campaign) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: CampaignCard(
                          campaign: campaign,
                          onTap: () => onOpenCampaign(campaign),
                          onSupport: () => onSupportCampaign(campaign),
                          onToggleFavorite: () => onToggleFavorite(campaign),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (visibleCampaigns.isNotEmpty && campaigns.length > visibleCampaigns.length)
            Center(
              child: Text(
                'Mostrando ${visibleCampaigns.length} de ${campaigns.length} campañas. Usa la búsqueda para encontrar más.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.6),
                    ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNoResultsForCategory(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.mediumText.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay campañas en esta categoría',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Intenta con otra categoría o explora todas las campañas disponibles.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumText,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onClearCategoryFilter != null)
              ElevatedButton.icon(
                onPressed: onClearCategoryFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.clear_all, size: 20),
                label: const Text('Ver todas las campañas'),
              ),
          ],
        ),
      ),
    );
  }

  List<CampaignSummary> _applySort(List<CampaignSummary> campaigns, CampaignSortOption option) {
    final sorted = List<CampaignSummary>.from(campaigns);
    
    switch (option) {
      case CampaignSortOption.recommended:
        // Algoritmo de recomendación inteligente: combina múltiples factores
        sorted.sort((a, b) {
          // Calcular score de recomendación para cada campaña
          final scoreA = _calculateRecommendationScore(a);
          final scoreB = _calculateRecommendationScore(b);
          return scoreB.compareTo(scoreA); // Mayor score primero
        });
        break;
        
      case CampaignSortOption.newest:
        // Ordenar por fecha de inicio (más reciente primero)
        sorted.sort((a, b) {
          final aDate = a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        break;
        
      case CampaignSortOption.funding:
        // Ordenar por porcentaje de avance (mayor primero)
        sorted.sort((a, b) => b.completionPercentage.compareTo(a.completionPercentage));
        break;
        
      case CampaignSortOption.donors:
        // Ordenar por cantidad de donadores (más primero)
        sorted.sort((a, b) => b.donorCount.compareTo(a.donorCount));
        break;
    }
    return sorted;
  }

  /// Calcula un score de recomendación basado en múltiples factores
  double _calculateRecommendationScore(CampaignSummary campaign) {
    double score = 0.0;
    
    // Factor 1: Actividad reciente (campañas nuevas son más relevantes)
    if (campaign.startDate != null) {
      final daysOld = DateTime.now().difference(campaign.startDate!).inDays;
      if (daysOld <= 7) {
        score += 30.0; // Muy reciente
      } else if (daysOld <= 30) {
        score += 15.0; // Reciente
      } else if (daysOld <= 90) {
        score += 5.0; // Moderadamente reciente
      }
    }
    
    // Factor 2: Progreso de financiamiento (sweet spot: 20-80%)
    final progress = campaign.completionPercentage;
    if (progress >= 20 && progress <= 80) {
      score += 25.0; // En progreso activo
    } else if (progress < 20) {
      score += 15.0; // Necesita impulso inicial
    } else if (progress > 80 && progress < 100) {
      score += 20.0; // Casi completa, empujón final
    }
    
    // Factor 3: Engagement de donadores (más donadores = más confianza)
    if (campaign.donorCount > 50) {
      score += 20.0; // Alta participación
    } else if (campaign.donorCount > 20) {
      score += 15.0; // Buena participación
    } else if (campaign.donorCount > 5) {
      score += 10.0; // Participación moderada
    }
    
    // Factor 4: Magnitud del proyecto (proyectos medianos son más alcanzables)
    final goalAmount = campaign.goalAmount;
    if (goalAmount >= 5000 && goalAmount <= 50000) {
      score += 10.0; // Meta alcanzable y significativa
    } else if (goalAmount > 50000 && goalAmount <= 200000) {
      score += 5.0; // Meta grande pero viable
    }
    
    // Factor 5: Favoritos del usuario (si está en favoritos, máxima prioridad)
    if (campaign.isFavorite) {
      score += 50.0; // Boost significativo para favoritos
    }
    
    return score;
  }
}

class _DonorLeaderboardPreview extends StatelessWidget {
  const _DonorLeaderboardPreview({
    required this.controller,
    this.onViewLeaderboard,
  });

  final DonorTrophyController controller;
  final VoidCallback? onViewLeaderboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading && controller.entries.isEmpty) {
          return _LeaderboardContainer(
            child: Row(
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Cargando ranking solidario…',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.errorMessage != null && controller.entries.isEmpty) {
          return _LeaderboardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No pudimos cargar el ranking',
                  style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.7),
                      ),
                ),
                TextButton.icon(
                  onPressed: controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final topEntries = controller.topThree;
        if (topEntries.isEmpty) {
          return _LeaderboardContainer(
            child: Column(
              children: [
                // Podio vacío ilustrado
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.orangeAction.withValues(alpha: 0.08),
                        AppColors.bluePrimary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.orangeAction.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Trofeo grande
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.orangeAction.withValues(alpha: 0.2),
                              AppColors.orangeAction.withValues(alpha: 0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.orangeAction,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¡Podio disponible!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sé el primero en donar y tu nombre aparecerá en el ranking solidario',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Mini podio ilustrativo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _EmptyPodiumBar(
                            height: 35,
                            label: '2°',
                            color: AppColors.bluePrimary,
                          ),
                          const SizedBox(width: 8),
                          _EmptyPodiumBar(
                            height: 50,
                            label: '1°',
                            color: AppColors.orangeAction,
                          ),
                          const SizedBox(width: 8),
                          _EmptyPodiumBar(
                            height: 25,
                            label: '3°',
                            color: AppColors.greenSuccess,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onViewLeaderboard != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onViewLeaderboard,
                    icon: const Icon(Icons.leaderboard_rounded, size: 18),
                    label: const Text('Ver ranking completo'),
                  ),
                ],
              ],
            ),
          );
        }

        final profile = controller.profile;

        return _LeaderboardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mejorado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.orangeAction.withValues(alpha: 0.15),
                          AppColors.orangeAction.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.orangeAction,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ranking Solidario',
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkText,
                              ),
                        ),
                        Text(
                          'Los más generosos del mes',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.darkText.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (onViewLeaderboard != null)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.bluePrimary.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onViewLeaderboard,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Ver todo',
                                  style: TextStyle(
                                    color: AppColors.bluePrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.bluePrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Podio horizontal simple
              Row(
                children: [
                  // Segundo lugar (izquierda)
                  if (topEntries.length > 1)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _LeaderboardPreviewTile(entry: topEntries[1]),
                      ),
                    ),
                  // Primer lugar (centro)
                  if (topEntries.isNotEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _LeaderboardPreviewTile(entry: topEntries[0]),
                      ),
                    ),
                  // Tercer lugar (derecha)
                  if (topEntries.length > 2)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: _LeaderboardPreviewTile(entry: topEntries[2]),
                      ),
                    ),
                ],
              ),
              
              // Posición del usuario
              if (profile != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        profile.hasRanking
                            ? AppColors.bluePrimary.withValues(alpha: 0.08)
                            : AppColors.grayNeutral.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: profile.hasRanking
                          ? AppColors.bluePrimary.withValues(alpha: 0.2)
                          : AppColors.grayNeutral.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar del usuario
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.bluePrimary,
                              AppColors.blueSecondary,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.bluePrimary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu posición',
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.darkText.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.hasRanking
                                  ? '#${profile.position} · ${profile.level.label}'
                                  : 'Aún sin ranking',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Monto del usuario
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                          Text(
                            profile.hasRanking ? 'Total donado' : 'Primera donación',
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.darkText.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.orangeAction,
                                  AppColors.orangeActionLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orangeAction.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              profile.hasRanking
                                  ? _formatPreviewAmount(profile.totalDonated)
                                  : '🎁 Desbloquea',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
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
      },
    );
  }

  String _formatPreviewAmount(double value) {
    if (value >= 1000) {
      return 'Bs. ${value.toStringAsFixed(0)}';
    }
    return 'Bs. ${value.toStringAsFixed(1)}';
  }
}

class _LeaderboardPreviewTile extends StatelessWidget {
  const _LeaderboardPreviewTile({required this.entry});

  final DonorTrophyEntry entry;

  @override
  Widget build(BuildContext context) {
    final podiumData = _getPodiumData(entry.position);
    final Color color = podiumData['color'];
    final double avatarSize = podiumData['avatarSize'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge de posición arriba
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: podiumData['gradientColors'] as List<Color>,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: entry.position == 1
                  ? const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : Text(
                      '${entry.position}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Avatar
          CircleAvatar(
            radius: avatarSize,
            backgroundColor: color.withValues(alpha: 0.15),
            backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Icon(
                    Icons.person_rounded,
                    size: avatarSize * 1.2,
                    color: color,
                  )
                : null,
          ),
          
          const SizedBox(height: 8),
          
          // Nombre (puede ocupar 2 líneas si es necesario)
          Text(
            entry.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
              fontSize: 11,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Monto destacado
          Text(
            _formatContribution(entry.totalDonated),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 3),
          
          // Nivel pequeño
          Text(
            entry.level.label,
            style: TextStyle(
              color: AppColors.darkText.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPodiumData(int position) {
    switch (position) {
      case 1:
        return {
          'color': AppColors.orangeAction,
          'gradientColors': [AppColors.orangeAction, AppColors.orangeActionLight],
          'avatarSize': 28.0,
        };
      case 2:
        return {
          'color': AppColors.bluePrimary,
          'gradientColors': [AppColors.bluePrimary, AppColors.blueSecondary],
          'avatarSize': 26.0,
        };
      case 3:
        return {
          'color': AppColors.greenSuccess,
          'gradientColors': [AppColors.greenSuccess, AppColors.greenHope],
          'avatarSize': 26.0,
        };
      default:
        return {
          'color': AppColors.darkText,
          'gradientColors': [AppColors.darkText, AppColors.grayNeutral],
          'avatarSize': 24.0,
        };
    }
  }

  String _formatContribution(double value) {
    if (value >= 1000) {
      final k = value / 1000;
      return 'Bs ${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return 'Bs ${value.toStringAsFixed(0)}';
  }
}

class _LeaderboardContainer extends StatelessWidget {
  const _LeaderboardContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.grayNeutral.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

enum CampaignSortOption {
  recommended('Recomendado', Icons.auto_awesome),
  newest('Más recientes', Icons.new_releases_outlined),
  funding('Mayor avance', Icons.trending_up),
  donors('Más donadores', Icons.groups_outlined);

  const CampaignSortOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

class SortToggleBar extends StatelessWidget {
  const SortToggleBar({
    super.key,
    required this.selectedOption,
    required this.onSelected,
  });

  final CampaignSortOption selectedOption;
  final ValueChanged<CampaignSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.grayNeutral.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: CampaignSortOption.values.map((option) {
                final isSelected = option == selectedOption;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _SortChip(
                    icon: option.icon,
                    label: option.label,
                    isSelected: isSelected,
                    onTap: () => onSelected(option),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCounter extends StatelessWidget {
  const _ResultCounter({
    required this.count,
    required this.sortOption,
  });

  final int count;
  final CampaignSortOption sortOption;

  @override
  Widget build(BuildContext context) {
    String message = '';
    switch (sortOption) {
      case CampaignSortOption.recommended:
        message = '$count campañas recomendadas para ti';
        break;
      case CampaignSortOption.newest:
        message = '$count campañas recientes';
        break;
      case CampaignSortOption.funding:
        message = '$count campañas por avance';
        break;
      case CampaignSortOption.donors:
        message = '$count campañas por donadores';
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bluePrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.bluePrimary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 16,
                color: AppColors.bluePrimary,
              ),
              const SizedBox(width: 6),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.bluePrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected 
          ? AppColors.bluePrimary 
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected 
                    ? Colors.white 
                    : AppColors.darkText.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : AppColors.darkText,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CampaignProgressTile extends StatelessWidget {
  const CampaignProgressTile({
    super.key,
    required this.campaign,
    required this.onTap,
    required this.onSupport,
    required this.onToggleFavorite,
  });

  final CampaignSummary campaign;
  final VoidCallback onTap;
  final VoidCallback onSupport;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final canSupport = !campaign.isCompleted;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressBadge(percent: campaign.completionPercentage),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      campaign.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.darkText.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: campaign.normalizedProgress,
                      minHeight: 6,
                      color: AppColors.greenHope,
                      backgroundColor: AppColors.greenSoft.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${campaign.donorCount} donadores · Meta Bs ${campaign.goalAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.darkText.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onToggleFavorite,
                    tooltip: campaign.isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
                    icon: Icon(
                      campaign.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: AppColors.orangeAction,
                    ),
                  ),
                  if (canSupport)
                    FilledButton.tonal(
                      onPressed: onSupport,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orangeAction.withValues(alpha: 0.18),
                        foregroundColor: AppColors.orangeAction,
                      ),
                      child: const Text('Apoyar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CampaignHeadlineTile extends StatelessWidget {
  const CampaignHeadlineTile({
    super.key,
    required this.campaign,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final CampaignSummary campaign;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final daysOld = campaign.startDate != null 
        ? DateTime.now().difference(campaign.startDate!).inDays 
        : 0;
    final isVeryNew = daysOld <= 3;
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.bluePrimary.withValues(alpha: 0.1),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.bluePrimary.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen thumbnail con badge NUEVO
              Stack(
                children: [
                  // Imagen
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.bluePrimary.withValues(alpha: 0.15),
                            AppColors.blueSecondary.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: campaign.coverUrl.isNotEmpty
                          ? Image.network(
                              campaign.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                    ),
                  ),
                  
                  // Badge "NUEVO" si tiene menos de 3 días
                  if (isVeryNew)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.orangeAction, AppColors.orangeActionLight],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orangeAction.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          '¡NUEVO!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  
                  // Badge de progreso superpuesto
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${campaign.completionPercentage.toInt()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.bluePrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 14),
              
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoría + días
                    Row(
                      children: [
                        // Categoría chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bluePrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.bluePrimary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            campaign.category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bluePrimary,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Días desde lanzamiento
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppColors.darkText.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Hace $daysOld ${daysOld == 1 ? 'día' : 'días'}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Título
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                        height: 1.3,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stats compactos
                    Row(
                      children: [
                        // Meta
                        _buildCompactStat(
                          icon: Icons.flag_rounded,
                          label: _formatGoal(campaign.goalAmount),
                          color: AppColors.bluePrimary,
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Donantes
                        _buildCompactStat(
                          icon: Icons.people_rounded,
                          label: '${campaign.donorCount}',
                          color: AppColors.greenSuccess,
                        ),
                        
                        const Spacer(),
                        
                        // Botón favorito
                        Container(
                          decoration: BoxDecoration(
                            color: campaign.isFavorite 
                                ? AppColors.orangeAction.withValues(alpha: 0.1)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: campaign.isFavorite
                                  ? AppColors.orangeAction.withValues(alpha: 0.3)
                                  : AppColors.darkText.withValues(alpha: 0.15),
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              campaign.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: campaign.isFavorite 
                                  ? AppColors.orangeAction 
                                  : AppColors.darkText.withValues(alpha: 0.4),
                              size: 20,
                            ),
                            onPressed: onToggleFavorite,
                            tooltip: campaign.isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.bluePrimary.withValues(alpha: 0.1),
      child: const Icon(
        Icons.campaign_rounded,
        size: 36,
        color: AppColors.bluePrimary,
      ),
    );
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatGoal(double amount) {
    if (amount >= 1000000) {
      return 'Bs ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'Bs ${(amount / 1000).toStringAsFixed(0)}k';
    }
    return 'Bs ${amount.toStringAsFixed(0)}';
  }
}

class ProgressBadge extends StatelessWidget {
  const ProgressBadge({
    super.key,
    required this.percent,
    this.size = 56,
  });

  final double percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = percent.clamp(0, 100);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: normalized / 100,
            strokeWidth: size * 0.12,
            color: AppColors.bluePrimary,
            backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.15),
          ),
          Text(
            '${normalized.toStringAsFixed(0)}%',
            style: TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.28,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileIncompleteBanner extends StatelessWidget {
  const ProfileIncompleteBanner({
    super.key,
    required this.onCompleteProfile,
  });

  final RetryCallback onCompleteProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.bluePrimary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Completa tu perfil para crear campañas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Necesitamos validar tu identidad, datos de contacto y cuenta bancaria antes de enviar solicitudes al equipo administrador.',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: AppPrimaryButton(
                label: 'Completar perfil',
                icon: Icons.edit_outlined,
                expanded: false,
                onPressed: onCompleteProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPodiumBar extends StatelessWidget {
  const _EmptyPodiumBar({
    required this.height,
    required this.label,
    required this.color,
  });

  final double height;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            border: Border(
              top: BorderSide(
                color: color,
                width: 3,
              ),
              left: BorderSide(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
              right: BorderSide(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CampaignEmptyState extends StatelessWidget {
  const CampaignEmptyState({super.key, required this.sortOption});

  final CampaignSortOption sortOption;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.greenHope, size: 40),
              const SizedBox(height: 16),
              Text(
                'Aún no hay campañas activas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sé el primero en crear una causa inspiradora y compártela con tu comunidad.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cuando estés listo, usa el botón naranja “Crear campaña” que aparece abajo a la derecha.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget para mostrar el chip de filtro activo
class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.category,
    required this.onClear,
  });

  final String category;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orangeAction.withValues(alpha: 0.1),
            AppColors.bluePrimary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orangeAction.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt,
            size: 18,
            color: AppColors.orangeAction,
          ),
          const SizedBox(width: 8),
          Text(
            'Categoría: ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.mediumText,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            category,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.orangeAction,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.orangeAction.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.orangeAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
