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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.greenHope.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: AppColors.greenHope),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Registrada el $formattedDate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.75),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onViewDetail,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Ver detalle'),
              ),
            ),
          ],
        ),
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
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
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
    final viewInsets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: viewInsets.bottom + 24,
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

            if (snapshot.hasError) {
              return _DonationDetailError(onRetry: _retry);
            }

            final detail = snapshot.data;
            if (detail == null) {
              return _DonationDetailError(onRetry: _retry);
            }

            final isPending = detail.status.toLowerCase() == 'pendiente';

            return _DonationDetailContent(
              item: widget.item,
              detail: detail,
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
      ),
    );
  }
}

class _DonationDetailError extends StatelessWidget {
  const _DonationDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 42, color: AppColors.orangeAction),
        const SizedBox(height: 16),
        const Text(
          'No pudimos cargar el detalle de la donación.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }
}

class _DonationDetailContent extends StatelessWidget {
  const _DonationDetailContent({
    required this.item,
    required this.detail,
    this.onApprove,
    this.onReject,
    this.isProcessing = false,
    this.errorMessage,
  });

  final AdminPendingItem item;
  final AdminDonationDetail detail;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isProcessing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Admin puede ver el nombre real incluso si es anónimo
    final donorName = detail.donorName ?? detail.userId ?? 'Sin datos del donante';
    final donorLabel = detail.isAnonymous 
        ? '$donorName (Anónimo para público)'
        : donorName;
    final campaignLabel = detail.campaignTitle ?? detail.campaignId;
    final String? rewardLabel = detail.rewardTitle ?? detail.rewardId;
    final createdText = formatAdminDateTime(detail.createdAt);
    final validatedText =
        detail.validatedAt != null ? formatAdminDateTime(detail.validatedAt!) : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Donación',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registrada el $createdText',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Monto y Estado
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.greenSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.greenSuccess.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments, size: 20, color: AppColors.greenSuccess),
                          const SizedBox(width: 8),
                          const Text(
                            'Monto',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCurrency(detail.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.bluePrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fact_check, size: 20, color: AppColors.bluePrimary),
                          const SizedBox(width: 8),
                          const Text(
                            'Estado',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detail.status.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Información del donante',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Nombre', value: donorLabel),
                if (detail.donorEmail != null && detail.donorEmail!.trim().isNotEmpty)
                  _DetailRow(label: 'Email', value: detail.donorEmail!.trim()),
                if (detail.donorPhone != null && detail.donorPhone!.trim().isNotEmpty)
                  _DetailRow(label: 'Teléfono', value: detail.donorPhone!.trim()),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Información de la transacción',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Fecha y hora', value: '${createdText.split(' ')[0]} a las ${createdText.split(' ').skip(1).join(' ')}'),
                _DetailRow(label: 'Método de pago', value: detail.method.toUpperCase()),
                if (detail.bankEntity != null && detail.bankEntity!.trim().isNotEmpty)
                  _DetailRow(label: 'Banco/Entidad', value: detail.bankEntity!.trim()),
                if (detail.operationNumber != null && detail.operationNumber!.trim().isNotEmpty)
                  _DetailRow(label: 'N° Operación', value: detail.operationNumber!.trim()),
                if (detail.reference != null && detail.reference!.trim().isNotEmpty)
                  _DetailRow(label: 'Referencia', value: detail.reference!.trim()),
                if (detail.ipAddress != null && detail.ipAddress!.trim().isNotEmpty)
                  _DetailRow(label: 'IP Registro', value: detail.ipAddress!.trim()),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Información de la campaña',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Campaña', value: campaignLabel),
                if (detail.campaignStatus != null)
                  _DetailRow(label: 'Estado campaña', value: detail.campaignStatus!.toUpperCase()),
                if (rewardLabel != null)
                  _DetailRow(label: 'Recompensa', value: rewardLabel),
                if (validatedText != null)
                  _DetailRow(label: 'Validada el', value: validatedText),
              ],
            ),
          ),
          if (detail.message != null && detail.message!.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Mensaje del donante',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.bluePrimary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                detail.message!.trim(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ],
          if (detail.receiptUrl != null && detail.receiptUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Comprobante',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                detail.receiptUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text(
                          'Error al cargar imagen',
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          detail.receiptUrl!.trim(),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 24),
            if (errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.orangeAction.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.orangeAction),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: AppColors.orangeAction,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: isProcessing ? null : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Aprobar donación'),
                      content: const Text('¿Confirmas que validaste el comprobante y deseas aprobar esta donación?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Aprobar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    onApprove!();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.greenSuccess,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'Aprobar donación',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: isProcessing ? null : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Rechazar donación'),
                      content: const Text('¿Estás seguro de rechazar esta donación?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Rechazar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    onReject!();
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text(
                  'Rechazar',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            if (isProcessing) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 3),
            ],
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) => 'Bs ${value.toStringAsFixed(2)}';
