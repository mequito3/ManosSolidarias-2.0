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
      appBar: AppBar(title: const Text('Historial de donaciones')),
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.volunteer_activism_outlined,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.campaignTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Chip(
                            backgroundColor: statusColor.withValues(alpha: 0.15),
                            label: Text(
                              entry.status.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                          Chip(
                            backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.12),
                            label: Text(
                              amountText,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.bluePrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.event_outlined,
              label: 'Registrada',
              value: dateText,
            ),
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
              const SizedBox(height: 12),
              Text(
                entry.message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.75),
                  height: 1.35,
                ),
              ),
            ],
            if (entry.hasReceipt) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _openReceipt(context, entry.receiptUrl!),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Ver comprobante'),
                ),
              ),
            ],
          ],
        ),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.bluePrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.75),
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: AppColors.grayNeutral),
          const SizedBox(height: 16),
          Text(
            'Aún no registraste donaciones.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cuando registres tus aportes, podrás consultar los comprobantes y el estado de revisión aquí.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkText.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppColors.orangeAction),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              onRetry();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
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
