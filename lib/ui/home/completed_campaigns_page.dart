import 'package:flutter/material.dart';

import '../../controllers/campaign_controller.dart';
import '../../models/campaign.dart';
import '../../models/user_profile.dart';
import '../../services/campaign_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_network_image.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/premium_empty_state.dart';
import '../widgets/premium_hero.dart';
import 'campaign_evidence_page.dart';

enum _CompletedFilter { todas, verificadas, sinVerificar, enProceso }

class CompletedCampaignsPage extends StatefulWidget {
  const CompletedCampaignsPage({
    super.key,
    required this.controller,
    required this.campaignService,
    this.userProfile,
  });

  final CampaignController controller;
  final CampaignService campaignService;
  final UserProfile? userProfile;

  @override
  State<CompletedCampaignsPage> createState() =>
      _CompletedCampaignsPageState();
}

class _CompletedCampaignsPageState extends State<CompletedCampaignsPage> {
  _CompletedFilter _filter = _CompletedFilter.todas;

  List<CampaignSummary> _apply(
    List<CampaignSummary> all,
    _CompletedFilter f,
  ) {
    switch (f) {
      case _CompletedFilter.todas:
        return all;
      case _CompletedFilter.verificadas:
        return all
            .where((c) => c.verificationStatus == VerificationStatus.verificada)
            .toList();
      case _CompletedFilter.sinVerificar:
        return all
            .where((c) =>
                c.verificationStatus == VerificationStatus.sinVerificar)
            .toList();
      case _CompletedFilter.enProceso:
        return all
            .where((c) =>
                c.verificationStatus == VerificationStatus.pendienteEvidencia ||
                c.verificationStatus == VerificationStatus.enRevision)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: const PremiumAppBar(title: 'Campañas completadas'),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading &&
              widget.controller.completedCampaigns.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.bluePrimary),
            );
          }

          final all = widget.controller.completedCampaigns;

          if (all.isEmpty) {
            return PremiumEmptyState(
              icon: Icons.celebration_rounded,
              iconColor: AppColors.greenHope,
              title: 'Aún no hay campañas completadas',
              description:
                  'Cuando una campaña alcance su meta aparecerá acá. Las verificadas mostrarán evidencia de cómo se usó el dinero.',
              blobColors: [
                AppColors.greenHope.withValues(alpha: 0.10),
                AppColors.bluePrimary.withValues(alpha: 0.06),
              ],
              hintChips: const [
                PremiumHintChip(
                  icon: Icons.verified_rounded,
                  label: 'Con evidencia',
                  color: AppColors.greenHope,
                ),
                PremiumHintChip(
                  icon: Icons.access_time_rounded,
                  label: '14 días para subir',
                  color: AppColors.orangeAction,
                ),
              ],
            );
          }

          final verified = all
              .where((c) =>
                  c.verificationStatus == VerificationStatus.verificada)
              .length;
          final unverified = all
              .where((c) =>
                  c.verificationStatus == VerificationStatus.sinVerificar)
              .length;
          final inProcess = all
              .where((c) =>
                  c.verificationStatus ==
                      VerificationStatus.pendienteEvidencia ||
                  c.verificationStatus == VerificationStatus.enRevision)
              .length;

          final filtered = _apply(all, _filter);

          return RefreshIndicator(
            color: AppColors.bluePrimary,
            onRefresh: () => widget.controller.refreshCampaigns(),
            child: CustomScrollView(
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
                      icon: Icons.celebration_rounded,
                      iconGradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.greenHope,
                          AppColors.greenSuccess,
                        ],
                      ),
                      iconShadowColor: AppColors.greenHope,
                      title: all.length == 1
                          ? '1 meta alcanzada'
                          : '${all.length} metas alcanzadas',
                      subtitle: 'Celebramos cada sueño cumplido.',
                      backgroundColors: [
                        AppColors.greenHope.withValues(alpha: 0.10),
                        AppColors.bluePrimary.withValues(alpha: 0.06),
                      ],
                      blobColors: [
                        AppColors.greenHope.withValues(alpha: 0.14),
                        AppColors.bluePrimary.withValues(alpha: 0.10),
                      ],
                      stats: [
                        PremiumStatPill(
                          icon: Icons.verified_rounded,
                          label: 'Verificadas',
                          value: '$verified',
                          color: AppColors.greenHope,
                        ),
                        PremiumStatPill(
                          icon: Icons.hourglass_top_rounded,
                          label: 'En proceso',
                          value: '$inProcess',
                          color: AppColors.orangeAction,
                        ),
                        PremiumStatPill(
                          icon: Icons.report_gmailerrorred_rounded,
                          label: 'Sin verificar',
                          value: '$unverified',
                          color: AppColors.grayDark,
                        ),
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
                    child: _FilterTabs(
                      filter: _filter,
                      counts: {
                        _CompletedFilter.todas: all.length,
                        _CompletedFilter.verificadas: verified,
                        _CompletedFilter.enProceso: inProcess,
                        _CompletedFilter.sinVerificar: unverified,
                      },
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(AppColors.space20),
                    sliver: SliverToBoxAdapter(
                      child: _NoResultsForFilter(filter: _filter),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppColors.space20,
                      AppColors.space4,
                      AppColors.space20,
                      AppColors.space32,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppColors.space16),
                      itemBuilder: (context, index) {
                        final campaign = filtered[index];
                        return _CompletedCampaignCard(
                          campaign: campaign,
                          onTap: () => _openEvidence(campaign),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openEvidence(CampaignSummary campaign) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CampaignEvidencePage(
          campaign: campaign,
          campaignService: widget.campaignService,
          currentUserId: widget.userProfile?.userId,
          isAdmin: widget.userProfile?.isAdmin ?? false,
        ),
      ),
    );
  }
}

// ─── Filter tabs ─────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.filter,
    required this.counts,
    required this.onChanged,
  });

  final _CompletedFilter filter;
  final Map<_CompletedFilter, int> counts;
  final ValueChanged<_CompletedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (_CompletedFilter.todas, 'Todas', AppColors.bluePrimary),
      (_CompletedFilter.verificadas, 'Verificadas', AppColors.greenHope),
      (_CompletedFilter.enProceso, 'En proceso', AppColors.orangeAction),
      (_CompletedFilter.sinVerificar, 'Sin verificar', AppColors.grayDark),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final opt in options) ...[
            _FilterChip(
              label: opt.$2,
              count: counts[opt.$1] ?? 0,
              selected: filter == opt.$1,
              color: opt.$3,
              onTap: () => onChanged(opt.$1),
            ),
            const SizedBox(width: AppColors.space8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? color : Colors.white;
    final fg = selected ? Colors.white : AppColors.darkText;
    final countBg = selected
        ? Colors.white.withValues(alpha: 0.22)
        : color.withValues(alpha: 0.10);
    final countFg = selected ? Colors.white : color;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppColors.radiusRound),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppColors.space12, vertical: AppColors.space8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
            border: Border.all(
              color: selected
                  ? color
                  : AppColors.grayLight.withValues(alpha: 0.9),
              width: 1.4,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: AppColors.fontSizeSm,
                  fontWeight: AppColors.fontWeightExtraBold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: AppColors.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.space8, vertical: 2),
                decoration: BoxDecoration(
                  color: countBg,
                  borderRadius: BorderRadius.circular(AppColors.radiusRound),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: countFg,
                    fontSize: AppColors.fontSizeXs,
                    fontWeight: AppColors.fontWeightExtraBold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Campaign card with verification badge ──────────────────────────────────

class _CompletedCampaignCard extends StatelessWidget {
  const _CompletedCampaignCard({
    required this.campaign,
    required this.onTap,
  });

  final CampaignSummary campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCover = campaign.coverUrl.isNotEmpty;
    final badge = _VerificationBadge(status: campaign.verificationStatus);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasCover)
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: AppNetworkImage(
                        url: campaign.coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: _coverPlaceholder(),
                      ),
                    ),
                    Positioned(
                      top: AppColors.space12,
                      right: AppColors.space12,
                      child: badge,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(AppColors.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasCover) ...[
                      badge,
                      const SizedBox(height: AppColors.space12),
                    ],
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: AppColors.fontSizeMd,
                        fontWeight: AppColors.fontWeightExtraBold,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppColors.space8),
                    Text(
                      campaign.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mediumText,
                        fontSize: AppColors.fontSizeSm,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppColors.space12),
                    Row(
                      children: [
                        _MiniStat(
                          icon: Icons.payments_rounded,
                          label: 'Bs ${_formatAmount(campaign.raisedAmount)}',
                          color: AppColors.greenHope,
                        ),
                        const SizedBox(width: AppColors.space16),
                        _MiniStat(
                          icon: Icons.people_rounded,
                          label: '${campaign.donorCount}',
                          color: AppColors.bluePrimary,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.lightText.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                    _DeadlineLine(campaign: campaign),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: AppColors.greenHope.withValues(alpha: 0.10),
      child: const Center(
        child: Icon(
          Icons.campaign_rounded,
          size: 48,
          color: AppColors.greenHope,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: AppColors.fontSizeSm,
            fontWeight: AppColors.fontWeightExtraBold,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _DeadlineLine extends StatelessWidget {
  const _DeadlineLine({required this.campaign});
  final CampaignSummary campaign;

  @override
  Widget build(BuildContext context) {
    final status = campaign.verificationStatus;

    // En revisión: ya subió evidencia, no mostramos countdown.
    // Se muestra en su lugar un chip neutral azul.
    if (status == VerificationStatus.enRevision) {
      return const Padding(
        padding: EdgeInsets.only(top: AppColors.space12),
        child: _ReviewPill(),
      );
    }

    if (status != VerificationStatus.pendienteEvidencia) {
      return const SizedBox.shrink();
    }
    final days = campaign.daysUntilEvidenceDeadline;
    if (days == null) return const SizedBox.shrink();

    final isUrgent = days <= 3;
    final color = isUrgent ? AppColors.error : AppColors.orangeAction;
    final text = days < 0
        ? 'Plazo vencido'
        : days == 0
            ? 'Vence hoy'
            : days == 1
                ? '1 día restante'
                : '$days días restantes';

    return Padding(
      padding: const EdgeInsets.only(top: AppColors.space12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: AppColors.fontSizeXs,
                fontWeight: AppColors.fontWeightExtraBold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewPill extends StatelessWidget {
  const _ReviewPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.space12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.fact_check_rounded,
              size: 14, color: AppColors.bluePrimary),
          SizedBox(width: 6),
          Text(
            'Esperando aprobación del admin',
            style: TextStyle(
              color: AppColors.bluePrimary,
              fontSize: AppColors.fontSizeXs,
              fontWeight: AppColors.fontWeightExtraBold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Verification badge ──────────────────────────────────────────────────────

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.status});
  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    late final IconData icon;

    switch (status) {
      case VerificationStatus.verificada:
        color = AppColors.greenHope;
        label = 'VERIFICADA';
        icon = Icons.verified_rounded;
        break;
      case VerificationStatus.pendienteEvidencia:
        color = AppColors.orangeAction;
        label = 'PENDIENTE';
        icon = Icons.hourglass_top_rounded;
        break;
      case VerificationStatus.enRevision:
        color = AppColors.bluePrimary;
        label = 'EN REVISIÓN';
        icon = Icons.fact_check_rounded;
        break;
      case VerificationStatus.sinVerificar:
        color = AppColors.grayDark;
        label = 'SIN VERIFICAR';
        icon = Icons.report_gmailerrorred_rounded;
        break;
      case VerificationStatus.noAplica:
        color = AppColors.greenHope;
        label = 'META ALCANZADA';
        icon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.space12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppColors.fontSizeXs,
              fontWeight: AppColors.fontWeightExtraBold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No results for filter ──────────────────────────────────────────────────

class _NoResultsForFilter extends StatelessWidget {
  const _NoResultsForFilter({required this.filter});
  final _CompletedFilter filter;

  String get _message {
    switch (filter) {
      case _CompletedFilter.verificadas:
        return 'Ninguna campaña verificada todavía. Cuando los creadores suban evidencia y el admin la apruebe, aparecerán acá.';
      case _CompletedFilter.enProceso:
        return 'No hay campañas con evidencia pendiente. Buena noticia: todos los creadores subieron a tiempo.';
      case _CompletedFilter.sinVerificar:
        return 'No hay campañas sin verificar. Cuando alguna no suba evidencia en el plazo, aparecerá acá.';
      case _CompletedFilter.todas:
        return 'No hay campañas completadas.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppColors.space12),
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
            ),
            child: const Icon(
              Icons.filter_alt_off_rounded,
              color: AppColors.bluePrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Text(
              _message,
              style: const TextStyle(
                color: AppColors.mediumText,
                fontSize: AppColors.fontSizeSm,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatAmount(double amount) {
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}k';
  return amount.toStringAsFixed(0);
}
