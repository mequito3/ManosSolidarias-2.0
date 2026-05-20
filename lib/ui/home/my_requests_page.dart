import 'package:flutter/material.dart';
import '../../models/campaign.dart';
import '../../services/campaign_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_network_image.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/premium_empty_state.dart';
import '../widgets/premium_hero.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({
    super.key,
    required this.campaignService,
    required this.onOpenCampaign,
  });

  final CampaignService campaignService;
  final ValueChanged<CampaignSummary> onOpenCampaign;

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  List<CampaignSummary>? _requests;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await widget.campaignService.fetchMyRequests();
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              e.toString().replaceAll('CampaignServiceException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() => _loadRequests();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: PremiumAppBar(
        title: 'Mis solicitudes',
        actions: [
          PremiumAppBarAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _loadRequests,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.bluePrimary),
      );
    }
    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadRequests);
    }
    if (_requests == null || _requests!.isEmpty) {
      return PremiumEmptyState(
        icon: Icons.assignment_outlined,
        iconColor: AppColors.bluePrimary,
        title: 'No tienes solicitudes',
        description:
            'Las campañas que crees aparecerán acá con su estado: en revisión, aprobada o rechazada.',
        blobColors: [
          AppColors.bluePrimary.withValues(alpha: 0.10),
          AppColors.greenHope.withValues(alpha: 0.08),
        ],
        hintChips: const [
          PremiumHintChip(
            icon: Icons.add_circle_outline_rounded,
            label: 'Crea una campaña',
            color: AppColors.bluePrimary,
          ),
          PremiumHintChip(
            icon: Icons.timeline_rounded,
            label: 'Sigue su estado',
            color: AppColors.greenHope,
          ),
        ],
      );
    }

    final requests = _requests!;
    final approved = requests.where((r) => r.status == 'aprobada').length;
    final pending = requests.where((r) => r.status == 'pendiente').length;
    final rejected = requests.where((r) => r.status == 'rechazada').length;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.bluePrimary,
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
                icon: Icons.assignment_rounded,
                iconGradient: AppColors.primaryGradient,
                iconShadowColor: AppColors.bluePrimary,
                title: requests.length == 1
                    ? '1 solicitud enviada'
                    : '${requests.length} solicitudes enviadas',
                subtitle: 'Hacé seguimiento al estado de tus campañas.',
                backgroundColors: [
                  AppColors.bluePrimary.withValues(alpha: 0.10),
                  AppColors.greenHope.withValues(alpha: 0.07),
                ],
                blobColors: [
                  AppColors.bluePrimary.withValues(alpha: 0.12),
                  AppColors.greenHope.withValues(alpha: 0.10),
                ],
                stats: [
                  PremiumStatPill(
                    icon: Icons.check_circle_rounded,
                    label: 'Aprobadas',
                    value: '$approved',
                    color: AppColors.greenHope,
                  ),
                  PremiumStatPill(
                    icon: Icons.schedule_rounded,
                    label: 'En revisión',
                    value: '$pending',
                    color: AppColors.orangeAction,
                  ),
                  PremiumStatPill(
                    icon: Icons.cancel_rounded,
                    label: 'Rechazadas',
                    value: '$rejected',
                    color: AppColors.error,
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
              child: PremiumSectionHeader(
                title: 'Historial de solicitudes',
                accentGradient: AppColors.primaryGradient,
                count: requests.length,
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
              itemCount: requests.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppColors.space16),
              itemBuilder: (context, index) {
                final request = requests[index];
                return _RequestCard(
                  request: request,
                  onTap: () => widget.onOpenCampaign(request),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Request card ───────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final CampaignSummary request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCover = request.coverUrl.isNotEmpty;
    final isApproved = request.status == 'aprobada';

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
                        url: request.coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: AppColors.grayLight,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            size: 48,
                            color: AppColors.grayNeutral,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: AppColors.space12,
                      right: AppColors.space12,
                      child: _StatusBadge(
                          status: request.status, floating: true),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
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
                      _StatusBadge(status: request.status),
                      const SizedBox(height: AppColors.space12),
                    ],
                    Text(
                      request.title,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: AppColors.fontSizeMd,
                        fontWeight: AppColors.fontWeightExtraBold,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppColors.space8),
                    Text(
                      request.shortDescription,
                      style: const TextStyle(
                        color: AppColors.mediumText,
                        fontSize: AppColors.fontSizeSm,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isApproved) ...[
                      const SizedBox(height: AppColors.space16),
                      _ProgressBlock(request: request),
                    ] else ...[
                      const SizedBox(height: AppColors.space12),
                      _StatusHint(status: request.status),
                    ],
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

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.request});
  final CampaignSummary request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space12),
      decoration: BoxDecoration(
        color: AppColors.greenHope.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.greenHope.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppColors.radiusXs),
                  child: LinearProgressIndicator(
                    value: request.normalizedProgress,
                    backgroundColor: AppColors.grayLight,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.greenHope),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: AppColors.space12),
              Text(
                '${request.completionPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.greenHope,
                  fontSize: AppColors.fontSizeBase,
                  fontWeight: AppColors.fontWeightExtraBold,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.savings_rounded,
                      size: 14, color: AppColors.greenHope),
                  const SizedBox(width: 4),
                  Text(
                    'Bs ${request.raisedAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: AppColors.fontSizeSm,
                      fontWeight: AppColors.fontWeightBold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.flag_rounded,
                      size: 14, color: AppColors.mediumText),
                  const SizedBox(width: 4),
                  Text(
                    'Bs ${request.goalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.mediumText,
                      fontSize: AppColors.fontSizeSm,
                      fontWeight: AppColors.fontWeightSemiBold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusHint extends StatelessWidget {
  const _StatusHint({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    Color color;
    switch (status) {
      case 'pendiente':
        message = 'Estamos revisando tu solicitud, te avisaremos pronto.';
        icon = Icons.hourglass_top_rounded;
        color = AppColors.orangeAction;
        break;
      case 'rechazada':
        message =
            'La solicitud no fue aprobada. Revisa los datos e inténtalo de nuevo.';
        icon = Icons.info_outline_rounded;
        color = AppColors.error;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.space12, vertical: AppColors.space8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppColors.space8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
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

// ─── Status badge ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.floating = false});

  final String? status;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final data = _statusData(status);
    final bg = floating
        ? Colors.white.withValues(alpha: 0.95)
        : data.color.withValues(alpha: 0.12);
    final borderColor = data.color.withValues(alpha: floating ? 0.20 : 0.30);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.space12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: floating ? AppColors.shadowSm : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: data.color),
          const SizedBox(width: 6),
          Text(
            data.label,
            style: TextStyle(
              color: data.color,
              fontSize: AppColors.fontSizeXs,
              fontWeight: AppColors.fontWeightExtraBold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _StatusData _statusData(String? status) {
    switch (status) {
      case 'pendiente':
        return const _StatusData(
          label: 'EN REVISIÓN',
          icon: Icons.schedule_rounded,
          color: AppColors.orangeAction,
        );
      case 'aprobada':
        return const _StatusData(
          label: 'APROBADA',
          icon: Icons.check_circle_rounded,
          color: AppColors.greenHope,
        );
      case 'rechazada':
        return const _StatusData(
          label: 'RECHAZADA',
          icon: Icons.cancel_rounded,
          color: AppColors.error,
        );
      default:
        return const _StatusData(
          label: 'SIN ESTADO',
          icon: Icons.help_outline_rounded,
          color: AppColors.grayNeutral,
        );
    }
  }
}

class _StatusData {
  const _StatusData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

// ─── Error state ────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.space24),
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(AppColors.space24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            boxShadow: AppColors.shadowMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.10),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppColors.space16),
              const Text(
                'No pudimos cargar tus solicitudes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: AppColors.fontSizeLg,
                  fontWeight: AppColors.fontWeightExtraBold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppColors.space8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.mediumText,
                  fontSize: AppColors.fontSizeBase,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppColors.space20),
              AppPrimaryButton(
                label: 'Reintentar',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
