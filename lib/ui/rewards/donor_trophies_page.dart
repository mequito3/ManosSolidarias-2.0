import 'package:flutter/material.dart';

import '../../controllers/donor_trophy_controller.dart';
import '../../models/donor_trophy_entry.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_network_image.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/premium_empty_state.dart';
import '../widgets/premium_hero.dart';

class DonorTrophiesPage extends StatefulWidget {
  const DonorTrophiesPage({
    super.key,
    required this.controller,
    this.scrollToRanking = false,
  });

  final DonorTrophyController controller;
  final bool scrollToRanking;

  @override
  State<DonorTrophiesPage> createState() => _DonorTrophiesPageState();
}

class _DonorTrophiesPageState extends State<DonorTrophiesPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _rankingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (!widget.controller.hasLoaded) {
      widget.controller.loadLeaderboard();
    }
    if (widget.scrollToRanking) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToRanking());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToRanking() {
    final ctx = _rankingKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleRefresh() => widget.controller.refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: PremiumAppBar(
        title: 'Ranking solidario',
        actions: [
          PremiumAppBarAction(
            icon: Icons.help_outline_rounded,
            tooltip: '¿Cómo funciona?',
            onPressed: () => _showHowItWorks(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final c = widget.controller;

          if (c.isLoading && c.entries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.bluePrimary),
            );
          }

          if (c.errorMessage != null && c.entries.isEmpty) {
            return PremiumEmptyState(
              icon: Icons.error_outline_rounded,
              iconColor: AppColors.error,
              title: 'No pudimos cargar el ranking',
              description: c.errorMessage!,
              blobColors: [
                AppColors.error.withValues(alpha: 0.08),
                AppColors.bluePrimary.withValues(alpha: 0.06),
              ],
              action: AppPrimaryButton(
                label: 'Reintentar',
                icon: Icons.refresh_rounded,
                onPressed: c.refresh,
              ),
            );
          }

          if (c.entries.isEmpty) {
            return PremiumEmptyState(
              icon: Icons.emoji_events_outlined,
              iconColor: AppColors.orangeAction,
              title: 'Aún no hay donantes destacados',
              description:
                  'Sé de los primeros en apoyar una campaña y tu nombre aparecerá acá en el ranking.',
              blobColors: [
                AppColors.orangeAction.withValues(alpha: 0.10),
                AppColors.bluePrimary.withValues(alpha: 0.06),
              ],
              hintChips: const [
                PremiumHintChip(
                  icon: Icons.volunteer_activism_rounded,
                  label: 'Doná y subí de nivel',
                  color: AppColors.orangeAction,
                ),
                PremiumHintChip(
                  icon: Icons.emoji_events_rounded,
                  label: 'Ganá trofeos',
                  color: AppColors.bluePrimary,
                ),
              ],
            );
          }

          final top3 = c.topThree;
          final rest = c.remainingEntries.take(10).toList();

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.bluePrimary,
            child: CustomScrollView(
              controller: _scrollController,
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
                    child: _buildHero(c.profile),
                  ),
                ),
                if (c.profile?.nextLevelAmount != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppColors.space20,
                      0,
                      AppColors.space20,
                      AppColors.space16,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _NextLevelCard(profile: c.profile!),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.space20,
                    AppColors.space4,
                    AppColors.space20,
                    AppColors.space12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: PremiumSectionHeader(
                      title: 'Top 3 del ranking',
                      accentGradient: AppColors.actionGradient,
                      countColor: AppColors.orangeAction,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.space20,
                    0,
                    AppColors.space20,
                    AppColors.space16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _Podium(entries: top3),
                  ),
                ),
                SliverPadding(
                  key: _rankingKey,
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.space20,
                    AppColors.space4,
                    AppColors.space20,
                    AppColors.space12,
                  ),
                  sliver: const SliverToBoxAdapter(
                    child: PremiumSectionHeader(
                      title: 'Top 10 del resto',
                      accentGradient: AppColors.primaryGradient,
                    ),
                  ),
                ),
                if (rest.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppColors.space20,
                      0,
                      AppColors.space20,
                      AppColors.space32,
                    ),
                    sliver: const SliverToBoxAdapter(
                      child: _OnlyTopThreeBanner(),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppColors.space20,
                      AppColors.space4,
                      AppColors.space20,
                      AppColors.space12,
                    ),
                    sliver: SliverList.separated(
                      itemCount: rest.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppColors.space12),
                      itemBuilder: (context, index) =>
                          _RankTile(entry: rest[index]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppColors.space20,
                      AppColors.space8,
                      AppColors.space20,
                      AppColors.space32,
                    ),
                    sliver: const SliverToBoxAdapter(
                      child: _RankingFooterNote(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(DonorTrophyProfile? profile) {
    if (profile == null) {
      return PremiumHero(
        icon: Icons.emoji_events_rounded,
        iconGradient: AppColors.actionGradient,
        iconShadowColor: AppColors.orangeAction,
        title: 'Doná y desbloqueá trofeos',
        subtitle:
            'Iniciá sesión y registrá tus aportes para aparecer en el ranking.',
        backgroundColors: [
          AppColors.orangeAction.withValues(alpha: 0.10),
          AppColors.bluePrimary.withValues(alpha: 0.06),
        ],
        blobColors: [
          AppColors.orangeAction.withValues(alpha: 0.14),
          AppColors.bluePrimary.withValues(alpha: 0.10),
        ],
      );
    }

    final hasPosition = profile.hasRanking;
    final title = hasPosition
        ? 'Estás en el puesto #${profile.position}'
        : profile.totalDonated > 0
            ? '¡Sumando puntos!'
            : 'Aún no apareces';
    final subtitle =
        '${profile.level.label} · ${profile.donationsCount} donaciones';

    return PremiumHero(
      icon: Icons.emoji_events_rounded,
      iconGradient: AppColors.actionGradient,
      iconShadowColor: AppColors.orangeAction,
      title: title,
      subtitle: subtitle,
      backgroundColors: [
        AppColors.orangeAction.withValues(alpha: 0.10),
        AppColors.bluePrimary.withValues(alpha: 0.06),
      ],
      blobColors: [
        AppColors.orangeAction.withValues(alpha: 0.14),
        AppColors.bluePrimary.withValues(alpha: 0.10),
      ],
      stats: [
        PremiumStatPill(
          icon: Icons.savings_rounded,
          label: 'Total donado',
          value: _formatCompact(profile.totalDonated),
          color: AppColors.greenHope,
        ),
        PremiumStatPill(
          icon: Icons.volunteer_activism_rounded,
          label: 'Donaciones',
          value: '${profile.donationsCount}',
          color: AppColors.bluePrimary,
        ),
        PremiumStatPill(
          icon: Icons.workspace_premium_rounded,
          label: 'Nivel',
          value: _shortLevelName(profile.level),
          color: AppColors.orangeAction,
        ),
      ],
    );
  }

  void _showHowItWorks(BuildContext context) {
    final userTotal = widget.controller.profile?.totalDonated ?? 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => _HowItWorksSheet(userTotalDonated: userTotal),
    );
  }
}

// ─── How-it-works bottom sheet ──────────────────────────────────────────────

class _HowItWorksSheet extends StatelessWidget {
  const _HowItWorksSheet({required this.userTotalDonated});
  final double userTotalDonated;

  static const _bronze = Color(0xFFCD7F32);
  static const _silver = Color(0xFF9DA3AE);
  static const _gold = AppColors.orangeAction;
  static const _platinum = AppColors.bluePrimary;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final levels = <_LevelData>[
      _LevelData(
        color: _bronze,
        icon: Icons.workspace_premium_rounded,
        name: 'Bronce',
        range: 'Bs 100 – 999',
        description: 'Primer paso solidario.',
        minAmount: 100,
        maxAmount: 999,
      ),
      _LevelData(
        color: _silver,
        icon: Icons.workspace_premium_rounded,
        name: 'Plata',
        range: 'Bs 1.000 – 4.999',
        description: 'Compromiso constante con la comunidad.',
        minAmount: 1000,
        maxAmount: 4999,
      ),
      _LevelData(
        color: _gold,
        icon: Icons.emoji_events_rounded,
        name: 'Oro',
        range: 'Bs 5.000 – 9.999',
        description: 'Generosidad excepcional.',
        minAmount: 5000,
        maxAmount: 9999,
      ),
      _LevelData(
        color: _platinum,
        icon: Icons.military_tech_rounded,
        name: 'Platino',
        range: 'Bs 10.000+',
        description: 'Héroe solidario de nuestra red.',
        minAmount: 10000,
        maxAmount: double.infinity,
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          AppColors.orangeAction.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  left: -50,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bluePrimary.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    AppColors.space20,
                    AppColors.space12,
                    AppColors.space20,
                    AppColors.space24 + mq.padding.bottom,
                  ),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.grayNeutral.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppColors.space20),

                    // Hero
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppColors.space12),
                          decoration: BoxDecoration(
                            gradient: AppColors.actionGradient,
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusMd),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orangeAction
                                    .withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppColors.space12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cómo funciona el ranking',
                                style: TextStyle(
                                  color: AppColors.darkText,
                                  fontSize: AppColors.fontSizeXl,
                                  fontWeight: AppColors.fontWeightExtraBold,
                                  letterSpacing: -0.4,
                                  height: 1.15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Doná, subí de nivel y desbloqueá trofeos.',
                                style: TextStyle(
                                  color: AppColors.mediumText,
                                  fontSize: AppColors.fontSizeSm,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppColors.space8),
                        _SheetCloseButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppColors.space20),

                    // Regla principal destacada
                    Container(
                      padding: const EdgeInsets.all(AppColors.space16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusLg),
                        boxShadow: AppColors.shadowSm,
                        border: Border.all(
                          color: AppColors.greenHope.withValues(alpha: 0.22),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppColors.space8),
                            decoration: BoxDecoration(
                              color: AppColors.greenHope
                                  .withValues(alpha: 0.14),
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusSm),
                            ),
                            child: const Icon(
                              Icons.savings_rounded,
                              color: AppColors.greenHope,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppColors.space12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '1 boliviano = 1 punto',
                                  style: TextStyle(
                                    color: AppColors.darkText,
                                    fontSize: AppColors.fontSizeMd,
                                    fontWeight:
                                        AppColors.fontWeightExtraBold,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Cada donación aprobada suma al total acumulado.',
                                  style: TextStyle(
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
                    ),

                    const SizedBox(height: AppColors.space20),

                    // Section header
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: AppColors.actionGradient,
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusXs),
                          ),
                        ),
                        const SizedBox(width: AppColors.space12),
                        const Text(
                          'Niveles solidarios',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: AppColors.fontSizeMd,
                            fontWeight: AppColors.fontWeightExtraBold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppColors.space12),

                    // Level cards
                    for (final level in levels) ...[
                      _LevelCard(
                        data: level,
                        isCurrent: userTotalDonated >= level.minAmount &&
                            userTotalDonated <= level.maxAmount,
                      ),
                      const SizedBox(height: AppColors.space12),
                    ],

                    const SizedBox(height: AppColors.space8),

                    // Tip card
                    Container(
                      padding: const EdgeInsets.all(AppColors.space16),
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusLg),
                        border: Border.all(
                          color:
                              AppColors.bluePrimary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: AppColors.bluePrimary,
                            size: 22,
                          ),
                          const SizedBox(width: AppColors.space12),
                          const Expanded(
                            child: Text(
                              'El podio se actualiza en tiempo real. Doná lo que puedas — incluso aportes pequeños suman al ranking.',
                              style: TextStyle(
                                color: AppColors.darkText,
                                fontSize: AppColors.fontSizeSm,
                                fontWeight: AppColors.fontWeightSemiBold,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppColors.space24),

                    AppPrimaryButton(
                      label: '¡Entendido!',
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LevelData {
  const _LevelData({
    required this.color,
    required this.icon,
    required this.name,
    required this.range,
    required this.description,
    required this.minAmount,
    required this.maxAmount,
  });

  final Color color;
  final IconData icon;
  final String name;
  final String range;
  final String description;
  final double minAmount;
  final double maxAmount;
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.data, required this.isCurrent});

  final _LevelData data;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowSm,
        border: Border.all(
          color: isCurrent
              ? data.color.withValues(alpha: 0.55)
              : AppColors.grayLight,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.color.withValues(alpha: 0.95),
                  data.color.withValues(alpha: 0.65),
                ],
              ),
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: data.color.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(data.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      data.name,
                      style: TextStyle(
                        color: data.color,
                        fontSize: AppColors.fontSizeMd,
                        fontWeight: AppColors.fontWeightExtraBold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: AppColors.space8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppColors.space8, vertical: 2),
                        decoration: BoxDecoration(
                          color: data.color.withValues(alpha: 0.14),
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusRound),
                        ),
                        child: Text(
                          'TU NIVEL',
                          style: TextStyle(
                            color: data.color,
                            fontSize: 9,
                            fontWeight: AppColors.fontWeightExtraBold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  data.range,
                  style: const TextStyle(
                    color: AppColors.mediumText,
                    fontSize: AppColors.fontSizeSm,
                    fontWeight: AppColors.fontWeightSemiBold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  style: const TextStyle(
                    color: AppColors.lightText,
                    fontSize: AppColors.fontSizeXs,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grayLight.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.close_rounded,
            color: AppColors.darkText,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Next level progress card ───────────────────────────────────────────────

class _NextLevelCard extends StatelessWidget {
  const _NextLevelCard({required this.profile});
  final DonorTrophyProfile profile;

  @override
  Widget build(BuildContext context) {
    final next = profile.nextLevelAmount!;
    final base = profile.currentLevelMinAmount;
    final span = (next - base).clamp(1, double.infinity);
    final progress =
        ((profile.totalDonated - base) / span).clamp(0.0, 1.0).toDouble();
    final remaining = (next - profile.totalDonated).clamp(0, next).toDouble();

    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowMd,
        border: const Border(
          left: BorderSide(color: AppColors.orangeAction, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.space8),
                decoration: BoxDecoration(
                  color: AppColors.orangeAction.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppColors.orangeAction,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppColors.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Próximo nivel · ${profile.nextLevelLevel?.label ?? ''}',
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: AppColors.fontSizeBase,
                        fontWeight: AppColors.fontWeightBold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Te faltan ${_formatCurrency(remaining)}',
                      style: const TextStyle(
                        color: AppColors.mediumText,
                        fontSize: AppColors.fontSizeSm,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.orangeAction,
                  fontSize: AppColors.fontSizeLg,
                  fontWeight: AppColors.fontWeightExtraBold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radiusXs),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.orangeAction.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.orangeAction),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Podium with 3 cards (1st in the middle, taller) ────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});
  final List<DonorTrophyEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppColors.space20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          boxShadow: AppColors.shadowMd,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppColors.space12),
              decoration: BoxDecoration(
                color: AppColors.orangeAction.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
              ),
              child: const Icon(Icons.emoji_events_outlined,
                  color: AppColors.orangeAction, size: 28),
            ),
            const SizedBox(width: AppColors.space12),
            const Expanded(
              child: Text(
                'Aún no hay donantes destacados. Sé el primero en apoyar.',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: AppColors.fontSizeBase,
                  fontWeight: AppColors.fontWeightSemiBold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final byPosition = {for (final e in entries) e.position: e};
    final first = byPosition[1];
    final second = byPosition[2];
    final third = byPosition[3];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second != null
                ? _PodiumCard(entry: second, isChampion: false)
                : const _PodiumPlaceholder(position: 2),
          ),
          const SizedBox(width: AppColors.space8),
          Expanded(
            child: first != null
                ? _PodiumCard(entry: first, isChampion: true)
                : const _PodiumPlaceholder(position: 1),
          ),
          const SizedBox(width: AppColors.space8),
          Expanded(
            child: third != null
                ? _PodiumCard(entry: third, isChampion: false)
                : const _PodiumPlaceholder(position: 3),
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.entry, required this.isChampion});

  final DonorTrophyEntry entry;
  final bool isChampion;

  @override
  Widget build(BuildContext context) {
    final color = _podiumColor(entry.position);
    final medal = _medalEmoji(entry.position);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isChampion ? AppColors.space12 : AppColors.space8,
        vertical: isChampion ? AppColors.space20 : AppColors.space16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(
          color: color.withValues(alpha: isChampion ? 0.45 : 0.25),
          width: isChampion ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isChampion ? 0.22 : 0.12),
            blurRadius: isChampion ? 18 : 10,
            offset: Offset(0, isChampion ? 6 : 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(medal, style: TextStyle(fontSize: isChampion ? 30 : 22)),
          const SizedBox(height: AppColors.space8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: Container(
              width: isChampion ? 64 : 52,
              height: isChampion ? 64 : 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.grayLight,
              ),
              child: ClipOval(
                child: entry.avatarUrl != null
                    ? AppNetworkImage(
                        url: entry.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: _AvatarFallback(color: color),
                      )
                    : _AvatarFallback(color: color),
              ),
            ),
          ),
          const SizedBox(height: AppColors.space8),
          Text(
            entry.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: isChampion
                  ? AppColors.fontSizeBase
                  : AppColors.fontSizeSm,
              fontWeight: AppColors.fontWeightExtraBold,
              letterSpacing: -0.2,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppColors.space8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppColors.space8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
            ),
            child: Text(
              _formatCompact(entry.totalDonated),
              style: TextStyle(
                color: color,
                fontSize: isChampion
                    ? AppColors.fontSizeSm
                    : AppColors.fontSizeXs,
                fontWeight: AppColors.fontWeightExtraBold,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.donationsCount} dona${entry.donationsCount == 1 ? "ción" : "ciones"}',
            style: const TextStyle(
              color: AppColors.lightText,
              fontSize: AppColors.fontSizeXs,
              fontWeight: AppColors.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumPlaceholder extends StatelessWidget {
  const _PodiumPlaceholder({required this.position});
  final int position;

  @override
  Widget build(BuildContext context) {
    final color = _podiumColor(position);
    final isChampion = position == 1;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppColors.space8,
        vertical: isChampion ? AppColors.space20 : AppColors.space16,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_medalEmoji(position),
              style: TextStyle(fontSize: isChampion ? 30 : 22)),
          const SizedBox(height: AppColors.space8),
          Container(
            width: isChampion ? 64 : 52,
            height: isChampion ? 64 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.10),
            ),
            child: Icon(Icons.person_outline_rounded,
                color: color.withValues(alpha: 0.6),
                size: isChampion ? 32 : 26),
          ),
          const SizedBox(height: AppColors.space12),
          const Text(
            'Disponible',
            style: TextStyle(
              color: AppColors.lightText,
              fontSize: AppColors.fontSizeSm,
              fontWeight: AppColors.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.10),
      child: Icon(Icons.person_rounded, color: color, size: 28),
    );
  }
}

Color _podiumColor(int position) {
  switch (position) {
    case 1:
      return AppColors.orangeAction;
    case 2:
      return AppColors.bluePrimary;
    case 3:
      return AppColors.greenHope;
    default:
      return AppColors.darkText;
  }
}

String _medalEmoji(int position) {
  switch (position) {
    case 1:
      return '🥇';
    case 2:
      return '🥈';
    case 3:
      return '🥉';
    default:
      return '';
  }
}

// ─── Rest-of-ranking tile ───────────────────────────────────────────────────

class _RankTile extends StatelessWidget {
  const _RankTile({required this.entry});
  final DonorTrophyEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowSm,
        border: Border.all(
          color: AppColors.grayLight.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: AppColors.space8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Text(
              '#${entry.position}',
              style: const TextStyle(
                color: AppColors.bluePrimary,
                fontSize: AppColors.fontSizeBase,
                fontWeight: AppColors.fontWeightExtraBold,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: AppColors.space12),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grayLight,
            ),
            child: ClipOval(
              child: entry.avatarUrl != null
                  ? AppNetworkImage(
                      url: entry.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: const _AvatarFallback(
                          color: AppColors.bluePrimary),
                    )
                  : const _AvatarFallback(color: AppColors.bluePrimary),
            ),
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.displayName,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeBase,
                    fontWeight: AppColors.fontWeightBold,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        size: 12, color: AppColors.orangeAction),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        entry.level.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.orangeAction,
                          fontSize: AppColors.fontSizeXs,
                          fontWeight: AppColors.fontWeightSemiBold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppColors.space8),
                    const Icon(Icons.volunteer_activism_rounded,
                        size: 12, color: AppColors.mediumText),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.donationsCount}',
                      style: const TextStyle(
                        color: AppColors.mediumText,
                        fontSize: AppColors.fontSizeXs,
                        fontWeight: AppColors.fontWeightSemiBold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppColors.space8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppColors.space12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.greenHope.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
            ),
            child: Text(
              _formatCompact(entry.totalDonated),
              style: const TextStyle(
                color: AppColors.greenHope,
                fontSize: AppColors.fontSizeSm,
                fontWeight: AppColors.fontWeightExtraBold,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Footer cuando hay top10 mostrado ───────────────────────────────────────

class _RankingFooterNote extends StatelessWidget {
  const _RankingFooterNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.info_outline_rounded,
            size: 14, color: AppColors.lightText),
        const SizedBox(width: 6),
        Text(
          'Mostrando los primeros 10 donantes del ranking',
          style: TextStyle(
            color: AppColors.lightText.withValues(alpha: 0.95),
            fontSize: AppColors.fontSizeXs,
            fontWeight: AppColors.fontWeightSemiBold,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Banner cuando solo hay top 3 ───────────────────────────────────────────

class _OnlyTopThreeBanner extends StatelessWidget {
  const _OnlyTopThreeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppColors.space8),
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: AppColors.bluePrimary, size: 18),
          ),
          const SizedBox(width: AppColors.space12),
          const Expanded(
            child: Text(
              'Solo hay tres donantes activos por ahora. Tu próxima donación puede ampliar la tabla.',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: AppColors.fontSizeSm,
                fontWeight: AppColors.fontWeightSemiBold,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

String _formatCurrency(double value) {
  if (value >= 1000) {
    return 'Bs ${value.toStringAsFixed(0)}';
  }
  return 'Bs ${value.toStringAsFixed(2)}';
}

String _formatCompact(double value) {
  if (value >= 1000000) {
    return 'Bs ${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return 'Bs ${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
  }
  return 'Bs ${value.toStringAsFixed(0)}';
}

String _shortLevelName(TrophyLevel level) {
  switch (level) {
    case TrophyLevel.top1:
      return '#1';
    case TrophyLevel.top2:
      return '#2';
    case TrophyLevel.top3:
      return '#3';
    case TrophyLevel.legend:
      return 'Leyenda';
    case TrophyLevel.champion:
      return 'Campeón';
    case TrophyLevel.hero:
      return 'Héroe';
    case TrophyLevel.ally:
      return 'Aliado';
    case TrophyLevel.supporter:
      return 'Acompañante';
    case TrophyLevel.friend:
      return 'Amigo';
    case TrophyLevel.starter:
      return 'Nuevo';
  }
}
