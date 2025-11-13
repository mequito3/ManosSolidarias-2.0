import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/admin_dashboard.dart';

class PdfExportService {
	static Future<void> exportMetricsToPdf({
		required AdminDashboardMetrics metrics,
		required List<AdminActiveCampaign> activeCampaigns,
	}) async {
		final pdf = pw.Document();

		// Calcular totales
		final campaignsGoalTotal = activeCampaigns.fold<double>(
			0,
			(sum, c) => sum + c.goalAmount,
		);
		final campaignsRaisedTotal = activeCampaigns.fold<double>(
			0,
			(sum, c) => sum + c.raisedAmount,
		);
		final averageProgress = activeCampaigns.isEmpty
				? 0.0
				: activeCampaigns.fold<double>(0, (sum, c) => sum + c.completionRatio) /
						activeCampaigns.length;

		pdf.addPage(
			pw.MultiPage(
				pageFormat: PdfPageFormat.a4,
				margin: const pw.EdgeInsets.all(32),
				build: (context) => [
					// Header
					pw.Row(
						mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
						children: [
							pw.Column(
								crossAxisAlignment: pw.CrossAxisAlignment.start,
								children: [
									pw.Text(
										'Reporte de Métricas',
										style: pw.TextStyle(
											fontSize: 28,
											fontWeight: pw.FontWeight.bold,
											color: PdfColors.blue800,
										),
									),
									pw.SizedBox(height: 8),
									pw.Text(
										'Manos Solidarias',
										style: pw.TextStyle(
											fontSize: 16,
											color: PdfColors.grey700,
										),
									),
									pw.SizedBox(height: 4),
									pw.Text(
										'Generado: ${_formatDate(DateTime.now())}',
										style: const pw.TextStyle(
											fontSize: 12,
											color: PdfColors.grey600,
										),
									),
								],
							),
							pw.Container(
								width: 80,
								height: 80,
								decoration: pw.BoxDecoration(
									color: PdfColors.blue50,
									borderRadius: pw.BorderRadius.circular(12),
								),
								child: pw.Center(
									child: pw.Icon(
										const pw.IconData(0xe1b7), // analytics icon
										size: 48,
										color: PdfColors.blue800,
									),
								),
							),
						],
					),
					pw.SizedBox(height: 32),
					pw.Divider(thickness: 2, color: PdfColors.blue800),
					pw.SizedBox(height: 24),

					// Resumen Ejecutivo
					_buildSectionTitle('Resumen Ejecutivo', PdfColors.blue800),
					pw.SizedBox(height: 16),
					pw.Container(
						padding: const pw.EdgeInsets.all(16),
						decoration: pw.BoxDecoration(
							color: PdfColors.grey100,
							borderRadius: pw.BorderRadius.circular(8),
						),
						child: pw.Column(
							children: [
								_buildMetricRow(
									'Total de Donantes',
									metrics.totalDonors.toString(),
									PdfColors.blue800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Campañas Activas',
									metrics.activeCampaigns.toString(),
									PdfColors.green800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Total Recaudado',
									_formatCurrency(campaignsRaisedTotal),
									PdfColors.orange800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Campañas Completadas',
									metrics.campaignsCompletedThisMonth.toString(),
									PdfColors.green800,
								),
							],
						),
					),
					pw.SizedBox(height: 24),

					// Indicadores Clave
					_buildSectionTitle('Indicadores Clave de Desempeño', PdfColors.orange800),
					pw.SizedBox(height: 16),
					pw.Container(
						padding: const pw.EdgeInsets.all(16),
						decoration: pw.BoxDecoration(
							color: PdfColors.orange50,
							borderRadius: pw.BorderRadius.circular(8),
						),
						child: pw.Column(
							children: [
								_buildMetricRow(
									'Progreso Promedio',
									'${(averageProgress * 100).toStringAsFixed(1)}%',
									PdfColors.green800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Meta Total',
									_formatCurrency(campaignsGoalTotal),
									PdfColors.blue800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Tasa de Aprobación',
									'${metrics.approvalRate.toStringAsFixed(1)}%',
									PdfColors.orange800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Tiempo Promedio de Respuesta',
									'${metrics.avgResponseTimeHours.toStringAsFixed(1)} hrs',
									PdfColors.blue800,
								),
							],
						),
					),
					pw.SizedBox(height: 24),

					// Tareas Pendientes
					_buildSectionTitle('Tareas Pendientes', PdfColors.red800),
					pw.SizedBox(height: 16),
					pw.Container(
						padding: const pw.EdgeInsets.all(16),
						decoration: pw.BoxDecoration(
							color: PdfColors.red50,
							borderRadius: pw.BorderRadius.circular(8),
						),
						child: pw.Column(
							children: [
								_buildMetricRow(
									'Solicitudes Pendientes',
									metrics.pendingRequests.toString(),
									PdfColors.orange800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Donaciones Pendientes',
									metrics.pendingDonations.toString(),
									PdfColors.green800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Organizaciones Pendientes',
									metrics.pendingOrganizations.toString(),
									PdfColors.blue800,
								),
							],
						),
					),
					pw.SizedBox(height: 24),

					// Campañas Activas
					if (activeCampaigns.isNotEmpty) ...[
						_buildSectionTitle('Campañas Activas', PdfColors.green800),
						pw.SizedBox(height: 16),
						pw.Table(
							border: pw.TableBorder.all(color: PdfColors.grey300),
							children: [
								// Header
								pw.TableRow(
									decoration: const pw.BoxDecoration(
										color: PdfColors.green800,
									),
									children: [
										_buildTableHeader('Campaña'),
										_buildTableHeader('Progreso'),
										_buildTableHeader('Recaudado'),
										_buildTableHeader('Meta'),
									],
								),
								// Filas de datos
								...activeCampaigns.take(10).map((campaign) {
									return pw.TableRow(
										decoration: const pw.BoxDecoration(
											color: PdfColors.white,
										),
										children: [
											_buildTableCell(campaign.title),
											_buildTableCell(
												'${(campaign.completionRatio * 100).toStringAsFixed(0)}%',
											),
											_buildTableCell(_formatCurrency(campaign.raisedAmount)),
											_buildTableCell(_formatCurrency(campaign.goalAmount)),
										],
									);
								}),
							],
						),
						if (activeCampaigns.length > 10)
							pw.Padding(
								padding: const pw.EdgeInsets.only(top: 8),
								child: pw.Text(
									'+ ${activeCampaigns.length - 10} campañas más',
									style: pw.TextStyle(
										fontSize: 10,
										fontStyle: pw.FontStyle.italic,
										color: PdfColors.grey600,
									),
								),
							),
						pw.SizedBox(height: 24),
					],

					// Estadísticas de Donaciones
					_buildSectionTitle('Estadísticas de Donaciones', PdfColors.blue800),
					pw.SizedBox(height: 16),
					pw.Container(
						padding: const pw.EdgeInsets.all(16),
						decoration: pw.BoxDecoration(
							color: PdfColors.blue50,
							borderRadius: pw.BorderRadius.circular(8),
						),
						child: pw.Column(
							children: [
								_buildMetricRow(
									'Donaciones Este Mes',
									metrics.donationsThisMonth.toString(),
									PdfColors.green800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Donaciones Mes Anterior',
									metrics.donationsLastMonth.toString(),
									PdfColors.grey700,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Crecimiento',
									'${metrics.donationGrowthRate.toStringAsFixed(1)}%',
									metrics.donationGrowthRate >= 0
											? PdfColors.green800
											: PdfColors.red800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Monto Promedio por Donación',
									_formatCurrency(metrics.avgDonationAmount),
									PdfColors.blue800,
								),
								pw.SizedBox(height: 12),
								_buildMetricRow(
									'Donantes Recurrentes',
									'${metrics.repeatDonorsPercentage.toStringAsFixed(1)}%',
									PdfColors.purple800,
								),
							],
						),
					),
					pw.SizedBox(height: 32),

					// Footer
					pw.Divider(thickness: 1, color: PdfColors.grey400),
					pw.SizedBox(height: 16),
					pw.Row(
						mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
						children: [
							pw.Text(
								'Manos Solidarias © ${DateTime.now().year}',
								style: const pw.TextStyle(
									fontSize: 10,
									color: PdfColors.grey600,
								),
							),
							pw.Text(
								'Reporte generado automáticamente',
								style: const pw.TextStyle(
									fontSize: 10,
									color: PdfColors.grey600,
								),
							),
						],
					),
				],
			),
		);

		// Abrir el preview del PDF con opciones de compartir/descargar
		await Printing.layoutPdf(
			onLayout: (format) async => pdf.save(),
			name: 'Manos_Solidarias_Metricas_${DateTime.now().millisecondsSinceEpoch}.pdf',
		);
	}

	static pw.Widget _buildSectionTitle(String title, PdfColor color) {
		return pw.Container(
			padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
			decoration: pw.BoxDecoration(
				color: color,
				borderRadius: pw.BorderRadius.circular(6),
			),
			child: pw.Text(
				title,
				style: pw.TextStyle(
					fontSize: 16,
					fontWeight: pw.FontWeight.bold,
					color: PdfColors.white,
				),
			),
		);
	}

	static pw.Widget _buildMetricRow(String label, String value, PdfColor color) {
		return pw.Row(
			mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
			children: [
				pw.Text(
					label,
					style: const pw.TextStyle(
						fontSize: 12,
						color: PdfColors.grey800,
					),
				),
				pw.Text(
					value,
					style: pw.TextStyle(
						fontSize: 12,
						fontWeight: pw.FontWeight.bold,
						color: color,
					),
				),
			],
		);
	}

	static pw.Widget _buildTableHeader(String text) {
		return pw.Padding(
			padding: const pw.EdgeInsets.all(8),
			child: pw.Text(
				text,
				style: pw.TextStyle(
					fontSize: 11,
					fontWeight: pw.FontWeight.bold,
					color: PdfColors.white,
				),
				textAlign: pw.TextAlign.center,
			),
		);
	}

	static pw.Widget _buildTableCell(String text) {
		return pw.Padding(
			padding: const pw.EdgeInsets.all(8),
			child: pw.Text(
				text,
				style: const pw.TextStyle(
					fontSize: 10,
					color: PdfColors.grey800,
				),
				textAlign: pw.TextAlign.center,
			),
		);
	}

	static String _formatCurrency(double value) {
		final formatted = value.toStringAsFixed(0).replaceAllMapped(
			RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
			(Match m) => '${m[1]},',
		);
		return 'Bs $formatted';
	}

	static String _formatDate(DateTime date) {
		final months = [
			'Enero',
			'Febrero',
			'Marzo',
			'Abril',
			'Mayo',
			'Junio',
			'Julio',
			'Agosto',
			'Septiembre',
			'Octubre',
			'Noviembre',
			'Diciembre'
		];
		return '${date.day} de ${months[date.month - 1]} de ${date.year}';
	}
}
