import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../models/admin_dashboard.dart';
import '../../../theme/app_colors.dart';
import '../../../services/pdf_export_service.dart';
import '../../../ui/widgets/premium_hero.dart';

// Decoración compartida para todas las cards del panel: fondo blanco con
// sombra sutil (mismo lenguaje que el resto del admin).
BoxDecoration get _kCardDecoration => BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      boxShadow: AppColors.shadowSm,
    );

// Moneda compacta para que los montos grandes no se corten en cards angostas:
// Bs 900 · Bs 75K · Bs 202K · Bs 1.2M
String _compactBs(double value) {
  final v = value.abs();
  if (v >= 1000000) {
    final m = value / 1000000;
    return 'Bs ${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
  }
  if (v >= 1000) {
    final k = value / 1000;
    return 'Bs ${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
  }
  return 'Bs ${value.round()}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Main panel
// ─────────────────────────────────────────────────────────────────────────────

class AdminMetricsPanel extends StatelessWidget {
  const AdminMetricsPanel({
    super.key,
    required this.metrics,
    required this.activeCampaigns,
  });

  final AdminDashboardMetrics metrics;
  final List<AdminActiveCampaign> activeCampaigns;

  @override
  Widget build(BuildContext context) {
    final campaignsGoalTotal =
        _sum(activeCampaigns, (c) => c.goalAmount);
    final campaignsRaisedTotal =
        _sum(activeCampaigns, (c) => c.raisedAmount);
    final averageProgress = activeCampaigns.isEmpty
        ? 0.0
        : activeCampaigns.fold<double>(
                0, (sum, c) => sum + c.completionRatio) /
            activeCampaigns.length;
    final averageProgressPercent =
        _clamp(averageProgress * 100, 0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero premium con 3 stats clave ──────────────────────────────
        PremiumHero(
          icon: Icons.analytics_rounded,
          iconGradient: AppColors.primaryGradient,
          iconShadowColor: AppColors.bluePrimary,
          title: 'Panel de análisis',
          subtitle: 'Métricas y KPIs del sistema.',
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
              icon: Icons.approval_rounded,
              label: 'Aprob.',
              value: '${metrics.approvalRate.toStringAsFixed(0)}%',
              color: AppColors.greenHope,
            ),
            PremiumStatPill(
              icon: Icons.schedule_rounded,
              label: 'Respuesta',
              value:
                  '${metrics.avgResponseTimeHours.toStringAsFixed(0)} h',
              color: AppColors.bluePrimary,
            ),
            PremiumStatPill(
              icon: Icons.people_rounded,
              label: 'Donantes',
              value: '${metrics.totalDonors}',
              color: AppColors.orangeAction,
            ),
          ],
        ),
        const SizedBox(height: AppColors.space12),
        // Botón exportar a PDF (alineado a la derecha, fuera del hero)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _exportPdf(context, metrics),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('Exportar PDF'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.bluePrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppColors.space12,
                vertical: AppColors.space8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
              ),
              textStyle: const TextStyle(
                fontWeight: AppColors.fontWeightBold,
                fontSize: AppColors.fontSizeSm,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppColors.space8),

        // ── Donantes recurrentes (info contextual al donantes del hero) ──
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.space16,
            vertical: AppColors.space12,
          ),
          decoration: _kCardDecoration,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.orangeAction.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                child: const Icon(Icons.repeat_rounded,
                    color: AppColors.orangeAction, size: 16),
              ),
              const SizedBox(width: AppColors.space12),
              Expanded(
                child: Text(
                  '${metrics.repeatDonorsPercentage.toStringAsFixed(0)}% de los donantes son recurrentes',
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeSm,
                    fontWeight: AppColors.fontWeightSemiBold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppColors.space20),

        // ── Crecimiento donaciones ────────────────────────────────────────
        const _MetricsSectionLabel(label: 'Crecimiento'),
        const SizedBox(height: AppColors.space12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _GrowthCard(
                title: 'Donaciones este mes',
                currentValue: metrics.donationsThisMonth,
                previousValue: metrics.donationsLastMonth,
                growthRate: metrics.donationGrowthRate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SimpleStatCard(
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.greenSuccess,
                value: metrics.campaignsCompletedThisMonth.toString(),
                label: 'Finalizadas',
                sub: 'Este mes',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Financiero ───────────────────────────────────────────────────
        const _MetricsSectionLabel(label: 'Financiero'),
        const SizedBox(height: AppColors.space12),
        Row(
          children: [
            Expanded(
              child: _FinancialCard(
                icon: Icons.attach_money_rounded,
                label: 'Donación promedio',
                amount: metrics.avgDonationAmount,
                color: AppColors.greenSuccess,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FinancialCard(
                icon: Icons.volunteer_activism_rounded,
                label: 'Total aprobado',
                amount: metrics.totalApprovedAmount,
                color: AppColors.bluePrimary,
              ),
            ),
          ],
        ),

        // ── Campañas activas ─────────────────────────────────────────────
        if (activeCampaigns.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _MetricsSectionLabel(label: 'Campañas activas'),
          const SizedBox(height: AppColors.space12),
          Row(
            children: [
              Expanded(
                child: _SimpleStatCard(
                  icon: Icons.campaign_rounded,
                  iconColor: AppColors.bluePrimary,
                  value: metrics.activeCampaigns.toString(),
                  label: 'Activas',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SimpleStatCard(
                  icon: Icons.flag_rounded,
                  iconColor: AppColors.orangeAction,
                  value: _formatCurrency(campaignsGoalTotal),
                  label: 'Meta total',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SimpleStatCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.greenHope,
                  value: _formatCurrency(campaignsRaisedTotal),
                  label: 'Recaudado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressCard(progressPercent: averageProgressPercent),
        ],

        const SizedBox(height: 16),

        // ── Tareas pendientes ────────────────────────────────────────────
        _pendingHeader(metrics),
        const SizedBox(height: AppColors.space12),
        Row(
          children: [
            Expanded(
              child: _PendingCard(
                icon: Icons.campaign_rounded,
                iconColor: AppColors.orangeAction,
                count: metrics.pendingRequests + metrics.pendingOrganizations,
                label: 'Solicitudes',
                sub: 'Campañas y orgs',
              ),
            ),
            const SizedBox(width: AppColors.space12),
            Expanded(
              child: _PendingCard(
                icon: Icons.volunteer_activism_rounded,
                iconColor: AppColors.greenSuccess,
                count: metrics.pendingDonations,
                label: 'Donaciones',
                sub: 'Por verificar',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pendingHeader(AdminDashboardMetrics m) {
    final total =
        m.pendingRequests + m.pendingDonations + m.pendingOrganizations;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.orangeAction,
            borderRadius: BorderRadius.circular(AppColors.radiusXs),
          ),
        ),
        const SizedBox(width: AppColors.space8),
        const Text(
          'Tareas pendientes',
          style: TextStyle(
            fontWeight: AppColors.fontWeightExtraBold,
            color: AppColors.darkText,
            fontSize: AppColors.fontSizeMd,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (total > 0)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppColors.space12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orangeAction.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
            ),
            child: Text(
              '$total',
              style: const TextStyle(
                fontSize: AppColors.fontSizeSm,
                fontWeight: AppColors.fontWeightExtraBold,
                color: AppColors.orangeAction,
                letterSpacing: 0.3,
              ),
            ),
          ),
      ],
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────
  static double _sum(List<AdminActiveCampaign> list,
      double Function(AdminActiveCampaign) fn) {
    double t = 0;
    for (final c in list) t += fn(c);
    return t;
  }

  static double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  static String _formatCurrency(double value) => _compactBs(value);

  // ── PDF export ──────────────────────────────────────────────────────────
  static void _exportPdf(
      BuildContext context, AdminDashboardMetrics metrics) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando PDF...'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final bytes = await PdfExportService.buildMetricsPdf(metrics: metrics);
      if (!context.mounted) return;
      Navigator.pop(context); // cierra el loading
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _PdfViewerScreen(bytes: bytes)),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error al generar PDF: $e')),
            ]),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visor del PDF dentro de la app (muestra el reporte; el botón de descargar/
// compartir vive en la barra del propio visor).
// ─────────────────────────────────────────────────────────────────────────────

class _PdfViewerScreen extends StatelessWidget {
  const _PdfViewerScreen({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        title: const Text(
          'Reporte de métricas',
          style: TextStyle(
            fontWeight: AppColors.fontWeightExtraBold,
            fontSize: AppColors.fontSizeMd,
          ),
        ),
      ),
      body: PdfPreview(
        build: (format) => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: PdfExportService.fileName(),
        pdfPreviewPageDecoration: const BoxDecoration(
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _MetricsSectionLabel extends StatelessWidget {
  const _MetricsSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusXs),
          ),
        ),
        const SizedBox(width: AppColors.space8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: AppColors.fontWeightExtraBold,
            color: AppColors.darkText,
            fontSize: AppColors.fontSizeMd,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// KPI card (eliminado — los KPIs ahora viven en el PremiumHero arriba)
// ignore: unused_element
class _KpiCardLegacyKept extends StatelessWidget {
  const _KpiCardLegacyKept();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─────────────────────────────────────────────────────────────────────────────
// Growth card
// ─────────────────────────────────────────────────────────────────────────────

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({
    required this.title,
    required this.currentValue,
    required this.previousValue,
    required this.growthRate,
  });

  final String title;
  final int currentValue;
  final int previousValue;
  final double growthRate;

  @override
  Widget build(BuildContext context) {
    final isPos = growthRate >= 0;
    final color = isPos ? AppColors.greenSuccess : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: _kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: AppColors.fontSizeXs,
                    color: AppColors.mediumText,
                    fontWeight: AppColors.fontWeightSemiBold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: AppColors.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.space8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppColors.radiusRound),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        isPos
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 11,
                        color: color),
                    const SizedBox(width: 2),
                    Text(
                      '${growthRate.abs().toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: AppColors.fontSizeXs,
                        fontWeight: AppColors.fontWeightExtraBold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentValue.toString(),
                style: const TextStyle(
                  fontSize: AppColors.fontSize2xl,
                  fontWeight: AppColors.fontWeightExtraBold,
                  color: AppColors.darkText,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'vs $previousValue',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(
                      fontSize: AppColors.fontSizeXs,
                      color: AppColors.mediumText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple stat card
// ─────────────────────────────────────────────────────────────────────────────

class _SimpleStatCard extends StatelessWidget {
  const _SimpleStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: _kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space12),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppColors.fontSizeXl,
              fontWeight: AppColors.fontWeightExtraBold,
              color: AppColors.darkText,
              letterSpacing: -0.4,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppColors.fontSizeXs,
              color: AppColors.mediumText,
              fontWeight: AppColors.fontWeightSemiBold,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: TextStyle(
                fontSize: AppColors.fontSizeXs,
                color: AppColors.mediumText.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Financial card
// ─────────────────────────────────────────────────────────────────────────────

class _FinancialCard extends StatelessWidget {
  const _FinancialCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: _kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: AppColors.space12),
          Text(
            _fmt(amount),
            style: const TextStyle(
              fontSize: AppColors.fontSizeLg,
              fontWeight: AppColors.fontWeightExtraBold,
              color: AppColors.darkText,
              letterSpacing: -0.4,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppColors.fontSizeXs,
              color: AppColors.mediumText,
              fontWeight: AppColors.fontWeightSemiBold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => _compactBs(v);
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress card
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progressPercent});
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    final pct = progressPercent.clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: _kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progreso promedio',
                  style: TextStyle(
                    fontSize: AppColors.fontSizeSm,
                    fontWeight: AppColors.fontWeightSemiBold,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: AppColors.fontSizeLg,
                  fontWeight: AppColors.fontWeightExtraBold,
                  color: AppColors.greenSuccess,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radiusXs),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor:
                  AppColors.greenSuccess.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.greenSuccess),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppColors.space8),
          const Text(
            'Avance de todas las campañas activas',
            style: TextStyle(
                fontSize: AppColors.fontSizeXs,
                color: AppColors.mediumText),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending task card
// ─────────────────────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
    this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final int count;
  final String label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final isEmpty = count == 0;
    final isUrgent = count > 5;
    final displayColor = isEmpty ? AppColors.mediumText : iconColor;

    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        boxShadow: AppColors.shadowSm,
        border: isUrgent
            ? Border.all(
                color: AppColors.error.withValues(alpha: 0.45),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                child: Icon(icon, size: 14, color: displayColor),
              ),
              const Spacer(),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppColors.space8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppColors.radiusRound),
                  ),
                  child: const Text(
                    'URGENTE',
                    style: TextStyle(
                      fontSize: AppColors.fontSizeXs,
                      fontWeight: AppColors.fontWeightExtraBold,
                      color: AppColors.error,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppColors.space12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: AppColors.fontSize2xl,
              fontWeight: AppColors.fontWeightExtraBold,
              color: isEmpty
                  ? AppColors.mediumText.withValues(alpha: 0.55)
                  : AppColors.darkText,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppColors.fontSizeSm,
              color: AppColors.darkText,
              fontWeight: AppColors.fontWeightBold,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: const TextStyle(
                fontSize: AppColors.fontSizeXs,
                color: AppColors.mediumText,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF export preview screen
// ─────────────────────────────────────────────────────────────────────────────

class _ExportPreviewScreen extends StatefulWidget {
  const _ExportPreviewScreen({
    required this.metrics,
    required this.activeCampaigns,
  });

  final AdminDashboardMetrics metrics;
  final List<AdminActiveCampaign> activeCampaigns;

  @override
  State<_ExportPreviewScreen> createState() => _ExportPreviewScreenState();
}

class _ExportPreviewScreenState extends State<_ExportPreviewScreen> {
  String _selectedFormat = 'PDF';
  bool _includeCharts = true;
  bool _includeCampaignDetails = true;
  bool _includeComparisons = true;

  @override
  Widget build(BuildContext context) {
    final campaignsGoalTotal =
        _sum(widget.activeCampaigns, (c) => c.goalAmount);
    final campaignsRaisedTotal =
        _sum(widget.activeCampaigns, (c) => c.raisedAmount);
    final averageProgress = widget.activeCampaigns.isEmpty
        ? 0.0
        : widget.activeCampaigns.fold<double>(
                0, (sum, c) => sum + c.completionRatio) /
            widget.activeCampaigns.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Previsualización del Reporte',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Revisa antes de exportar',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Información',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Row(children: [
                  Icon(Icons.info_rounded, color: AppColors.bluePrimary),
                  SizedBox(width: 12),
                  Text('Acerca del reporte'),
                ]),
                content: const Text(
                  'Este reporte incluye todas las métricas y KPIs del panel '
                  'de análisis. Puedes personalizar el contenido antes de exportar.',
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendido')),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Config panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusSm),
                      ),
                      child: const Icon(Icons.settings_rounded,
                          size: 14, color: AppColors.bluePrimary),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Configuración de exportación',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _FormatChip(
                      label: 'PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      color: AppColors.error,
                      isSelected: _selectedFormat == 'PDF',
                      onTap: () =>
                          setState(() => _selectedFormat = 'PDF'),
                    ),
                    const SizedBox(width: 8),
                    _FormatChip(
                      label: 'Excel',
                      icon: Icons.table_chart_rounded,
                      color: AppColors.greenSuccess,
                      isSelected: _selectedFormat == 'Excel',
                      onTap: () =>
                          setState(() => _selectedFormat = 'Excel'),
                    ),
                    const SizedBox(width: 8),
                    _FormatChip(
                      label: 'CSV',
                      icon: Icons.code_rounded,
                      color: AppColors.bluePrimary,
                      isSelected: _selectedFormat == 'CSV',
                      onTap: () =>
                          setState(() => _selectedFormat = 'CSV'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Incluir en el reporte:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mediumText,
                  ),
                ),
                const SizedBox(height: 6),
                _OptionSwitch(
                  label: 'Gráficos y visualizaciones',
                  value: _includeCharts,
                  enabled: _selectedFormat == 'PDF',
                  onChanged: (v) => setState(() => _includeCharts = v),
                ),
                _OptionSwitch(
                  label: 'Detalles de campañas activas',
                  value: _includeCampaignDetails,
                  onChanged: (v) =>
                      setState(() => _includeCampaignDetails = v),
                ),
                _OptionSwitch(
                  label: 'Comparaciones y tendencias',
                  value: _includeComparisons,
                  onChanged: (v) =>
                      setState(() => _includeComparisons = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),

          // Preview content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppColors.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(
                                AppColors.radiusMd),
                          ),
                          child: const Icon(Icons.analytics_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reporte de Métricas',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Generado: ${_formatDate(DateTime.now())}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mediumText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Executive summary
                    _SectionTitle(
                        icon: Icons.summarize_rounded,
                        title: 'Resumen Ejecutivo',
                        color: AppColors.bluePrimary),
                    const SizedBox(height: 14),
                    _PreviewMetricRow(
                        label: 'Total de Donantes',
                        value: widget.metrics.totalDonors.toString(),
                        icon: Icons.people_rounded,
                        color: AppColors.bluePrimary),
                    _PreviewMetricRow(
                        label: 'Campañas Activas',
                        value:
                            widget.metrics.activeCampaigns.toString(),
                        icon: Icons.campaign_rounded,
                        color: AppColors.greenSuccess),
                    _PreviewMetricRow(
                        label: 'Total Recaudado',
                        value: _formatCurrency(campaignsRaisedTotal),
                        icon: Icons.attach_money_rounded,
                        color: AppColors.orangeAction),
                    _PreviewMetricRow(
                        label: 'Campañas Completadas',
                        value: widget.metrics.campaignsCompletedThisMonth
                            .toString(),
                        icon: Icons.check_circle_rounded,
                        color: AppColors.greenSuccess),

                    const SizedBox(height: 20),

                    // KPIs
                    _SectionTitle(
                        icon: Icons.speed_rounded,
                        title: 'Indicadores Clave (KPIs)',
                        color: AppColors.orangeAction),
                    const SizedBox(height: 14),
                    _PreviewMetricRow(
                        label: 'Progreso Promedio',
                        value:
                            '${(averageProgress * 100).toStringAsFixed(1)}%',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.greenSuccess),
                    _PreviewMetricRow(
                        label: 'Meta Total',
                        value: _formatCurrency(campaignsGoalTotal),
                        icon: Icons.flag_rounded,
                        color: AppColors.bluePrimary),
                    _PreviewMetricRow(
                        label: 'Tasa de Aprobación',
                        value:
                            '${widget.metrics.approvalRate.toStringAsFixed(1)}%',
                        icon: Icons.analytics_rounded,
                        color: AppColors.orangeAction),

                    if (_includeCampaignDetails) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(
                          icon: Icons.list_alt_rounded,
                          title: 'Campañas Activas',
                          color: AppColors.greenSuccess),
                      const SizedBox(height: 12),
                      if (widget.activeCampaigns.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No hay campañas activas',
                                style: TextStyle(
                                    color: AppColors.mediumText,
                                    fontSize: 14)),
                          ),
                        )
                      else ...[
                        ...widget.activeCampaigns.take(5).map((c) =>
                            Container(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(
                                    AppColors.radiusMd),
                                border: Border.all(
                                    color: AppColors.dividerColor
                                        .withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.greenSuccess
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.campaign_rounded,
                                        size: 16,
                                        color: AppColors.greenSuccess),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.title,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.darkText,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.greenSuccess
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${(c.completionRatio * 100).toStringAsFixed(0)}%',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.greenSuccess,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${_formatCurrency(c.raisedAmount)} / ${_formatCurrency(c.goalAmount)}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.mediumText),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        if (widget.activeCampaigns.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '+ ${widget.activeCampaigns.length - 5} campañas más',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mediumText,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ],

                    if (_includeComparisons) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(
                          icon: Icons.compare_arrows_rounded,
                          title: 'Análisis Comparativo',
                          color: AppColors.bluePrimary),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary
                              .withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(
                              AppColors.radiusMd),
                          border: Border.all(
                              color: AppColors.bluePrimary
                                  .withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          children: [
                            _ComparisonRow(
                              label: 'Solicitudes Pendientes',
                              value: widget.metrics.pendingRequests,
                              total: widget.metrics.pendingRequests +
                                  widget.metrics.activeCampaigns,
                            ),
                            const SizedBox(height: 12),
                            _ComparisonRow(
                              label: 'Donaciones Este Mes',
                              value: widget.metrics.donationsThisMonth,
                              total:
                                  widget.metrics.donationsThisMonth +
                                      widget.metrics.donationsLastMonth,
                            ),
                            const SizedBox(height: 12),
                            _ComparisonRow(
                              label: 'Organizaciones Pendientes',
                              value:
                                  widget.metrics.pendingOrganizations,
                              total:
                                  widget.metrics.pendingOrganizations +
                                      widget.metrics.activeCampaigns,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 14, color: AppColors.bluePrimary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Reporte generado automáticamente por Manos Solidarias',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.mediumText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                      color: AppColors.dividerColor.withValues(alpha: 0.8),
                      width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusMd)),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showExportProgress(context, _selectedFormat);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusMd)),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  'Exportar $_selectedFormat',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportProgress(BuildContext context, String format) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Exportando reporte como $format...',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text('Por favor espera',
                style:
                    TextStyle(fontSize: 12, color: AppColors.mediumText)),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Reporte exportado como $format')),
          ]),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  static double _sum(List<AdminActiveCampaign> list,
      double Function(AdminActiveCampaign) fn) {
    double t = 0;
    for (final c in list) t += fn(c);
    return t;
  }

  static String _formatCurrency(double v) {
    final s = v.round().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return 'Bs $s';
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Format chip
// ─────────────────────────────────────────────────────────────────────────────

class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            border: Border.all(
              color: isSelected ? color : AppColors.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? color : AppColors.grayDark,
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: isSelected ? color : AppColors.grayDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Option switch
// ─────────────────────────────────────────────────────────────────────────────

class _OptionSwitch extends StatelessWidget {
  const _OptionSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: enabled ? AppColors.darkText : AppColors.mediumText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.bluePrimary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title (used inside preview)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview metric row
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewMetricRow extends StatelessWidget {
  const _PreviewMetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comparison row
// ─────────────────────────────────────────────────────────────────────────────

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.value,
    required this.total,
  });

  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct =
        total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600)),
            Text(
              '$value ($pct%)',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluePrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? value / total : 0,
            backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.bluePrimary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
