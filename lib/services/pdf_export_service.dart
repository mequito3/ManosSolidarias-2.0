import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/admin_dashboard.dart';

/// Genera el reporte de métricas en PDF.
///
/// Importante (escala): todas las cifras provienen de agregados que el RPC
/// `get_admin_dashboard_metrics` calcula en el servidor. NO se suman listas
/// en el cliente — la lista de campañas que llega al dashboard está limitada
/// a 6 registros (solo muestra visual), así que sumarla daría totales falsos
/// cuando haya miles de campañas.
class PdfExportService {
	static final PdfColor _blue = PdfColor.fromHex('#2E86AB');
	static final PdfColor _orange = PdfColor.fromHex('#F28E2C');
	static final PdfColor _green = PdfColor.fromHex('#4CAF50');
	static final PdfColor _greenDark = PdfColor.fromHex('#28A745');
	static final PdfColor _ink = PdfColor.fromHex('#2C3E50');
	static final PdfColor _muted = PdfColor.fromHex('#6B7B8C');
	static final PdfColor _line = PdfColor.fromHex('#E3E8EE');
	static final PdfColor _surface = PdfColor.fromHex('#F8F9FA');

	static Future<Uint8List> buildMetricsPdf({
		required AdminDashboardMetrics metrics,
	}) async {
		final pdf = pw.Document();
		final pendingSolicitudes =
				metrics.pendingRequests + metrics.pendingOrganizations;

		pdf.addPage(
			pw.MultiPage(
				pageFormat: PdfPageFormat.a4,
				margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 44),
				footer: _footer,
				build: (context) => [
					_letterhead(),
					pw.SizedBox(height: 22),

					_sectionTitle('Resumen ejecutivo', _blue),
					pw.SizedBox(height: 10),
					_execSummary(metrics, pendingSolicitudes),
					pw.SizedBox(height: 20),

					// KPIs (todos agregados del servidor)
					pw.Row(
						children: [
							_kpiCard('Donantes', '${metrics.totalDonors}', _blue),
							pw.SizedBox(width: 10),
							_kpiCard('Recaudado',
									_compactBs(metrics.totalApprovedAmount), _greenDark),
							pw.SizedBox(width: 10),
							_kpiCard('Aprobación',
									'${metrics.approvalRate.toStringAsFixed(0)}%', _green),
							pw.SizedBox(width: 10),
							_kpiCard('Campañas activas', '${metrics.activeCampaigns}',
									_orange),
						],
					),
					pw.SizedBox(height: 24),

					// Desempeño (porcentajes -> barras). Solo métricas que el
					// servidor entrega como % real, no promedios sobre la muestra.
					_sectionTitle('Indicadores de desempeño', _green),
					pw.SizedBox(height: 12),
					_panel([
						_bar('Tasa de aprobación de solicitudes',
								metrics.approvalRate, _green),
						_bar('Donantes recurrentes',
								metrics.repeatDonorsPercentage, _orange),
					], gap: 14),
					pw.SizedBox(height: 24),

					// Donaciones del mes
					_sectionTitle('Donaciones del mes', _orange),
					pw.SizedBox(height: 12),
					_growthChart(metrics),
					pw.SizedBox(height: 24),

					// Resumen general (agregados acumulados)
					_sectionTitle('Resumen general', _blue),
					pw.SizedBox(height: 12),
					_panel([
						_metricRow('Total recaudado (acumulado)',
								_formatCurrency(metrics.totalApprovedAmount), _greenDark),
						_metricRow('Donación promedio',
								_formatCurrency(metrics.avgDonationAmount), _ink),
						_metricRow('Tiempo promedio de respuesta',
								'${metrics.avgResponseTimeHours.toStringAsFixed(0)} h', _blue),
						_metricRow('Campañas completadas este mes',
								'${metrics.campaignsCompletedThisMonth}', _green),
						_metricRow('Categoría más popular',
								_orEmpty(metrics.topCampaignCategory), _orange),
					]),
					pw.SizedBox(height: 24),

					// Pendientes (operación)
					_sectionTitle('Tareas pendientes', _orange),
					pw.SizedBox(height: 12),
					pw.Row(
						crossAxisAlignment: pw.CrossAxisAlignment.start,
						children: [
							_pendingCard('Solicitudes', '$pendingSolicitudes',
									'Campañas y organizaciones', _orange),
							pw.SizedBox(width: 10),
							_pendingCard('Donaciones', '${metrics.pendingDonations}',
									'Por verificar', _greenDark),
						],
					),
				],
			),
		);

		return pdf.save();
	}

	static String fileName() =>
			'Manos_Solidarias_Reporte_${_fileStamp(DateTime.now())}.pdf';

	// ── Membrete ─────────────────────────────────────────────────────────────────
	static pw.Widget _letterhead() {
		return pw.Container(
			padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 20),
			decoration: pw.BoxDecoration(
				color: _blue,
				borderRadius: pw.BorderRadius.circular(14),
			),
			child: pw.Row(
				crossAxisAlignment: pw.CrossAxisAlignment.center,
				children: [
					pw.Container(
						width: 46,
						height: 46,
						decoration: pw.BoxDecoration(
							color: PdfColors.white,
							borderRadius: pw.BorderRadius.circular(12),
						),
						alignment: pw.Alignment.center,
						child: pw.Text('MS',
								style: pw.TextStyle(
									fontSize: 20,
									fontWeight: pw.FontWeight.bold,
									color: _blue,
								)),
					),
					pw.SizedBox(width: 14),
					pw.Expanded(
						child: pw.Column(
							crossAxisAlignment: pw.CrossAxisAlignment.start,
							children: [
								pw.Text('Manos Solidarias',
										style: pw.TextStyle(
											fontSize: 19,
											fontWeight: pw.FontWeight.bold,
											color: PdfColors.white,
											letterSpacing: 0.2,
										)),
								pw.SizedBox(height: 2),
								pw.Text('Reporte de métricas · Datos acumulados a la fecha',
										style: pw.TextStyle(
											fontSize: 10.5,
											color: PdfColor.fromHex('#D6E6EF'),
										)),
							],
						),
					),
					pw.Column(
						crossAxisAlignment: pw.CrossAxisAlignment.end,
						children: [
							pw.Text('GENERADO',
									style: pw.TextStyle(
										fontSize: 8,
										color: PdfColor.fromHex('#BCD6E5'),
										letterSpacing: 1.2,
									)),
							pw.SizedBox(height: 3),
							pw.Text(_formatDate(DateTime.now()),
									style: pw.TextStyle(
										fontSize: 11,
										fontWeight: pw.FontWeight.bold,
										color: PdfColors.white,
									)),
						],
					),
				],
			),
		);
	}

	// ── Resumen ejecutivo ──────────────────────────────────────────────────────────
	static pw.Widget _execSummary(AdminDashboardMetrics m, int pendingSolicitudes) {
		final growthWord =
				m.donationGrowthRate >= 0 ? 'crecieron' : 'disminuyeron';
		final category = (m.topCampaignCategory.trim().isEmpty)
				? 'sin datos suficientes'
				: m.topCampaignCategory.trim();
		final text =
				'A la fecha se registran ${m.totalDonors} donantes únicos y '
				'${m.activeCampaigns} campañas activas, con un total recaudado de '
				'${_formatCurrency(m.totalApprovedAmount)}. La tasa de aprobación de '
				'solicitudes es del ${m.approvalRate.toStringAsFixed(0)}%, con un tiempo '
				'promedio de respuesta de ${m.avgResponseTimeHours.toStringAsFixed(0)} '
				'horas. En el último mes las donaciones $growthWord un '
				'${m.donationGrowthRate.abs().toStringAsFixed(0)}% respecto al mes '
				'anterior. La categoría con más campañas es $category. Quedan '
				'$pendingSolicitudes solicitudes y ${m.pendingDonations} donaciones '
				'pendientes de revisión.';
		return pw.Container(
			decoration: pw.BoxDecoration(
				color: _surface,
				borderRadius: pw.BorderRadius.circular(10),
				border: pw.Border.all(color: _line, width: 1),
			),
			child: pw.Row(
				crossAxisAlignment: pw.CrossAxisAlignment.start,
				children: [
					pw.Container(
						width: 4,
						height: 70,
						decoration: pw.BoxDecoration(
							color: _blue,
							borderRadius: const pw.BorderRadius.only(
								topLeft: pw.Radius.circular(10),
								bottomLeft: pw.Radius.circular(10),
							),
						),
					),
					pw.Expanded(
						child: pw.Padding(
							padding: const pw.EdgeInsets.all(14),
							child: pw.Text(text,
									style: pw.TextStyle(
										fontSize: 11,
										color: _ink,
										lineSpacing: 3.5,
									)),
						),
					),
				],
			),
		);
	}

	// ── Footer ────────────────────────────────────────────────────────────────────
	static pw.Widget _footer(pw.Context context) {
		return pw.Container(
			margin: const pw.EdgeInsets.only(top: 10),
			padding: const pw.EdgeInsets.only(top: 8),
			decoration: pw.BoxDecoration(
				border: pw.Border(top: pw.BorderSide(color: _line, width: 1)),
			),
			child: pw.Row(
				mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
				children: [
					pw.Text('Manos Solidarias © ${DateTime.now().year}',
							style: pw.TextStyle(fontSize: 9, color: _muted)),
					pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
							style: pw.TextStyle(fontSize: 9, color: _muted)),
				],
			),
		);
	}

	// ── Título de sección ──────────────────────────────────────────────────────────
	static pw.Widget _sectionTitle(String title, PdfColor color) {
		return pw.Row(
			children: [
				pw.Container(
					width: 4,
					height: 16,
					decoration: pw.BoxDecoration(
						color: color,
						borderRadius: pw.BorderRadius.circular(2),
					),
				),
				pw.SizedBox(width: 8),
				pw.Text(title,
						style: pw.TextStyle(
							fontSize: 14,
							fontWeight: pw.FontWeight.bold,
							color: _ink,
							letterSpacing: 0.2,
						)),
			],
		);
	}

	// ── KPI ─────────────────────────────────────────────────────────────────────────
	static pw.Widget _kpiCard(String label, String value, PdfColor color) {
		return pw.Expanded(
			child: pw.Container(
				padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 14),
				decoration: pw.BoxDecoration(
					color: _surface,
					borderRadius: pw.BorderRadius.circular(10),
					border: pw.Border.all(color: _line, width: 1),
				),
				child: pw.Column(
					crossAxisAlignment: pw.CrossAxisAlignment.start,
					children: [
						pw.Container(
							width: 22,
							height: 4,
							decoration: pw.BoxDecoration(
								color: color,
								borderRadius: pw.BorderRadius.circular(2),
							),
						),
						pw.SizedBox(height: 10),
						pw.Text(value,
								style: pw.TextStyle(
									fontSize: 18,
									fontWeight: pw.FontWeight.bold,
									color: _ink,
								)),
						pw.SizedBox(height: 3),
						pw.Text(label,
								style: pw.TextStyle(fontSize: 9, color: _muted)),
					],
				),
			),
		);
	}

	// ── Pendientes ────────────────────────────────────────────────────────────────
	static pw.Widget _pendingCard(
			String label, String value, String sub, PdfColor color) {
		return pw.Expanded(
			child: pw.Container(
				padding: const pw.EdgeInsets.all(14),
				decoration: pw.BoxDecoration(
					color: PdfColors.white,
					borderRadius: pw.BorderRadius.circular(10),
					border: pw.Border.all(color: _line, width: 1),
				),
				child: pw.Row(
					children: [
						pw.Text(value,
								style: pw.TextStyle(
									fontSize: 26,
									fontWeight: pw.FontWeight.bold,
									color: color,
								)),
						pw.SizedBox(width: 12),
						pw.Expanded(
							child: pw.Column(
								crossAxisAlignment: pw.CrossAxisAlignment.start,
								children: [
									pw.Text(label,
											style: pw.TextStyle(
												fontSize: 12,
												fontWeight: pw.FontWeight.bold,
												color: _ink,
											)),
									pw.SizedBox(height: 2),
									pw.Text(sub,
											style: pw.TextStyle(fontSize: 9, color: _muted)),
								],
							),
						),
					],
				),
			),
		);
	}

	// ── Panel de filas ────────────────────────────────────────────────────────────
	static pw.Widget _panel(List<pw.Widget> rows, {double? gap}) {
		final children = <pw.Widget>[];
		for (var i = 0; i < rows.length; i++) {
			if (i > 0) {
				children.add(gap != null
						? pw.SizedBox(height: gap)
						: pw.Divider(height: 1, thickness: 0.6, color: _line));
			}
			children.add(rows[i]);
		}
		return pw.Container(
			padding:
					pw.EdgeInsets.symmetric(horizontal: 16, vertical: gap != null ? 16 : 4),
			decoration: pw.BoxDecoration(
				color: _surface,
				borderRadius: pw.BorderRadius.circular(10),
				border: pw.Border.all(color: _line, width: 1),
			),
			child: pw.Column(children: children),
		);
	}

	static pw.Widget _metricRow(String label, String value, PdfColor color) {
		return pw.Padding(
			padding: const pw.EdgeInsets.symmetric(vertical: 9),
			child: pw.Row(
				mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
				crossAxisAlignment: pw.CrossAxisAlignment.start,
				children: [
					pw.Expanded(
						child: pw.Text(label,
								style: pw.TextStyle(fontSize: 11, color: _ink)),
					),
					pw.SizedBox(width: 12),
					pw.Text(value,
							style: pw.TextStyle(
								fontSize: 11.5,
								fontWeight: pw.FontWeight.bold,
								color: color,
							)),
				],
			),
		);
	}

	// ── Barra horizontal de porcentaje ────────────────────────────────────────────
	static pw.Widget _bar(String label, double pct, PdfColor color) {
		final filled = pct.round().clamp(0, 100);
		final empty = 100 - filled;
		return pw.Column(
			crossAxisAlignment: pw.CrossAxisAlignment.start,
			children: [
				pw.Row(
					mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
					children: [
						pw.Expanded(
							child: pw.Text(label,
									style: pw.TextStyle(fontSize: 10, color: _ink)),
						),
						pw.SizedBox(width: 10),
						pw.Text('${pct.toStringAsFixed(0)}%',
								style: pw.TextStyle(
									fontSize: 10,
									fontWeight: pw.FontWeight.bold,
									color: color,
								)),
					],
				),
				pw.SizedBox(height: 5),
				pw.Container(
					height: 9,
					decoration: pw.BoxDecoration(
						color: _line,
						borderRadius: pw.BorderRadius.circular(5),
					),
					child: pw.Row(
						children: [
							if (filled > 0)
								pw.Expanded(
									flex: filled,
									child: pw.Container(
										decoration: pw.BoxDecoration(
											color: color,
											borderRadius: pw.BorderRadius.circular(5),
										),
									),
								),
							if (empty > 0) pw.Expanded(flex: empty, child: pw.SizedBox()),
						],
					),
				),
			],
		);
	}

	// ── Gráfico de crecimiento de donaciones ─────────────────────────────────────
	static pw.Widget _growthChart(AdminDashboardMetrics m) {
		final maxV = [m.donationsThisMonth, m.donationsLastMonth, 1]
				.reduce((a, b) => a > b ? a : b);
		final up = m.donationGrowthRate >= 0;
		return pw.Container(
			padding: const pw.EdgeInsets.all(16),
			decoration: pw.BoxDecoration(
				color: _surface,
				borderRadius: pw.BorderRadius.circular(10),
				border: pw.Border.all(color: _line, width: 1),
			),
			child: pw.Column(
				children: [
					_growthBar('Este mes', m.donationsThisMonth, maxV, _green),
					pw.SizedBox(height: 12),
					_growthBar('Mes anterior', m.donationsLastMonth, maxV, _muted),
					pw.SizedBox(height: 14),
					pw.Container(
						padding:
								const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
						decoration: pw.BoxDecoration(
							color: up
									? PdfColor.fromHex('#E8F5E9')
									: PdfColor.fromHex('#FDECEA'),
							borderRadius: pw.BorderRadius.circular(20),
						),
						child: pw.Text(
							'${up ? '+' : '-'}${m.donationGrowthRate.abs().toStringAsFixed(1)}% ${up ? 'de crecimiento' : 'de caída'} vs. mes anterior',
							style: pw.TextStyle(
								fontSize: 10,
								fontWeight: pw.FontWeight.bold,
								color: up ? _greenDark : PdfColors.red700,
							),
						),
					),
				],
			),
		);
	}

	static pw.Widget _growthBar(String label, int value, int maxV, PdfColor color) {
		final filled = maxV <= 0 ? 0 : (value / maxV * 100).round().clamp(0, 100);
		final empty = 100 - filled;
		return pw.Row(
			children: [
				pw.SizedBox(
					width: 76,
					child: pw.Text(label,
							style: pw.TextStyle(fontSize: 10, color: _ink)),
				),
				pw.Expanded(
					child: pw.Container(
						height: 16,
						decoration: pw.BoxDecoration(
							color: _line,
							borderRadius: pw.BorderRadius.circular(4),
						),
						child: pw.Row(
							children: [
								if (filled > 0)
									pw.Expanded(
										flex: filled,
										child: pw.Container(
											decoration: pw.BoxDecoration(
												color: color,
												borderRadius: pw.BorderRadius.circular(4),
											),
										),
									),
								if (empty > 0)
									pw.Expanded(flex: empty, child: pw.SizedBox()),
							],
						),
					),
				),
				pw.SizedBox(width: 10),
				pw.SizedBox(
					width: 36,
					child: pw.Text('$value',
							textAlign: pw.TextAlign.right,
							style: pw.TextStyle(
								fontSize: 11,
								fontWeight: pw.FontWeight.bold,
								color: _ink,
							)),
				),
			],
		);
	}

	// ── Formateadores ────────────────────────────────────────────────────────────
	static String _formatCurrency(double value) {
		final formatted = value.toStringAsFixed(0).replaceAllMapped(
					RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
					(Match m) => '${m[1]}.',
				);
		return 'Bs $formatted';
	}

	// Compacto para tarjetas angostas: Bs 900 · Bs 75K · Bs 2.4M
	static String _compactBs(double value) {
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

	static String _orEmpty(String value) =>
			value.trim().isEmpty ? 'Sin datos' : value.trim();

	static String _formatDate(DateTime date) {
		const months = [
			'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
			'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
		];
		return '${date.day} de ${months[date.month - 1]} de ${date.year}';
	}

	static String _fileStamp(DateTime date) {
		String two(int n) => n.toString().padLeft(2, '0');
		return '${date.year}${two(date.month)}${two(date.day)}_${two(date.hour)}${two(date.minute)}';
	}
}
