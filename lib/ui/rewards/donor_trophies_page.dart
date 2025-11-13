import 'package:flutter/material.dart';

import '../../controllers/donor_trophy_controller.dart';
import '../../models/donor_trophy_entry.dart';
import '../../theme/app_colors.dart';

class DonorTrophiesPage extends StatefulWidget {
  const DonorTrophiesPage({super.key, required this.controller});

  final DonorTrophyController controller;

  @override
  State<DonorTrophiesPage> createState() => _DonorTrophiesPageState();
}

class _DonorTrophiesPageState extends State<DonorTrophiesPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.hasLoaded) {
      widget.controller.loadLeaderboard();
    }
  }

  Future<void> _handleRefresh() => widget.controller.refresh();

  void _showTrophyInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.bluePrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¿Cómo funciona?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'El sistema de trofeos reconoce tu solidaridad según el monto total donado:',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _TrophyLevelItem(
                icon: Icons.workspace_premium,
                color: const Color(0xFFCD7F32),
                level: 'Bronce',
                range: 'Bs. 100 - 999',
                description: 'Primer paso solidario',
              ),
              const SizedBox(height: 12),
              _TrophyLevelItem(
                icon: Icons.workspace_premium,
                color: const Color(0xFFC0C0C0),
                level: 'Plata',
                range: 'Bs. 1,000 - 4,999',
                description: 'Compromiso constante',
              ),
              const SizedBox(height: 12),
              _TrophyLevelItem(
                icon: Icons.workspace_premium,
                color: const Color(0xFFFFD700),
                level: 'Oro',
                range: 'Bs. 5,000 - 9,999',
                description: 'Generosidad excepcional',
              ),
              const SizedBox(height: 12),
              _TrophyLevelItem(
                icon: Icons.military_tech_rounded,
                color: AppColors.bluePrimary,
                level: 'Platino',
                range: 'Bs. 10,000+',
                description: 'Héroe solidario',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.greenHope.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.greenHope.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.greenHope,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Cada donación suma! 1 punto = 1 boliviano',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.greenHope,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          if (controller.isLoading && controller.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null && controller.entries.isEmpty) {
            return _LeaderboardErrorState(
              message: controller.errorMessage!,
              onRetry: controller.refresh,
            );
          }

          if (controller.entries.isEmpty) {
            return const _LeaderboardEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.bluePrimary,
            child: CustomScrollView(
              slivers: [
                // App Bar personalizado
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: AppColors.bluePrimary,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: () => _showTrophyInfoDialog(context),
                      tooltip: '¿Cómo funciona?',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                    title: const Text(
                      'Ranking Solidario',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.bluePrimary,
                            AppColors.bluePrimary.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -20,
                            right: -30,
                            child: Icon(
                              Icons.emoji_events_outlined,
                              size: 180,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: Icon(
                              Icons.military_tech_outlined,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Contenido
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileHighlight(profile: controller.profile),
                        const SizedBox(height: 24),
                        _TopThreePodium(entries: controller.topThree),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: 'Últimos 10 del ranking',
                          icon: Icons.format_list_numbered,
                        ),
                        const SizedBox(height: 12),
                        ...controller.remainingEntries
                            .take(10)
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _LeaderboardTile(entry: entry),
                                ))
                            .toList(),
                        if (controller.remainingEntries.isEmpty)
                          const _OnlyTopThreeBanner(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHighlight extends StatelessWidget {
  const _ProfileHighlight({this.profile});

  final DonorTrophyProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (profile == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppColors.bluePrimary.withValues(alpha: 0.03),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.bluePrimary.withValues(alpha: 0.7), size: 32),
            const SizedBox(height: 16),
            Text(
              'Dona y desbloquea trofeos',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inicia sesión y registra tus aportes para aparecer en el ranking solidario.',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mediumText,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      );
    }

    final level = profile!.level;
    final nextAmount = profile!.nextLevelAmount;
    final progress = _computeProgress(profile!);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.bluePrimary.withValues(alpha: 0.04),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bluePrimary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.15),
                  backgroundImage:
                      profile!.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                  child: profile!.avatarUrl == null
                      ? Icon(Icons.person, color: AppColors.bluePrimary, size: 36)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile!.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star, size: 12, color: AppColors.orangeAction),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            level.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                  color: AppColors.orangeAction,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (profile!.hasRanking)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.bluePrimary, AppColors.bluePrimary.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bluePrimary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.military_tech, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '#${profile!.position}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  label: 'Total donado',
                  value: _formatCurrency(profile!.totalDonated),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBlock(
                  label: 'Donaciones',
                  value: profile!.donationsCount.toString(),
                ),
              ),
            ],
          ),
          if (nextAmount != null) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final remainingAmount =
                    (nextAmount - profile!.totalDonated).clamp(0, nextAmount).toDouble();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Próximo nivel: ${profile!.nextLevelLevel?.label ?? ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText,
                              ),
                        ),
                        Text(
                          'Faltan ${_formatCurrency(remainingAmount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.darkText.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: AppColors.orangeAction,
                        backgroundColor: AppColors.orangeAction.withValues(alpha: 0.18),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  double _computeProgress(DonorTrophyProfile profile) {
    if (profile.nextLevelAmount == null) {
      return 1;
    }
    final target = profile.nextLevelAmount!;
    final base = profile.currentLevelMinAmount;
    final span = (target - base).clamp(1, double.infinity);
    final progress = (profile.totalDonated - base) / span;
    return progress.clamp(0, 1).toDouble();
  }
}

class _TopThreePodium extends StatelessWidget {
  const _TopThreePodium({required this.entries});

  final List<DonorTrophyEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppColors.grayNeutral.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: AppColors.grayNeutral.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: AppColors.mediumText, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Aún no hay donantes destacados. Sé el primero en apoyar.',
                style: TextStyle(color: AppColors.mediumText, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    final items = entries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Top 3 de la semana',
          icon: Icons.emoji_events,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: items.map((entry) {
            final isChampion = entry.position == 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isChampion ? 4 : 2),
                child: _PodiumCard(entry: entry, isChampion: isChampion),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.entry, required this.isChampion});

  final DonorTrophyEntry entry;
  final bool isChampion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (entry.position) {
      1 => AppColors.orangeAction,
      2 => AppColors.bluePrimary,
      3 => AppColors.greenSuccess,
      _ => AppColors.darkText,
    };
    
    final medalIcon = switch (entry.position) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '',
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isChampion ? 14 : 12, 
        vertical: isChampion ? 24 : 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: isChampion ? 0.4 : 0.25),
          width: isChampion ? 2.5 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: isChampion ? 20 : 12,
            offset: Offset(0, isChampion ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medalla emoji en la parte superior
          Text(
            medalIcon,
            style: TextStyle(fontSize: isChampion ? 32 : 24),
          ),
          const SizedBox(height: 8),
          
          // Avatar con borde de color
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: isChampion ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: isChampion ? 36 : 30,
              backgroundColor: color.withValues(alpha: 0.1),
              backgroundImage:
                  entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
              child: entry.avatarUrl == null
                  ? Icon(Icons.person, color: color, size: isChampion ? 32 : 26)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          
          // Nombre (sin truncar, puede ser de 2 líneas)
          Text(
            entry.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                  fontSize: isChampion ? 13 : 11,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 6),
          
          // Monto donado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _formatCurrency(entry.totalDonated),
              style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: isChampion ? 13 : 11,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          
          // Número de donaciones
          Text(
            '${entry.donationsCount} donaciones',
            style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mediumText,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry});

  final DonorTrophyEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grayNeutral.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
              backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
              child: entry.avatarUrl == null
                  ? Icon(Icons.person, color: AppColors.bluePrimary, size: 28)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '#${entry.position}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          entry.displayName,
          style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.volunteer_activism, size: 14, color: AppColors.mediumText),
            const SizedBox(width: 4),
            Text(
              '${entry.donationsCount} donaciones',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumText,
                  ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.star, size: 14, color: AppColors.orangeAction),
            const SizedBox(width: 4),
            Text(
              entry.level.label,
              style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.orangeAction,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.bluePrimary.withValues(alpha: 0.1),
                AppColors.greenSuccess.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(entry.totalDonated),
                style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.bluePrimary,
                    ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.trending_up,
                color: AppColors.greenSuccess,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardErrorState extends StatelessWidget {
  const _LeaderboardErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardEmptyState extends StatelessWidget {
  const _LeaderboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.bluePrimary),
            const SizedBox(height: 12),
            Text(
              'Aún no hay donaciones registradas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sé de los primeros en apoyar una campaña y tu nombre aparecerá aquí.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlyTopThreeBanner extends StatelessWidget {
  const _OnlyTopThreeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.bluePrimary.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppColors.bluePrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Solo tenemos tres donantes activos registrados. Tu próxima donación puede ampliar la tabla.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.8),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBackground,
            Colors.white,
          ],
        ),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mediumText,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.bluePrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
          ),
        ],
      ),
    );
  }
}

// Widget para encabezado de sección
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.bluePrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.bluePrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.darkText,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

String _formatCurrency(double value) {
  if (value >= 1000) {
    return 'Bs. ${value.toStringAsFixed(0)}';
  }
  return 'Bs. ${value.toStringAsFixed(2)}';
}

class _TrophyLevelItem extends StatelessWidget {
  const _TrophyLevelItem({
    required this.icon,
    required this.color,
    required this.level,
    required this.range,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String level;
  final String range;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    level,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    range,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mediumText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
