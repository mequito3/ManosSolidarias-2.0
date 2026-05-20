import 'package:flutter/material.dart';

import '../../controllers/donation_history_controller.dart';
import '../../models/donation_history_entry.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_network_image.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/premium_empty_state.dart';
import '../widgets/premium_hero.dart';

class DonationHistoryPage extends StatefulWidget {
  const DonationHistoryPage({super.key, required this.controller});

  final DonationHistoryController controller;

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.hasLoaded) {
      widget.controller.loadHistory();
    }
  }

  Future<void> _handleRefresh() => widget.controller.refreshHistory();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: PremiumAppBar(
        title: 'Mis donaciones',
        actions: [
          PremiumAppBarAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualizar',
            onPressed: widget.controller.isLoading ? null : _handleRefresh,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          if (controller.isLoading && controller.entries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.bluePrimary),
            );
          }

          if (controller.errorMessage != null && controller.entries.isEmpty) {
            return PremiumEmptyState(
              icon: Icons.error_outline_rounded,
              iconColor: AppColors.error,
              title: 'No pudimos cargar tu historial',
              description: controller.errorMessage!,
              blobColors: [
                AppColors.error.withValues(alpha: 0.08),
                AppColors.bluePrimary.withValues(alpha: 0.06),
              ],
              action: AppPrimaryButton(
                label: 'Reintentar',
                icon: Icons.refresh_rounded,
                onPressed: _handleRefresh,
              ),
            );
          }

          if (controller.entries.isEmpty) {
            return PremiumEmptyState(
              icon: Icons.volunteer_activism_rounded,
              iconColor: AppColors.bluePrimary,
              title: 'Sin donaciones aún',
              description:
                  'Cuando apoyes una campaña, tus aportes aparecerán acá con su estado y comprobante.',
              blobColors: [
                AppColors.bluePrimary.withValues(alpha: 0.10),
                AppColors.greenHope.withValues(alpha: 0.08),
              ],
              hintChips: const [
                PremiumHintChip(
                  icon: Icons.favorite_rounded,
                  label: 'Apoyá una causa',
                  color: AppColors.orangeAction,
                ),
                PremiumHintChip(
                  icon: Icons.receipt_long_rounded,
                  label: 'Subí el comprobante',
                  color: AppColors.bluePrimary,
                ),
              ],
            );
          }

          final entries = controller.entries;
          final totalApproved = entries
              .where((e) => e.status == DonationStatus.approved)
              .fold<double>(0, (sum, e) => sum + e.amount);
          final approvedCount =
              entries.where((e) => e.status == DonationStatus.approved).length;
          final pendingCount =
              entries.where((e) => e.status == DonationStatus.pending).length;
          final rejectedCount =
              entries.where((e) => e.status == DonationStatus.rejected).length;

          return RefreshIndicator(
            color: AppColors.bluePrimary,
            onRefresh: _handleRefresh,
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
                      icon: Icons.volunteer_activism_rounded,
                      iconGradient: AppColors.primaryGradient,
                      iconShadowColor: AppColors.bluePrimary,
                      title: entries.length == 1
                          ? 'Hiciste 1 donación'
                          : 'Hiciste ${entries.length} donaciones',
                      subtitle: 'Gracias por ser parte del cambio.',
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
                          icon: Icons.savings_rounded,
                          label: 'Total donado',
                          value: _formatCompact(totalApproved),
                          color: AppColors.greenHope,
                        ),
                        PremiumStatPill(
                          icon: Icons.check_circle_rounded,
                          label: 'Aprobadas',
                          value: '$approvedCount',
                          color: AppColors.bluePrimary,
                        ),
                        PremiumStatPill(
                          icon: pendingCount > 0
                              ? Icons.hourglass_top_rounded
                              : Icons.cancel_rounded,
                          label: pendingCount > 0
                              ? 'Pendientes'
                              : 'Rechazadas',
                          value: pendingCount > 0
                              ? '$pendingCount'
                              : '$rejectedCount',
                          color: pendingCount > 0
                              ? AppColors.orangeAction
                              : AppColors.error,
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
                      title: 'Tu historial',
                      accentGradient: AppColors.primaryGradient,
                      count: entries.length,
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
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppColors.space12),
                    itemBuilder: (context, index) =>
                        _DonationCard(entry: entries[index]),
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

String _formatCompact(double value) {
  if (value >= 1000000) return 'Bs ${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) {
    return 'Bs ${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
  }
  return 'Bs ${value.toStringAsFixed(0)}';
}

// ─── Donation card ──────────────────────────────────────────────────────────

class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.entry});

  final DonationHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(entry.status);
    final dateText = _formatDate(entry.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowMd,
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppColors.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.campaignCoverUrl != null &&
                    entry.campaignCoverUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusSm),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: AppNetworkImage(
                        url: entry.campaignCoverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: AppColors.bluePrimary.withValues(alpha: 0.10),
                          child: const Icon(Icons.campaign_rounded,
                              color: AppColors.bluePrimary, size: 22),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusSm),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: AppColors.bluePrimary, size: 22),
                  ),
                const SizedBox(width: AppColors.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.campaignTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: AppColors.fontSizeBase,
                          fontWeight: AppColors.fontWeightExtraBold,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: AppColors.lightText),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              dateText,
                              style: const TextStyle(
                                color: AppColors.lightText,
                                fontSize: AppColors.fontSizeXs,
                                fontWeight: AppColors.fontWeightSemiBold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppColors.space12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppColors.space12,
                      vertical: AppColors.space8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusRound),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.bluePrimary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Bs ${entry.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: AppColors.fontWeightExtraBold,
                      fontSize: AppColors.fontSizeBase,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const Spacer(),
                _StatusBadge(status: entry.status),
              ],
            ),
            if (_hasDetails) ...[
              const SizedBox(height: AppColors.space12),
              const Divider(height: 1, color: AppColors.grayLight),
              const SizedBox(height: AppColors.space12),
              if (entry.validatedAt != null)
                _DetailRow(
                  icon: entry.status == DonationStatus.approved
                      ? Icons.verified_rounded
                      : Icons.update_rounded,
                  label: entry.status == DonationStatus.approved
                      ? 'Aprobada'
                      : 'Actualizada',
                  value: _formatDate(entry.validatedAt!),
                ),
              if (entry.method != null)
                _DetailRow(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Método',
                  value: _methodLabel(entry.method!),
                ),
              if (entry.reference != null)
                _DetailRow(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Referencia',
                  value: entry.reference!,
                ),
              if (entry.rewardTitle != null)
                _DetailRow(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Recompensa',
                  value: entry.rewardTitle!,
                ),
            ],
            if (entry.message != null) ...[
              const SizedBox(height: AppColors.space12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppColors.space12),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  border: Border.all(color: AppColors.grayLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 14, color: AppColors.lightText),
                    const SizedBox(width: AppColors.space8),
                    Expanded(
                      child: Text(
                        entry.message!,
                        style: const TextStyle(
                          color: AppColors.mediumText,
                          fontSize: AppColors.fontSizeSm,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (entry.hasReceipt) ...[
              const SizedBox(height: AppColors.space12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openReceipt(context, entry.receiptUrl!),
                  icon: const Icon(Icons.image_search_rounded, size: 18),
                  label: const Text('Ver comprobante'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.bluePrimary,
                    side: const BorderSide(
                        color: AppColors.bluePrimary, width: 1.4),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppColors.space12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusMd),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: AppColors.fontWeightExtraBold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasDetails =>
      entry.validatedAt != null ||
      entry.method != null ||
      entry.reference != null ||
      entry.rewardTitle != null;

  static Color _statusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.approved:
        return AppColors.greenHope;
      case DonationStatus.rejected:
        return AppColors.error;
      case DonationStatus.pending:
        return AppColors.orangeAction;
    }
  }

  static String _methodLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'qr':
        return 'QR';
      case 'transferencia':
        return 'Transferencia';
      case 'otro':
      default:
        return 'Otro';
    }
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month $year · $hour:$minute';
  }

  static Future<void> _openReceipt(BuildContext context, String url) async {
    if (_isImageUrl(url)) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => _ReceiptImageDialog(imageUrl: url),
      );
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
            'Este comprobante no es una imagen. Copia el enlace manualmente.'),
      ),
    );
  }

  static bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.contains('image');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final DonationStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    late final IconData icon;
    switch (status) {
      case DonationStatus.approved:
        color = AppColors.greenHope;
        label = 'APROBADA';
        icon = Icons.check_circle_rounded;
        break;
      case DonationStatus.pending:
        color = AppColors.orangeAction;
        label = 'PENDIENTE';
        icon = Icons.hourglass_top_rounded;
        break;
      case DonationStatus.rejected:
        color = AppColors.error;
        label = 'RECHAZADA';
        icon = Icons.cancel_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.space12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.30)),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppColors.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Icon(icon, size: 14, color: AppColors.bluePrimary),
          ),
          const SizedBox(width: AppColors.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.lightText.withValues(alpha: 0.95),
                    fontSize: AppColors.fontSizeXs,
                    fontWeight: AppColors.fontWeightBold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeSm,
                    fontWeight: AppColors.fontWeightSemiBold,
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

class _ReceiptImageDialog extends StatelessWidget {
  const _ReceiptImageDialog({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppColors.space16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          child: Container(
            color: AppColors.cardBackground,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.space20,
                    AppColors.space16,
                    AppColors.space12,
                    AppColors.space12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppColors.space8),
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusSm),
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            color: AppColors.bluePrimary, size: 20),
                      ),
                      const SizedBox(width: AppColors.space12),
                      const Expanded(
                        child: Text(
                          'Comprobante adjunto',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: AppColors.fontSizeMd,
                            fontWeight: AppColors.fontWeightExtraBold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Material(
                        color: AppColors.grayLight.withValues(alpha: 0.6),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.close_rounded,
                                color: AppColors.darkText, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: AppNetworkImage(
                        url: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.bluePrimary,
                          ),
                        ),
                        errorWidget: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppColors.space24),
                            child: Text(
                              'No pudimos cargar la imagen del comprobante.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.mediumText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppColors.space16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
