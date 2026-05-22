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
		// Tipografía profesional embebida (con fallback a la default si no hay red).
		pw.ThemeData theme;
		try {
			final regular = await PdfGoogleFonts.latoRegular();
			final bold = await PdfGoogleFonts.latoBold();
			final italic = await PdfGoogleFonts.latoItalic();
			theme = pw.ThemeData.withFont(
				base: regular,
				bold: bold,
				italic: italic,
			);
		} catch (_) {
			theme = pw.ThemeData.base();
		}

		final pdf = pw.Document(theme: theme);

		// Totales
		final campaignsGoalTotal =
				activeCampaigns.fold<double>(0, (s, c) => s + c.goalAmount);
		final campaignsRaisedTotal =
				activeCampaigns.fold<double>(0, (s, c) => s + c.raisedAmount);
		final averageProgress = activeCampaigns.isEmpty
				? 0.0
				: activeCampaigns.fold<double>(0, (s, c) => s + c.completionRatio) /
						activeCampaigns.length;
		// Las organizaciones viven dentro de Solicitudes (igual que en la app).
		final pendingSolicitudes =
				metrics.pendingRequests + metrics.pendingOrganizations;

		pdf.addPage(
			pw.MultiPage(
				pageFormat: PdfPageFormat.a4,
				margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 44),
				footer: (context) => _footer(context),
				build: (context) => [
					// El membrete va dentro del contenido (no como header de
					// MultiPage, que vive en el margen y no admite tanta altura).
					_letterhead(),
					pw.SizedBox(height: 24),

					// ── KPIs principales (tarjetas) ─────────────────────────────
					_sectionTitle('Indicadores principales', _blue),
					pw.SizedBox(height: 12),
					pw.Row(
						crossAxisAlignment: pw.CrossAxisAlignment.stretch,
						children: [
							_kpiCard('Donantes únicos', '${metrics.totalDonors}', _blue),
							pw.SizedBox(width: 10),
							_kpiCard('Tasa de aprobación',
									'${metrics.approvalRate.toStringAsFixed(0)}%', _green),
							pw.SizedBox(width: 10),
							_kpiCard('Campañas activas', '${metrics.activeCampaigns}',
									_orange),
							pw.SizedBox(width: 10),
							_kpiCard('Resp. promedio',
									'${metrics.avgResponseTimeHours.toStringAsFixed(0)} h', _blueDark),
						],
					),
					pw.SizedBox(height: 24),

					// ── Resumen financiero ──────────────────────────────────────
					_sectionTitle('Resumen financiero', _greenDark),
					pw.SizedBox(height: 12),
					_panel([
						_metricRow('Total recaudado',
								_formatCurrency(campaignsRaisedTotal), _greenDark),
						_metricRow('Meta total', _formatCurrency(campaignsGoalTotal),
								_blue),
						_metricRow('Progreso promedio',
								'${(averageProgress * 100).toStringAsFixed(1)}%', _orange),
						_metricRow('Donación promedio',
								_formatCurrency(metrics.avgDonationAmount), _ink),
					]),
					pw.SizedBox(height: 24),

					// ── Tareas pendientes ───────────────────────────────────────
					_sectionTitle('Tareas pendientes', _orange),
					pw.SizedBox(height: 12),
					pw.Row(
						crossAxisAlignment: pw.CrossAxisAlignment.stretch,
						children: [
							_pendingCard('Solicitudes', '$pendingSolicitudes',
									'Campañas y organizaciones', _orange),
							pw.SizedBox(width: 10),
							_pendingCard('Donaciones', '${metrics.pendingDonations}',
									'Por verificar', _greenDark),
						],
					),
					pw.SizedBox(height: 24),

					// ── Campañas activas ────────────────────────────────────────
					if (activeCampaigns.isNotEmpty) ...[
						_sectionTitle('Campañas activas', _green),
						pw.SizedBox(height: 12),
						_campaignsTable(activeCampaigns),
						if (activeCampaigns.length > 10)
							pw.Padding(
								padding: const pw.EdgeInsets.only(top: 8),
								child: pw.Text(
									'+ ${activeCampaigns.length - 10} campañas más',
									style: pw.TextStyle(
										fontSize: 9,
										fontStyle: pw.FontStyle.italic,
										color: _muted,
									),
								),
							),
						pw.SizedBox(height: 24),
					],

					// ── Estadísticas de donaciones ──────────────────────────────
					_sectionTitle('Estadísticas de donaciones', _blue),
					pw.SizedBox(height: 12),
					_panel([
						_metricRow('Donaciones este mes',
								'${metrics.donationsThisMonth}', _greenDark),
						_metricRow('Donaciones mes anterior',
								'${metrics.donationsLastMonth}', _muted),
						_metricRow(
							'Crecimiento',
							'${metrics.donationGrowthRate >= 0 ? '+' : ''}${metrics.donationGrowthRate.toStringAsFixed(1)}%',
							metrics.donationGrowthRate >= 0 ? _greenDark : PdfColors.red700,
						),
						_metricRow('Donantes recurrentes',
								'${metrics.repeatDonorsPercentage.toStringAsFixed(0)}%', _blue),
						_metricRow('Campañas completadas este mes',
								'${metrics.campaignsCompletedThisMonth}', _green),
					]),
				],
			),
		);

		await Printing.layoutPdf(
			onLayout: (format) async => pdf.save(),
			name:
					'Manos_Solidarias_Reporte_${_fileStamp(DateTime.now())}.pdf',
		);
	}

	// ── Membrete (página 1) ─────────────────────────────────────────────────────
	static pw.Widget _letterhead() {
		return pw.Container(
			padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 20),
			decoration: pw.BoxDecoration(
				gradient: pw.LinearGradient(
					begin: pw.Alignment.centerLeft,
					end: pw.Alignment.centerRight,
					colors: [_blueDark, _blue],
				),
				borderRadius: pw.BorderRadius.circular(14),
			),
			child: pw.Row(
				crossAxisAlignment: pw.CrossAxisAlignment.center,
				children: [
					// Insignia de marca (sin iconos: monograma)
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

	// ── Footer con paginación ────────────────────────────────────────────────────
	static pw.Widget _footer(pw.Context context) {
		return pw.Container(
			margin: const pw.EdgeInsets.only(top: 12),
			padding: const pw.EdgeInsets.only(top: 8),
			decoration: pw.BoxDecoration(
				border: pw.Border(top: pw.BorderSide(color: _line, width: 1)),
			),
			child: pw.Row(
				mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
				children: [
					pw.Text(
						'Manos Solidarias © ${DateTime.now().year}',
						style: pw.TextStyle(fontSize: 9, color: _muted),
					),
					pw.Text(
						'Página ${context.pageNumber} de ${context.pagesCount}',
						style: pw.TextStyle(fontSize: 9, color: _muted),
					),
				],
			),
		);
	}

	// ── Título de sección (barra lateral + texto) ────────────────────────────────
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

	// ── Tarjeta KPI ───────────────────────────────────────────────────────────────
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
						pw.Text(
							value,
							style: pw.TextStyle(
								fontSize: 20,
								fontWeight: pw.FontWeight.bold,
								color: _ink,
							),
						),
						pw.SizedBox(height: 3),
						pw.Text(
							label,
							style: pw.TextStyle(fontSize: 8.5, color: _muted),
							maxLines: 2,
						),
					],
				),
			),
		);
	}

	// ── Tarjeta de pendientes ─────────────────────────────────────────────────────
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
					crossAxisAlignment: pw.CrossAxisAlignment.center,
					children: [
						pw.Text(
							value,
							style: pw.TextStyle(
								fontSize: 26,
								fontWeight: pw.FontWeight.bold,
								color: color,
							),
						),
						pw.SizedBox(width: 12),
						pw.Expanded(
							child: pw.Column(
								crossAxisAlignment: pw.CrossAxisAlignment.start,
								children: [
									pw.Text(
										label,
										style: pw.TextStyle(
											fontSize: 12,
											fontWeight: pw.FontWeight.bold,
											color: _ink,
										),
									),
									pw.SizedBox(height: 2),
									pw.Text(
										sub,
										style: pw.TextStyle(fontSize: 9, color: _muted),
									),
								],
							),
						),
					],
				),
			),
		);
	}

	// ── Panel de filas métricas (divisores solo entre filas) ─────────────────────
	static pw.Widget _panel(List<pw.Widget> rows) {
		final children = <pw.Widget>[];
		for (var i = 0; i < rows.length; i++) {
			if (i > 0) {
				children.add(pw.Divider(height: 1, thickness: 0.6, color: _line));
			}
			children.add(rows[i]);
		}
		return pw.Container(
			padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
					pw.Text(
						label,
						style: pw.TextStyle(fontSize: 11, color: _ink),
					),
					pw.Text(
						value,
						style: pw.TextStyle(
							fontSize: 11.5,
							fontWeight: pw.FontWeight.bold,
							color: color,
						),
					),
				],
			),
		);
	}

	// ── Tabla de campañas (con zebra) ───────────────────────────────────────────
	static pw.Widget _campaignsTable(List<AdminActiveCampaign> campaigns) {
		final rows = <pw.TableRow>[
			pw.TableRow(
				decoration: pw.BoxDecoration(color: _blue),
				children: [
					_th('Campaña', pw.TextAlign.left),
					_th('Progreso', pw.TextAlign.center),
					_th('Recaudado', pw.TextAlign.right),
					_th('Meta', pw.TextAlign.right),
				],
			),
		];

		final shown = campaigns.take(10).toList();
		for (var i = 0; i < shown.length; i++) {
			final c = shown[i];
			rows.add(
				pw.TableRow(
					decoration: pw.BoxDecoration(
						color: i.isEven ? PdfColors.white : _surface,
					),
					children: [
						_td(c.title, pw.TextAlign.left),
						_td('${(c.completionRatio * 100).toStringAsFixed(0)}%',
								pw.TextAlign.center),
						_td(_formatCurrency(c.raisedAmount), pw.TextAlign.right),
						_td(_formatCurrency(c.goalAmount), pw.TextAlign.right),
					],
				),
			);
		}

		return pw.Container(
			decoration: pw.BoxDecoration(
				borderRadius: pw.BorderRadius.circular(8),
				border: pw.Border.all(color: _line, width: 1),
			),
			child: pw.ClipRRect(
				horizontalRadius: 8,
				verticalRadius: 8,
				child: pw.Table(
					columnWidths: {
						0: const pw.FlexColumnWidth(3),
						1: const pw.FlexColumnWidth(1.2),
						2: const pw.FlexColumnWidth(1.6),
						3: const pw.FlexColumnWidth(1.6),
					},
					children: rows,
				),
			),
		);
	}

	static pw.Widget _th(String text, pw.TextAlign align) {
		return pw.Padding(
			padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
			child: pw.Text(
				text,
				textAlign: align,
				style: pw.TextStyle(
					fontSize: 10,
					fontWeight: pw.FontWeight.bold,
					color: PdfColors.white,
				),
			),
		);
	}

	static pw.Widget _td(String text, pw.TextAlign align) {
		return pw.Padding(
			padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
			child: pw.Text(
				text,
				textAlign: align,
				style: pw.TextStyle(fontSize: 9.5, color: _ink),
			),
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
