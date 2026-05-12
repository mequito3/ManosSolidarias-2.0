import 'package:flutter/material.dart';

import '../../../controllers/admin_dashboard_controller.dart';
import '../../../models/admin_dashboard.dart';
import '../../../models/admin_donation_detail.dart';
import '../../../theme/app_colors.dart';
import 'admin_section_widgets.dart';

enum DonationReviewResult {
  approved,
  rejected,
}

class DonationsSection extends StatelessWidget {
  const DonationsSection({
    super.key,
    required this.items,
    required this.onViewDetail,
  });

  final List<AdminPendingItem> items;
  final Future<void> Function(AdminPendingItem item) onViewDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionHeading(
          title: 'Donaciones por validar',
          description: 'Verifica los comprobantes y confirma las transferencias recibidas.',
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const AdminEmptyState(message: 'No hay donaciones pendientes de revisión.')
        else
          ...items.indexed.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: entry.$1 == items.length - 1 ? 0 : 14),
              child: DonationReviewCard(
                item: entry.$2,
                onViewDetail: () => onViewDetail(entry.$2),
              ),
            ),
          ),
      ],
    );
  }
}

class DonationReviewCard extends StatelessWidget {
  const DonationReviewCard({
    super.key,
    required this.item,
    required this.onViewDetail,
  });

  final AdminPendingItem item;
  final Future<void> Function() onViewDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = item.subtitle?.trim();
    final formattedDate = formatAdminDateTime(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.greenHopeDark, AppColors.greenHope],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: AppColors.grayDark),
                    const SizedBox(width: 5),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grayDark,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orangeAction.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.orangeAction.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.orangeAction,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Pendiente',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orangeAction,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumText,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onViewDetail,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.greenHope,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text(
                      'Revisar donación',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
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

Future<DonationReviewResult?> showDonationDetailSheet({
  required BuildContext context,
  required AdminPendingItem item,
  required Future<AdminDonationDetail> Function() loadDetail,
  required Future<void> Function() onApprove,
  required Future<void> Function() onReject,
}) {
  return showModalBottomSheet<DonationReviewResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _DonationDetailSheet(
      item: item,
      loadDetail: loadDetail,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}

class _DonationDetailSheet extends StatefulWidget {
  const _DonationDetailSheet({
    required this.item,
    required this.loadDetail,
    required this.onApprove,
    required this.onReject,
  });

  final AdminPendingItem item;
  final Future<AdminDonationDetail> Function() loadDetail;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  @override
  State<_DonationDetailSheet> createState() => _DonationDetailSheetState();
}

class _DonationDetailSheetState extends State<_DonationDetailSheet> {
  late Future<AdminDonationDetail> _future;
  bool _isActionInProgress = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _future = widget.loadDetail();
  }

  void _retry() {
    setState(() {
      _future = widget.loadDetail();
      _actionError = null;
    });
  }

  Future<void> _handleAction({
    required Future<void> Function() action,
    required DonationReviewResult result,
  }) async {
    if (_isActionInProgress) {
      return;
    }

    setState(() {
      _isActionInProgress = true;
      _actionError = null;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } on AdminActionException catch (error) {
      setState(() {
        _actionError = error.message;
      });
    } catch (_) {
      setState(() {
        _actionError = 'No pudimos completar la acción. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<AdminDonationDetail>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _DonationDetailError(onRetry: _retry);
              }

              final detail = snapshot.data!;
              final isPending = detail.status.toLowerCase() == 'pendiente';

              return _DonationDetailContent(
                item: widget.item,
                detail: detail,
                scrollController: scrollController,
                onApprove: isPending
                    ? () => _handleAction(
                          action: widget.onApprove,
                          result: DonationReviewResult.approved,
                        )
                    : null,
                onReject: isPending
                    ? () => _handleAction(
                          action: widget.onReject,
                          result: DonationReviewResult.rejected,
                        )
                    : null,
                isProcessing: _isActionInProgress,
                errorMessage: _actionError,
              );
            },
          ),
        );
      },
    );
  }
}

class _DonationDetailError extends StatelessWidget {
  const _DonationDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          const Text(
            'No pudimos cargar el detalle',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.darkText),
          ),
          const SizedBox(height: 6),
          const Text(
            'Revisa tu conexión e intenta nuevamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mediumText, fontSize: 14),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _DonationDetailContent extends StatelessWidget {
  const _DonationDetailContent({
    required this.item,
    required this.detail,
    required this.scrollController,
    this.onApprove,
    this.onReject,
    this.isProcessing = false,
    this.errorMessage,
  });

  final AdminPendingItem item;
  final AdminDonationDetail detail;
  final ScrollController scrollController;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isProcessing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final donorName = detail.donorName ?? detail.userId ?? 'Sin datos del donante';
    final donorLabel = detail.isAnonymous ? '$donorName (Anónimo para público)' : donorName;
    final campaignLabel = detail.campaignTitle ?? detail.campaignId;
    final String? rewardLabel = detail.rewardTitle ?? detail.rewardId;
    final createdText = formatAdminDateTime(detail.createdAt);
    final validatedText = detail.validatedAt != null ? formatAdminDateTime(detail.validatedAt!) : null;
    final isPending = detail.status.toLowerCase() == 'pendiente';
    final statusColor = isPending
        ? AppColors.orangeAction
        : (detail.status.toLowerCase() == 'aprobada'
            ? AppColors.greenSuccess
            : AppColors.error);

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      children: [
        // ── Hero header ────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.greenHopeDark, AppColors.greenHope],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount circle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatCurrency(detail.amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          campaignLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Status + date row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          detail.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.access_time_rounded, size: 13, color: Colors.white.withValues(alpha: 0.75)),
                  const SizedBox(width: 4),
                  Text(
                    createdText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Content sections ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Donor info
              _DonationSectionCard(
                icon: Icons.person_rounded,
                iconColor: AppColors.bluePrimary,
                title: 'Información del donante',
                child: Column(
                  children: [
                    _DonationInfoRow(
                      icon: Icons.badge_rounded,
                      iconColor: AppColors.bluePrimary,
                      label: 'Nombre',
                      value: donorLabel,
                    ),
                    if (detail.donorEmail != null && detail.donorEmail!.trim().isNotEmpty)
                      _DonationInfoRow(
                        icon: Icons.email_outlined,
                        iconColor: AppColors.bluePrimary,
                        label: 'Email',
                        value: detail.donorEmail!.trim(),
                      ),
                    if (detail.donorPhone != null && detail.donorPhone!.trim().isNotEmpty)
                      _DonationInfoRow(
                        icon: Icons.phone_outlined,
                        iconColor: AppColors.bluePrimary,
                        label: 'Teléfono',
                        value: detail.donorPhone!.trim(),
                        isLast: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Transaction info
              _DonationSectionCard(
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.greenSuccess,
                title: 'Información de la transacción',
                child: Column(
                  children: [
                    _DonationInfoRow(
                      icon: Icons.event_rounded,
                      iconColor: AppColors.greenSuccess,
                      label: 'Fecha y hora',
                      value: createdText,
                    ),
                    _DonationInfoRow(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.greenSuccess,
                      label: 'Método de pago',
                      value: detail.method.toUpperCase(),
                    ),
                    if (detail.bankEntity != null && detail.bankEntity!.trim().isNotEmpty)
                      _DonationInfoRow(
                        icon: Icons.account_balance_rounded,
                        iconColor: AppColors.greenSuccess,
                        label: 'Banco/Entidad',
                        value: detail.bankEntity!.trim(),
                      ),
                    if (detail.operationNumber != null && detail.operationNumber!.trim().isNotEmpty)
                      _DonationInfoRow(
                        icon: Icons.tag_rounded,
                        iconColor: AppColors.greenSuccess,
                        label: 'N° Operación',
                        value: detail.operationNumber!.trim(),
                      ),
                    if (detail.reference != null && detail.reference!.trim().isNotEmpty)
                      _DonationInfoRow(
                        icon: Icons.confirmation_number_rounded,
                        iconColor: AppColors.greenSuccess,
                        label: 'Referencia',
                        value: detail.reference!.trim(),
                      ),
                    if (detail.ipAddress != null && detail.ipAddress!.trim().isNotEmpty)
                      _DonationInfoRow(
                        icon: Icons.lan_rounded,
                        iconColor: AppColors.greenSuccess,
                        label: 'IP Registro',
                        value: detail.ipAddress!.trim(),
                        isLast: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Campaign info
              _DonationSectionCard(
                icon: Icons.campaign_rounded,
                iconColor: AppColors.orangeAction,
                title: 'Información de la campaña',
                child: Column(
                  children: [
                    _DonationInfoRow(
                      icon: Icons.volunteer_activism_rounded,
                      iconColor: AppColors.orangeAction,
                      label: 'Campaña',
                      value: campaignLabel,
                    ),
                    if (detail.campaignStatus != null)
                      _DonationInfoRow(
                        icon: Icons.circle_rounded,
                        iconColor: AppColors.orangeAction,
                        label: 'Estado campaña',
                        value: detail.campaignStatus!.toUpperCase(),
                      ),
                    if (rewardLabel != null)
                      _DonationInfoRow(
                        icon: Icons.card_giftcard_rounded,
                        iconColor: AppColors.orangeAction,
                        label: 'Recompensa',
                        value: rewardLabel,
                      ),
                    if (validatedText != null)
                      _DonationInfoRow(
                        icon: Icons.verified_rounded,
                        iconColor: AppColors.orangeAction,
                        label: 'Validada el',
                        value: validatedText,
                        isLast: true,
                      ),
                  ],
                ),
              ),

              // Message
              if (detail.message != null && detail.message!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _DonationSectionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: AppColors.blueSecondary,
                  title: 'Mensaje del donante',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      detail.message!.trim(),
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ],

              // Receipt
              if (detail.receiptUrl != null && detail.receiptUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _DonationSectionCard(
                  icon: Icons.image_rounded,
                  iconColor: AppColors.grayDark,
                  title: 'Comprobante adjunto',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      detail.receiptUrl!.trim(),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.broken_image_rounded, size: 42, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text(
                              'No se pudo cargar la imagen',
                              style: TextStyle(color: AppColors.mediumText, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              detail.receiptUrl!.trim(),
                              style: const TextStyle(color: AppColors.bluePrimary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          height: 180,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Action error
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              if (onApprove != null || onReject != null) ...[
                const SizedBox(height: 20),
                if (isProcessing)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: AppColors.greenSuccess),
                  )
                else ...[
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.greenHopeDark, AppColors.greenHope],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.greenSuccess.withValues(alpha: 0.38),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: onApprove == null
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.greenSuccess.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.check_circle_rounded, color: AppColors.greenSuccess, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(child: Text('¿Aprobar donación?')),
                                    ],
                                  ),
                                  content: const Text('Confirma que revisaste el comprobante y deseas aprobar esta donación.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: FilledButton.styleFrom(backgroundColor: AppColors.greenSuccess),
                                      child: const Text('Aprobar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) onApprove!();
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text('Aprobar donación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onReject == null
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(child: Text('¿Rechazar donación?')),
                                  ],
                                ),
                                content: const Text('Esta acción notificará al donante que su comprobante fue rechazado.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                    child: const Text('Rechazar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) onReject!();
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    label: const Text('Rechazar donación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}


class _DonationSectionCard extends StatelessWidget {
  const _DonationSectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 16, indent: 14, endIndent: 14, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _DonationInfoRow extends StatelessWidget {
  const _DonationInfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.isLast = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.bluePrimary).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: iconColor ?? AppColors.bluePrimary),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.mediumText,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 14,
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

String _formatCurrency(double value) => 'Bs ${value.toStringAsFixed(2)}';
