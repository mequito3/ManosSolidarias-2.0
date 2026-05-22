import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/admin_dashboard.dart';

class PdfExportService {
	// ── Paleta de marca (misma que la app) ─────────────────────────────────────
	static final PdfColor _blue = PdfColor.fromHex('#2E86AB');
	static final PdfColor _blueDark = PdfColor.fromHex('#1B5E7A');
	static final PdfColor _orange = PdfColor.fromHex('#F28E2C');
	static final PdfColor _green = PdfColor.fromHex('#4CAF50');
	static final PdfColor _greenDark = PdfColor.fromHex('#28A745');
	static final PdfColor _ink = PdfColor.fromHex('#2C3E50');
	static final PdfColor _muted = PdfColor.fromHex('#6B7B8C');
	static final PdfColor _line = PdfColor.fromHex('#E3E8EE');
	static final PdfColor _surface = PdfColor.fromHex('#F8F9FA');

	static Future<void> exportMetricsToPdf({
		required AdminDashboardMetrics metrics,
		required List<AdminActiveCampaign> activeCampaigns,
	}) async {
		// Fuente estándar del paquete (soporta acentos vía WinAnsi). Evitamos
		// embeber fuentes de red porque generaba PDFs que algunos visores de
		// Android rechazaban ("Lo sentimos, esto no ha funcionado").
		final pdf = pw.Document();

		// Totales / derivados
		final goalTotal =
				activeCampaigns.fold<double>(0, (s, c) => s + c.goalAmount);
		final raisedTotal =
				activeCampaigns.fold<double>(0, (s, c) => s + c.raisedAmount);
		final avgProgress = activeCampaigns.isEmpty
				? 0.0
				: activeCampaigns.fold<double>(0, (s, c) => s + c.completionRatio) /
						activeCampaigns.length;
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

					// ── Resumen ejecutivo (narrativo) ───────────────────────────
					_sectionTitle('Resumen ejecutivo', _blue),
					pw.SizedBox(height: 10),
					_execSummary(metrics, activeCampaigns, raisedTotal,
							pendingSolicitudes),
					pw.SizedBox(height: 20),

					// ── KPIs principales ────────────────────────────────────────
					pw.Row(
						children: [
							_kpiCard('Donantes', '${metrics.totalDonors}', _blue),
							pw.SizedBox(width: 10),
							_kpiCard('Aprobación',
									'${metrics.approvalRate.toStringAsFixed(0)}%', _green),
							pw.SizedBox(width: 10),
							_kpiCard('Campañas', '${metrics.activeCampaigns}', _orange),
							pw.SizedBox(width: 10),
							_kpiCard('Tiempo resp.',
									'${metrics.avgResponseTimeHours.toStringAsFixed(0)} h',
									_blueDark),
						],
					),
					pw.SizedBox(height: 24),

					// ── Indicadores de desempeño (barras) ───────────────────────
					_sectionTitle('Indicadores de desempeño', _green),
					pw.SizedBox(height: 12),
					_panel([
						_bar('Tasa de aprobación de solicitudes',
								metrics.approvalRate, _green),
						_bar('Progreso promedio de campañas',
								avgProgress * 100, _blue),
						_bar('Donantes recurrentes',
								metrics.repeatDonorsPercentage, _orange),
					], gap: 14),
					pw.SizedBox(height: 24),

					// ── Crecimiento de donaciones (gráfico) ─────────────────────
					_sectionTitle('Crecimiento de donaciones', _orange),
					pw.SizedBox(height: 12),
					_growthChart(metrics),
					pw.SizedBox(height: 24),

					// ── Resumen financiero ──────────────────────────────────────
					_sectionTitle('Resumen financiero', _greenDark),
					pw.SizedBox(height: 12),
					_panel([
						_metricRow('Total recaudado', _formatCurrency(raisedTotal),
								_greenDark),
						_metricRow('Meta total', _formatCurrency(goalTotal), _blue),
						_metricRow('Donación promedio',
								_formatCurrency(metrics.avgDonationAmount), _ink),
					]),
					pw.SizedBox(height: 24),

					// ── Campañas activas (con barras de progreso) ───────────────
					if (activeCampaigns.isNotEmpty) ...[
						_sectionTitle('Campañas activas', _green),
						pw.SizedBox(height: 12),
						_campaignsList(activeCampaigns),
						if (activeCampaigns.length > 8)
							pw.Padding(
								padding: const pw.EdgeInsets.only(top: 8),
								child: pw.Text(
									'+ ${activeCampaigns.length - 8} campañas más',
									style: pw.TextStyle(
										fontSize: 9,
										fontStyle: pw.FontStyle.italic,
										color: _muted,
									),
								),
							),
						pw.SizedBox(height: 24),
					],

					// ── Tareas pendientes ───────────────────────────────────────
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

		// Compartir/guardar el archivo (no imprimir): abre el menú del sistema
		// para guardar en Archivos, enviar por WhatsApp, abrir en Drive, etc.
		// Evita el spooler de impresión de Android, que falla al previsualizar
		// ("Lo sentimos, eso no ha funcionado").
		final bytes = await pdf.save();
		await Printing.sharePdf(
			bytes: bytes,
			filename: 'Manos_Solidarias_Reporte_${_fileStamp(DateTime.now())}.pdf',
		);
	}

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
						child: pw.Text(
							'MS',
							style: pw.TextStyle(
								fontSize: 20,
								fontWeight: pw.FontWeight.bold,
								color: _blue,
							),
						),
					),
					pw.SizedBox(width: 14),
					pw.Expanded(
						child: pw.Column(
							crossAxisAlignment: pw.CrossAxisAlignment.start,
							children: [
								pw.Text(
									'Manos Solidarias',
									style: pw.TextStyle(
										fontSize: 19,
										fontWeight: pw.FontWeight.bold,
										color: PdfColors.white,
										letterSpacing: 0.2,
									),
								),
								pw.SizedBox(height: 2),
								pw.Text(
									'Reporte de métricas del panel administrativo',
									style: pw.TextStyle(
										fontSize: 11,
										color: PdfColor.fromHex('#D6E6EF'),
									),
								),
							],
						),
					),
					pw.Column(
						crossAxisAlignment: pw.CrossAxisAlignment.end,
						children: [
							pw.Text(
								'GENERADO',
								style: pw.TextStyle(
									fontSize: 8,
									color: PdfColor.fromHex('#BCD6E5'),
									letterSpacing: 1.2,
								),
							),
							pw.SizedBox(height: 3),
							pw.Text(
								_formatDate(DateTime.now()),
								style: pw.TextStyle(
									fontSize: 11,
									fontWeight: pw.FontWeight.bold,
									color: PdfColors.white,
								),
							),
						],
					),
				],
			),
		);
	}

	// ── Resumen ejecutivo narrativo ──────────────────────────────────────────────
	static pw.Widget _execSummary(
		AdminDashboardMetrics m,
		List<AdminActiveCampaign> campaigns,
		double raisedTotal,
		int pendingSolicitudes,
	) {
		final growthWord = m.donationGrowthRate >= 0 ? 'crecieron' : 'disminuyeron';
		final text =
				'En el período analizado se contabilizaron ${m.totalDonors} donantes '
				'únicos y ${m.activeCampaigns} campañas activas, con un total recaudado '
				'de ${_formatCurrency(raisedTotal)}. La tasa de aprobación de solicitudes '
				'fue del ${m.approvalRate.toStringAsFixed(0)}%, con un tiempo promedio de '
				'respuesta de ${m.avgResponseTimeHours.toStringAsFixed(0)} horas. Las '
				'donaciones $growthWord un ${m.donationGrowthRate.abs().toStringAsFixed(0)}% '
				'respecto al mes anterior. Actualmente hay $pendingSolicitudes solicitudes '
				'y ${m.pendingDonations} donaciones pendientes de revisión.';
		return pw.Container(
			padding: const pw.EdgeInsets.all(16),
			decoration: pw.BoxDecoration(
				color: _surface,
				borderRadius: pw.BorderRadius.circular(10),
				border: pw.Border(left: pw.BorderSide(color: _blue, width: 3)),
			),
			child: pw.Text(
				text,
				style: pw.TextStyle(fontSize: 11, color: _ink, lineSpacing: 3.5),
			),
		);
	}

	// ── Footer con paginación ────────────────────────────────────────────────────
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
				pw.Text(
					title,
					style: pw.TextStyle(
						fontSize: 14,
						fontWeight: pw.FontWeight.bold,
						color: _ink,
						letterSpacing: 0.2,
					),
				),
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
									fontSize: 20,
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

	// ── Panel de filas / contenido ──────────────────────────────────────────────────
	static pw.Widget _panel(List<pw.Widget> rows, {double? gap}) {
		final children = <pw.Widget>[];
		for (var i = 0; i < rows.length; i++) {
			if (i > 0) {
				if (gap != null) {
					children.add(pw.SizedBox(height: gap));
				} else {
					children.add(pw.Divider(height: 1, thickness: 0.6, color: _line));
				}
			}
			children.add(rows[i]);
		}
		return pw.Container(
			padding: pw.EdgeInsets.symmetric(horizontal: 16, vertical: gap != null ? 16 : 4),
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
				children: [
					pw.Text(label, style: pw.TextStyle(fontSize: 11, color: _ink)),
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
						pw.Text(label,
								style: pw.TextStyle(fontSize: 10, color: _ink)),
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

	// ── Gráfico de crecimiento (2 barras comparativas) ──────────────────────────────
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
					width: 32,
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

	// ── Lista de campañas con barra de progreso ─────────────────────────────────────
	static pw.Widget _campaignsList(List<AdminActiveCampaign> campaigns) {
		final shown = campaigns.take(8).toList();
		final rows = <pw.Widget>[];
		for (var i = 0; i < shown.length; i++) {
			final c = shown[i];
			final pct = (c.completionRatio * 100);
			final filled = pct.round().clamp(0, 100);
			final empty = 100 - filled;
			if (i > 0) {
				rows.add(pw.Divider(height: 1, thickness: 0.6, color: _line));
			}
			rows.add(
				pw.Padding(
					padding: const pw.EdgeInsets.symmetric(vertical: 10),
					child: pw.Column(
						crossAxisAlignment: pw.CrossAxisAlignment.start,
						children: [
							pw.Row(
								mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
								children: [
									pw.Expanded(
										child: pw.Text(
											c.title,
											maxLines: 1,
											overflow: pw.TextOverflow.clip,
											style: pw.TextStyle(
												fontSize: 11,
												fontWeight: pw.FontWeight.bold,
												color: _ink,
											),
										),
									),
									pw.SizedBox(width: 10),
									pw.Text(
										'${_formatCurrency(c.raisedAmount)} / ${_formatCurrency(c.goalAmount)}',
										style: pw.TextStyle(fontSize: 9.5, color: _muted),
									),
								],
							),
							pw.SizedBox(height: 6),
							pw.Row(
								children: [
									pw.Expanded(
										child: pw.Container(
											height: 8,
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
																	color: _green,
																	borderRadius:
																			pw.BorderRadius.circular(4),
																),
															),
														),
													if (empty > 0)
														pw.Expanded(
																flex: empty, child: pw.SizedBox()),
												],
											),
										),
									),
									pw.SizedBox(width: 10),
									pw.SizedBox(
										width: 34,
										child: pw.Text(
											'${pct.toStringAsFixed(0)}%',
											textAlign: pw.TextAlign.right,
											style: pw.TextStyle(
												fontSize: 10,
												fontWeight: pw.FontWeight.bold,
												color: _greenDark,
											),
										),
									),
								],
							),
						],
					),
				),
			);
		}
		return pw.Container(
			padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
			decoration: pw.BoxDecoration(
				color: PdfColors.white,
				borderRadius: pw.BorderRadius.circular(10),
				border: pw.Border.all(color: _line, width: 1),
			),
			child: pw.Column(children: rows),
		);
	}

	static String _formatCurrency(double value) {
		final formatted = value.toStringAsFixed(0).replaceAllMapped(
					RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
					(Match m) => '${m[1]}.',
				);
		return 'Bs $formatted';
	}

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
