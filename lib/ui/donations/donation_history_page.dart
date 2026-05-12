import 'package:flutter/material.dart';
import '../../controllers/donation_history_controller.dart';
import '../../models/donation_history_entry.dart';
import '../../theme/app_colors.dart';

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
      appBar: AppBar(
        title: const Text(
          'Historial de donaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bluePrimary, AppColors.blueSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppColors.lightBackground,
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          if (controller.isLoading && controller.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null && controller.entries.isEmpty) {
            return _DonationHistoryError(
              message: controller.errorMessage!,
              onRetry: controller.refreshHistory,
            );
          }

          if (controller.entries.isEmpty) {
            return const _DonationHistoryEmpty();
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: controller.entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final entry = controller.entries[index];
                return _DonationHistoryCard(entry: entry);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DonationHistoryCard extends StatelessWidget {
  const _DonationHistoryCard({required this.entry});

  final DonationHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountText = 'Bs ${entry.amount.toStringAsFixed(2)}';
    final dateText = _formatDate(entry.createdAt);
    final validatedText = entry.validatedAt != null ? _formatDate(entry.validatedAt!) : null;
    final statusColor = _statusColor(entry.status);

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
          // Header strip with status colour
          Container(
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(color: statusColor.withValues(alpha: 0.2)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.volunteer_activism_rounded, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.campaignTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    entry.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount + date row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.bluePrimary, AppColors.blueSecondary],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        amountText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time_rounded, size: 13, color: AppColors.grayDark),
                    const SizedBox(width: 4),
                    Text(
                      dateText,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grayDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Detail rows
                if (validatedText != null)
                  _DetailRow(
                    icon: Icons.verified_outlined,
                    label: entry.status == DonationStatus.approved ? 'Aprobada' : 'Actualizada',
                    value: validatedText,
                  ),
                if (entry.method != null)
                  _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Método',
                    value: _methodLabel(entry.method!),
                  ),
                if (entry.reference != null)
                  _DetailRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Referencia',
                    value: entry.reference!,
                  ),
                if (entry.rewardTitle != null)
                  _DetailRow(
                    icon: Icons.card_giftcard_outlined,
                    label: 'Recompensa',
                    value: entry.rewardTitle!,
                  ),
                if (entry.message != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.grayLight),
                    ),
                    child: Text(
                      entry.message!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumText,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                if (entry.hasReceipt) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openReceipt(context, entry.receiptUrl!),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.bluePrimary.withValues(alpha: 0.4)),
                        foregroundColor: AppColors.bluePrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.image_search_rounded, size: 18),
                      label: const Text('Ver comprobante', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.approved:
        return AppColors.greenSuccess;
      case DonationStatus.rejected:
        return Colors.redAccent;
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
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
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
        content: Text('Este comprobante no es una imagen. Copia el enlace manualmente.'),
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: AppColors.bluePrimary),
          ),
          const SizedBox(width: 8),
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
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
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

class _DonationHistoryEmpty extends StatelessWidget {
  const _DonationHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                size: 52,
                color: AppColors.bluePrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin donaciones aún',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Cuando registres tus aportes, podrás consultar los comprobantes y el estado de revisión aquí.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationHistoryError extends StatelessWidget {
  const _DonationHistoryError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Algo salió mal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => onRetry(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Comprobante adjunto',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No pudimos cargar la imagen del comprobante.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
