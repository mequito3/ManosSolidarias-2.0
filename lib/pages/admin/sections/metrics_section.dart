import 'package:flutter/material.dart';

import '../../../models/admin_dashboard.dart';
import '../../../theme/app_colors.dart';
import '../../../services/pdf_export_service.dart';

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
		final campaignsGoalTotal = _sum(activeCampaigns, (campaign) => campaign.goalAmount);
		final campaignsRaisedTotal = _sum(activeCampaigns, (campaign) => campaign.raisedAmount);
		final averageProgress = activeCampaigns.isEmpty
				? 0.0
				: activeCampaigns.fold<double>(0, (sum, campaign) => sum + campaign.completionRatio) /
						activeCampaigns.length;
		final averageProgressPercent = _clamp(averageProgress * 100, 0, 100);

		return Stack(
			children: [
				Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
				// Header mejorado con botón de exportar
				Row(
					children: [
						Container(
							decoration: BoxDecoration(
								color: AppColors.bluePrimary.withOpacity(0.1),
								borderRadius: BorderRadius.circular(8),
							),
							padding: const EdgeInsets.all(8),
							child: const Icon(
								Icons.analytics_outlined,
								color: AppColors.bluePrimary,
								size: 20,
							),
						),
						const SizedBox(width: 12),
						const Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										'Panel de Análisis',
										style: TextStyle(
											fontWeight: FontWeight.w700,
											color: Colors.black,
											fontSize: 16,
										),
									),
									SizedBox(height: 2),
									Text(
										'Métricas y KPIs en tiempo real',
										style: TextStyle(
											color: Colors.black54,
											fontSize: 11,
											fontWeight: FontWeight.w400,
										),
									),
								],
							),
						),
						const SizedBox(width: 12),
						ElevatedButton.icon(
							onPressed: () => _exportPdf(context, metrics, activeCampaigns),
							style: ElevatedButton.styleFrom(
								backgroundColor: Colors.red.shade700,
								foregroundColor: Colors.white,
								elevation: 2,
								padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
								shape: RoundedRectangleBorder(
									borderRadius: BorderRadius.circular(10),
								),
							),
							icon: const Icon(Icons.picture_as_pdf, size: 18),
							label: const Text(
								'Exportar PDF',
								style: TextStyle(
									fontWeight: FontWeight.w600,
									fontSize: 13,
								),
							),
						),
					],
				),
				const SizedBox(height: 16),
				
				// KPIs principales con comparaciones
				const Text(
					'Indicadores Clave',
					style: TextStyle(
						fontWeight: FontWeight.w700,
						color: Colors.black87,
						fontSize: 13,
					),
				),
				const SizedBox(height: 8),
				
				// Fila 1: KPIs principales con análisis
				Row(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Expanded(
							child: _AdvancedMetricCard(
								icon: Icons.approval_outlined,
								iconColor: AppColors.greenSuccess,
								value: '${metrics.approvalRate.toStringAsFixed(1)}%',
								label: 'Tasa Aprobación',
								subtitle: 'Solicitudes',
								trend: metrics.approvalRate >= 70 ? 'positive' : 'neutral',
							),
						),
						const SizedBox(width: 6),
						Expanded(
							child: _AdvancedMetricCard(
								icon: Icons.schedule_outlined,
								iconColor: AppColors.bluePrimary,
								value: '${metrics.avgResponseTimeHours.toStringAsFixed(1)}h',
								label: 'Tiempo Respuesta',
								subtitle: 'Promedio',
								trend: metrics.avgResponseTimeHours < 48 ? 'positive' : 'warning',
							),
						),
						const SizedBox(width: 6),
						Expanded(
							child: _AdvancedMetricCard(
								icon: Icons.people_outline,
								iconColor: AppColors.orangeAction,
								value: metrics.totalDonors.toString(),
								label: 'Donantes',
								subtitle: '${metrics.repeatDonorsPercentage.toStringAsFixed(0)}% recurrentes',
								trend: 'positive',
							),
						),
					],
				),
				
				const SizedBox(height: 12),
				
				// Análisis de crecimiento
				const Text(
					'Crecimiento',
					style: TextStyle(
						fontWeight: FontWeight.w700,
						color: Colors.black87,
						fontSize: 13,
					),
				),
				const SizedBox(height: 8),
				
				Row(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Expanded(
							flex: 2,
							child: _GrowthCard(
								title: 'Donaciones',
								currentValue: metrics.donationsThisMonth,
								previousValue: metrics.donationsLastMonth,
								growthRate: metrics.donationGrowthRate,
								icon: Icons.trending_up,
							),
						),
						const SizedBox(width: 6),
						Expanded(
							child: _MetricCard(
								icon: Icons.check_circle,
								iconColor: AppColors.greenSuccess,
								value: metrics.campaignsCompletedThisMonth.toString(),
								label: 'Finalizadas',
							),
						),
					],
				),
				
				const SizedBox(height: 12),
				
				// Métricas financieras
				Row(
					children: [
						Expanded(
							child: _FinancialCard(
								icon: Icons.attach_money,
								label: 'Promedio',
								amount: metrics.avgDonationAmount,
								color: AppColors.greenSuccess,
							),
						),
						const SizedBox(width: 8),
						Expanded(
							child: _FinancialCard(
								icon: Icons.volunteer_activism,
								label: 'Total Aprobado',
								amount: metrics.totalApprovedAmount,
								color: AppColors.bluePrimary,
							),
						),
					],
				),
				
				if (activeCampaigns.isNotEmpty) ...[
					const SizedBox(height: 12),
					
					const Text(
						'Campañas Activas',
						style: TextStyle(
							fontWeight: FontWeight.w700,
							color: Colors.black87,
							fontSize: 13,
						),
					),
					const SizedBox(height: 8),
					
					Row(
						children: [
							Expanded(
								child: _MetricCard(
									icon: Icons.campaign,
									iconColor: AppColors.bluePrimary,
									value: metrics.activeCampaigns.toString(),
									label: 'Activas',
								),
							),
							const SizedBox(width: 8),
							Expanded(
								child: _MetricCard(
									icon: Icons.flag,
									iconColor: AppColors.orangeAction,
									value: _formatCurrency(campaignsGoalTotal),
									label: 'Meta',
								),
							),
							const SizedBox(width: 8),
							Expanded(
								child: _MetricCard(
									icon: Icons.trending_up,
									iconColor: AppColors.greenHope,
									value: _formatCurrency(campaignsRaisedTotal),
									label: 'Recaudado',
								),
							),
						],
					),
					
					const SizedBox(height: 8),
					
					// Progreso
					_ProgressCard(progressPercent: averageProgressPercent),
				],
				
				const SizedBox(height: 16),
				
				// Tareas pendientes (al final)
				Container(
					padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
					child: Row(
						children: [
							Container(
								width: 4,
								height: 20,
								decoration: BoxDecoration(
									color: AppColors.orangeAction,
									borderRadius: BorderRadius.circular(2),
								),
							),
							const SizedBox(width: 10),
							const Text(
								'Tareas Pendientes',
								style: TextStyle(
									fontWeight: FontWeight.w800,
									color: Colors.black87,
									fontSize: 15,
									letterSpacing: 0.3,
								),
							),
							const Spacer(),
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
								decoration: BoxDecoration(
									color: AppColors.orangeAction.withOpacity(0.1),
									borderRadius: BorderRadius.circular(12),
									border: Border.all(
										color: AppColors.orangeAction.withOpacity(0.3),
										width: 1,
									),
								),
								child: Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										Icon(Icons.notifications_active_outlined, 
											size: 12, 
											color: AppColors.orangeAction,
										),
										const SizedBox(width: 4),
										Text(
											'${metrics.pendingRequests + metrics.pendingDonations + metrics.pendingOrganizations}',
											style: TextStyle(
												fontSize: 11,
												fontWeight: FontWeight.w700,
												color: AppColors.orangeAction,
											),
										),
									],
								),
							),
						],
					),
				),
				const SizedBox(height: 12),
				
				Row(
					children: [
						Expanded(
							child: _PendingTaskCard(
								icon: Icons.campaign,
								iconColor: AppColors.orangeAction,
								count: metrics.pendingRequests,
								label: 'Solicitudes',
								subtitle: 'Campañas nuevas',
							),
						),
						const SizedBox(width: 10),
						Expanded(
							child: _PendingTaskCard(
								icon: Icons.volunteer_activism,
								iconColor: AppColors.greenSuccess,
								count: metrics.pendingDonations,
								label: 'Donaciones',
								subtitle: 'Por verificar',
							),
						),
						const SizedBox(width: 10),
						Expanded(
							child: _PendingTaskCard(
								icon: Icons.domain_verification,
								iconColor: AppColors.bluePrimary,
								count: metrics.pendingOrganizations,
								label: 'Organizaciones',
								subtitle: 'Por aprobar',
							),
						),
					],
				),
			],
		),
		],
	);
}

// Exportar métricas a PDF con previsualización
void _exportPdf(BuildContext context, AdminDashboardMetrics metrics, List<AdminActiveCampaign> campaigns) async {
	try {
		// Mostrar loading
		showDialog(
			context: context,
			barrierDismissible: false,
			builder: (context) => const Center(
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

		// Generar y mostrar PDF
		await PdfExportService.exportMetricsToPdf(
			metrics: metrics,
			activeCampaigns: campaigns,
		);

		// Cerrar loading
		if (context.mounted) {
			Navigator.pop(context);
		}
	} catch (e) {
		// Cerrar loading
		if (context.mounted) {
			Navigator.pop(context);
			
			// Mostrar error
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Row(
						children: [
							const Icon(Icons.error, color: Colors.white),
							const SizedBox(width: 12),
							Expanded(
								child: Text('Error al generar PDF: $e'),
							),
						],
					),
					backgroundColor: Colors.red,
					behavior: SnackBarBehavior.floating,
				),
			);
		}
	}
}

double _sum(List<AdminActiveCampaign> campaigns, double Function(AdminActiveCampaign) selector) {
		double total = 0;
		for (final campaign in campaigns) {
			total += selector(campaign);
		}
		return total;
	}

	double _clamp(double value, double min, double max) {
		if (value < min) {
			return min;
		}
		if (value > max) {
			return max;
		}
		return value;
	}

	String _formatCurrency(double value) {
		final intValue = value.round().toString();
		final formatted = intValue.replaceAllMapped(
			RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
			(Match m) => '${m[1]},',
		);
		return 'Bs $formatted';
	}
}

// Tarjeta de métrica avanzada con análisis
class _AdvancedMetricCard extends StatelessWidget {
	const _AdvancedMetricCard({
		required this.icon,
		required this.iconColor,
		required this.value,
		required this.label,
		required this.subtitle,
		required this.trend,
	});

	final IconData icon;
	final Color iconColor;
	final String value;
	final String label;
	final String subtitle;
	final String trend; // 'positive', 'negative', 'neutral', 'warning'

	@override
	Widget build(BuildContext context) {
		IconData trendIcon;
		Color trendColor;
		
		switch (trend) {
			case 'positive':
				trendIcon = Icons.arrow_upward;
				trendColor = AppColors.greenSuccess;
				break;
			case 'negative':
				trendIcon = Icons.arrow_downward;
				trendColor = Colors.red;
				break;
			case 'warning':
				trendIcon = Icons.warning_amber;
				trendColor = AppColors.orangeAction;
				break;
			default:
				trendIcon = Icons.remove;
				trendColor = Colors.grey;
		}

		return Container(
			decoration: BoxDecoration(
				gradient: LinearGradient(
					colors: [
						iconColor.withOpacity(0.08),
						iconColor.withOpacity(0.02),
					],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
				borderRadius: BorderRadius.circular(10),
				border: Border.all(color: iconColor.withOpacity(0.2), width: 0.8),
			),
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Container(
								decoration: BoxDecoration(
									color: iconColor.withOpacity(0.15),
									borderRadius: BorderRadius.circular(6),
								),
								padding: const EdgeInsets.all(5),
								child: Icon(icon, size: 14, color: iconColor),
							),
							Icon(trendIcon, size: 14, color: trendColor),
						],
					),
					const SizedBox(height: 8),
					Text(
						value,
						style: TextStyle(
							fontSize: 18,
							fontWeight: FontWeight.w800,
							color: iconColor,
							height: 1.1,
						),
					),
					const SizedBox(height: 4),
					Text(
						label,
						style: const TextStyle(
							fontSize: 10,
							color: Colors.black87,
							fontWeight: FontWeight.w600,
							height: 1.2,
						),
						maxLines: 2,
						overflow: TextOverflow.ellipsis,
					),
					const SizedBox(height: 2),
					Text(
						subtitle,
						style: TextStyle(
							fontSize: 8.5,
							color: Colors.black.withOpacity(0.5),
							fontWeight: FontWeight.w400,
							height: 1.2,
						),
						maxLines: 1,
						overflow: TextOverflow.ellipsis,
					),
				],
			),
		);
	}
}

// Tarjeta de crecimiento con comparación
class _GrowthCard extends StatelessWidget {
	const _GrowthCard({
		required this.title,
		required this.currentValue,
		required this.previousValue,
		required this.growthRate,
		required this.icon,
	});

	final String title;
	final int currentValue;
	final int previousValue;
	final double growthRate;
	final IconData icon;

	@override
	Widget build(BuildContext context) {
		final isPositive = growthRate >= 0;
		final growthColor = isPositive ? AppColors.greenSuccess : Colors.red;

		return Container(
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(10),
				border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.8),
				boxShadow: [
					BoxShadow(
						color: growthColor.withOpacity(0.06),
						blurRadius: 6,
						offset: const Offset(0, 1),
					),
				],
			),
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Container(
								decoration: BoxDecoration(
									color: growthColor.withOpacity(0.12),
									borderRadius: BorderRadius.circular(6),
								),
								padding: const EdgeInsets.all(5),
								child: Icon(icon, size: 14, color: growthColor),
							),
							const Spacer(),
							Container(
								decoration: BoxDecoration(
									color: growthColor.withOpacity(0.15),
									borderRadius: BorderRadius.circular(4),
								),
								padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
								child: Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										Icon(
											isPositive ? Icons.arrow_upward : Icons.arrow_downward,
											size: 9,
											color: growthColor,
										),
										const SizedBox(width: 1.5),
										Text(
											'${growthRate.abs().toStringAsFixed(1)}%',
											style: TextStyle(
												fontSize: 8,
												fontWeight: FontWeight.w800,
												color: growthColor,
											),
										),
									],
								),
							),
						],
					),
					const SizedBox(height: 8),
					Text(
						title,
						style: const TextStyle(
							fontSize: 8.5,
							color: Colors.black54,
							fontWeight: FontWeight.w500,
							height: 1.2,
						),
					),
					const SizedBox(height: 6),
					Row(
						crossAxisAlignment: CrossAxisAlignment.end,
						children: [
							Text(
								currentValue.toString(),
								style: TextStyle(
									fontSize: 18,
									fontWeight: FontWeight.w800,
									color: growthColor,
									height: 1.1,
								),
							),
							const SizedBox(width: 4),
							Padding(
								padding: const EdgeInsets.only(bottom: 2),
								child: Text(
									'vs $previousValue',
									style: const TextStyle(
										fontSize: 8,
										color: Colors.black45,
										fontWeight: FontWeight.w400,
										height: 1.2,
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

// Tarjeta financiera
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
			decoration: BoxDecoration(
				color: color.withOpacity(0.08),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: color.withOpacity(0.25), width: 1),
			),
			padding: const EdgeInsets.all(12),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Icon(icon, size: 20, color: color),
					const SizedBox(height: 8),
					Text(
						_formatAmount(amount),
						style: TextStyle(
							fontSize: 18,
							fontWeight: FontWeight.w900,
							color: color,
							height: 1,
						),
					),
					const SizedBox(height: 4),
					Text(
						label,
						style: const TextStyle(
							fontSize: 10,
							color: Colors.black87,
							fontWeight: FontWeight.w500,
						),
					),
				],
			),
		);
	}

	String _formatAmount(double value) {
		final intValue = value.round().toString();
		final formatted = intValue.replaceAllMapped(
			RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
			(Match m) => '${m[1]},',
		);
		return 'Bs $formatted';
	}
}

// Tarjeta de categoría popular
// Tarjeta de tareas pendientes mejorada
class _PendingTaskCard extends StatelessWidget {
	const _PendingTaskCard({
		required this.icon,
		required this.iconColor,
		required this.count,
		required this.label,
		this.subtitle,
	});

	final IconData icon;
	final Color iconColor;
	final int count;
	final String label;
	final String? subtitle;

	@override
	Widget build(BuildContext context) {
		final isUrgent = count > 5;
		final isEmpty = count == 0;
		
		return Container(
			decoration: BoxDecoration(
				gradient: isEmpty 
					? LinearGradient(
							begin: Alignment.topLeft,
							end: Alignment.bottomRight,
							colors: [
								Colors.grey.shade50,
								Colors.grey.shade100,
							],
						)
					: LinearGradient(
							begin: Alignment.topLeft,
							end: Alignment.bottomRight,
							colors: [
								Colors.white,
								iconColor.withOpacity(0.02),
							],
						),
				borderRadius: BorderRadius.circular(14),
				border: Border.all(
					color: isUrgent 
						? Colors.red.withOpacity(0.4) 
						: isEmpty
							? Colors.grey.shade300
							: iconColor.withOpacity(0.25),
					width: isUrgent ? 2.5 : 1.5,
				),
				boxShadow: [
					if (!isEmpty)
						BoxShadow(
							color: iconColor.withOpacity(0.08),
							blurRadius: 8,
							offset: const Offset(0, 2),
						),
				],
			),
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Container(
								decoration: BoxDecoration(
									color: isEmpty 
										? Colors.grey.shade200 
										: iconColor.withOpacity(0.15),
									borderRadius: BorderRadius.circular(10),
									boxShadow: [
										if (!isEmpty)
											BoxShadow(
												color: iconColor.withOpacity(0.2),
												blurRadius: 4,
												offset: const Offset(0, 2),
											),
									],
								),
								padding: const EdgeInsets.all(8),
								child: Icon(
									icon, 
									size: 20, 
									color: isEmpty ? Colors.grey.shade400 : iconColor,
								),
							),
							const Spacer(),
							if (isUrgent)
								Container(
									decoration: BoxDecoration(
										gradient: const LinearGradient(
											colors: [Colors.red, Colors.redAccent],
										),
										borderRadius: BorderRadius.circular(6),
										boxShadow: [
											BoxShadow(
												color: Colors.red.withOpacity(0.4),
												blurRadius: 4,
												offset: const Offset(0, 2),
											),
										],
									),
									padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
									child: Row(
										mainAxisSize: MainAxisSize.min,
										children: const [
											Icon(Icons.warning_amber, size: 10, color: Colors.white),
											SizedBox(width: 3),
											Text(
												'URGENTE',
												style: TextStyle(
													fontSize: 8,
													fontWeight: FontWeight.w900,
													color: Colors.white,
													letterSpacing: 0.5,
												),
											),
										],
									),
								),
						],
					),
					const SizedBox(height: 14),
					Row(
						crossAxisAlignment: CrossAxisAlignment.end,
						children: [
							Text(
								count.toString(),
								style: TextStyle(
									fontSize: 32,
									fontWeight: FontWeight.w900,
									color: isEmpty ? Colors.grey.shade400 : iconColor,
									height: 0.9,
									letterSpacing: -0.5,
								),
							),
							const SizedBox(width: 6),
							if (!isEmpty)
								Padding(
									padding: const EdgeInsets.only(bottom: 4),
									child: Icon(
										Icons.arrow_upward,
										size: 14,
										color: iconColor.withOpacity(0.6),
									),
								),
						],
					),
					const SizedBox(height: 6),
					Text(
						label,
						style: TextStyle(
							fontSize: 11,
							color: isEmpty ? Colors.grey.shade500 : Colors.black87,
							fontWeight: FontWeight.w700,
							letterSpacing: 0.2,
						),
					),
					if (subtitle != null) ...[
						const SizedBox(height: 2),
						Text(
							subtitle!,
							style: TextStyle(
								fontSize: 9,
								color: isEmpty ? Colors.grey.shade400 : Colors.black54,
								fontWeight: FontWeight.w500,
							),
							maxLines: 1,
							overflow: TextOverflow.ellipsis,
						),
					],
				],
			),
		);
	}
}

// Tarjeta simple para métricas básicas
class _MetricCard extends StatelessWidget {
	const _MetricCard({
		required this.icon,
		required this.iconColor,
		required this.value,
		required this.label,
	});

	final IconData icon;
	final Color iconColor;
	final String value;
	final String label;

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(10),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withOpacity(0.03),
						blurRadius: 2,
						offset: const Offset(0, 1),
					),
				],
			),
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					Container(
						decoration: BoxDecoration(
							color: iconColor.withOpacity(0.12),
							borderRadius: BorderRadius.circular(6),
						),
						padding: const EdgeInsets.all(5),
						child: Icon(icon, size: 14, color: iconColor),
					),
					const SizedBox(height: 6),
					Text(
						value,
						style: TextStyle(
							fontSize: 18,
							fontWeight: FontWeight.w800,
							color: iconColor,
							height: 1.1,
						),
						textAlign: TextAlign.center,
					),
					const SizedBox(height: 3),
					Text(
						label,
						style: const TextStyle(
							fontSize: 9,
							color: Colors.black87,
							fontWeight: FontWeight.w500,
							height: 1.2,
						),
						textAlign: TextAlign.center,
						maxLines: 2,
						overflow: TextOverflow.ellipsis,
					),
				],
			),
		);
	}
}

// Tarjeta de progreso
class _ProgressCard extends StatelessWidget {
	const _ProgressCard({
		required this.progressPercent,
	});

	final double progressPercent;

	@override
	Widget build(BuildContext context) {
		final clamped = progressPercent.clamp(0, 100);
		return Container(
			decoration: BoxDecoration(
				color: AppColors.greenSuccess.withOpacity(0.08),
				borderRadius: BorderRadius.circular(12),
			),
			padding: const EdgeInsets.all(12),
			child: Column(
				children: [
					Row(
						children: [
							Container(
								decoration: BoxDecoration(
									color: AppColors.greenSuccess.withOpacity(0.15),
									borderRadius: BorderRadius.circular(8),
								),
								padding: const EdgeInsets.all(6),
								child: Icon(
									Icons.insights,
									size: 16,
									color: AppColors.greenSuccess,
								),
							),
							const SizedBox(width: 8),
							const Expanded(
								child: Text(
									'Progreso Promedio',
									style: TextStyle(
										fontSize: 11,
										fontWeight: FontWeight.w700,
										color: Colors.black,
									),
								),
							),
							Text(
								'${clamped.toStringAsFixed(1)}%',
								style: TextStyle(
									fontSize: 18,
									fontWeight: FontWeight.w900,
									color: AppColors.greenSuccess,
								),
							),
						],
					),
					const SizedBox(height: 8),
					ClipRRect(
						borderRadius: BorderRadius.circular(6),
						child: LinearProgressIndicator(
							value: clamped / 100,
							backgroundColor: Colors.grey.withOpacity(0.2),
							valueColor: AlwaysStoppedAnimation<Color>(
								AppColors.greenSuccess,
							),
							minHeight: 8,
						),
					),
					const SizedBox(height: 8),
					const Text(
						'Avance de todas las campañas activas',
						style: TextStyle(
							fontSize: 12,
							color: Colors.black87,
							fontWeight: FontWeight.w500,
						),
					),
				],
			),
		);
	}
}

// Pantalla de previsualización del reporte antes de exportar
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
		final campaignsGoalTotal = _sum(widget.activeCampaigns, (c) => c.goalAmount);
		final campaignsRaisedTotal = _sum(widget.activeCampaigns, (c) => c.raisedAmount);
		final averageProgress = widget.activeCampaigns.isEmpty
				? 0.0
				: widget.activeCampaigns.fold<double>(0, (sum, c) => sum + c.completionRatio) / widget.activeCampaigns.length;

		return Scaffold(
			backgroundColor: Colors.grey.shade100,
			appBar: AppBar(
				backgroundColor: AppColors.bluePrimary,
				foregroundColor: Colors.white,
				elevation: 0,
				title: const Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(
							'Previsualización del Reporte',
							style: TextStyle(
								fontSize: 18,
								fontWeight: FontWeight.w700,
							),
						),
						Text(
							'Revisa antes de exportar',
							style: TextStyle(
								fontSize: 12,
								fontWeight: FontWeight.w400,
								color: Colors.white70,
							),
						),
					],
				),
				actions: [
					IconButton(
						icon: const Icon(Icons.info_outline),
						tooltip: 'Información',
						onPressed: () {
							showDialog(
								context: context,
								builder: (context) => AlertDialog(
									title: const Row(
										children: [
											Icon(Icons.info, color: AppColors.bluePrimary),
											SizedBox(width: 12),
											Text('Acerca del reporte'),
										],
									),
									content: const Text(
										'Este reporte incluye todas las métricas y KPIs del panel de análisis. '
										'Puedes personalizar el contenido y formato antes de exportar.',
										style: TextStyle(fontSize: 14),
									),
									actions: [
										TextButton(
											onPressed: () => Navigator.pop(context),
											child: const Text('Entendido'),
										),
									],
								),
							);
						},
					),
				],
			),
			body: Column(
				children: [
					// Panel de configuración
					Container(
						color: Colors.white,
						padding: const EdgeInsets.all(16),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									children: [
										const Icon(Icons.settings, size: 20, color: AppColors.bluePrimary),
										const SizedBox(width: 8),
										const Text(
											'Configuración de exportación',
											style: TextStyle(
												fontSize: 15,
												fontWeight: FontWeight.w700,
												color: Colors.black87,
											),
										),
									],
								),
								const SizedBox(height: 16),
								// Selector de formato
								Row(
									children: [
										_FormatChip(
											label: 'PDF',
											icon: Icons.picture_as_pdf,
											color: Colors.red,
											isSelected: _selectedFormat == 'PDF',
											onTap: () => setState(() => _selectedFormat = 'PDF'),
										),
										const SizedBox(width: 8),
										_FormatChip(
											label: 'Excel',
											icon: Icons.table_chart,
											color: Colors.green,
											isSelected: _selectedFormat == 'Excel',
											onTap: () => setState(() => _selectedFormat = 'Excel'),
										),
										const SizedBox(width: 8),
										_FormatChip(
											label: 'CSV',
											icon: Icons.code,
											color: Colors.blue,
											isSelected: _selectedFormat == 'CSV',
											onTap: () => setState(() => _selectedFormat = 'CSV'),
										),
									],
								),
								const SizedBox(height: 16),
								// Opciones de contenido
								const Text(
									'Incluir en el reporte:',
									style: TextStyle(
										fontSize: 13,
										fontWeight: FontWeight.w600,
										color: Colors.black87,
									),
								),
								const SizedBox(height: 8),
								_OptionSwitch(
									label: 'Gráficos y visualizaciones',
									value: _includeCharts,
									enabled: _selectedFormat == 'PDF',
									onChanged: (val) => setState(() => _includeCharts = val),
								),
								_OptionSwitch(
									label: 'Detalles de campañas activas',
									value: _includeCampaignDetails,
									onChanged: (val) => setState(() => _includeCampaignDetails = val),
								),
								_OptionSwitch(
									label: 'Comparaciones y tendencias',
									value: _includeComparisons,
									onChanged: (val) => setState(() => _includeComparisons = val),
								),
							],
						),
					),
					const SizedBox(height: 2),
					// Preview del contenido
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.all(16),
							child: Container(
								decoration: BoxDecoration(
									color: Colors.white,
									borderRadius: BorderRadius.circular(12),
									boxShadow: [
										BoxShadow(
											color: Colors.black.withOpacity(0.08),
											blurRadius: 12,
											offset: const Offset(0, 4),
										),
									],
								),
								padding: const EdgeInsets.all(24),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										// Header del reporte
										Row(
											children: [
												Container(
													padding: const EdgeInsets.all(12),
													decoration: BoxDecoration(
														color: AppColors.bluePrimary.withOpacity(0.1),
														borderRadius: BorderRadius.circular(12),
													),
													child: const Icon(
														Icons.analytics,
														color: AppColors.bluePrimary,
														size: 32,
													),
												),
												const SizedBox(width: 16),
												Expanded(
													child: Column(
														crossAxisAlignment: CrossAxisAlignment.start,
														children: [
															const Text(
																'Reporte de Métricas',
																style: TextStyle(
																	fontSize: 22,
																	fontWeight: FontWeight.w800,
																	color: Colors.black,
																),
															),
															const SizedBox(height: 4),
															Text(
																'Generado: ${_formatDate(DateTime.now())}',
																style: const TextStyle(
																	fontSize: 13,
																	color: Colors.black54,
																	fontWeight: FontWeight.w500,
																),
															),
														],
													),
												),
											],
										),
										const Divider(height: 32, thickness: 1),
										
										// Resumen ejecutivo
										_SectionTitle(
											icon: Icons.summarize,
											title: 'Resumen Ejecutivo',
											color: AppColors.bluePrimary,
										),
										const SizedBox(height: 16),
										_PreviewMetricRow(
											label: 'Total de Donantes',
											value: widget.metrics.totalDonors.toString(),
											icon: Icons.people,
											color: AppColors.bluePrimary,
										),
										_PreviewMetricRow(
											label: 'Campañas Activas',
											value: widget.metrics.activeCampaigns.toString(),
											icon: Icons.campaign,
											color: AppColors.greenSuccess,
										),
										_PreviewMetricRow(
											label: 'Total Recaudado',
											value: _formatCurrency(campaignsRaisedTotal),
											icon: Icons.attach_money,
											color: AppColors.orangeAction,
										),
										_PreviewMetricRow(
											label: 'Campañas Completadas',
											value: widget.metrics.campaignsCompletedThisMonth.toString(),
											icon: Icons.check_circle,
											color: AppColors.greenSuccess,
										),
										
										const SizedBox(height: 24),
										
										// Indicadores clave
										_SectionTitle(
											icon: Icons.speed,
											title: 'Indicadores Clave de Desempeño (KPIs)',
											color: AppColors.orangeAction,
										),
										const SizedBox(height: 16),
										_PreviewMetricRow(
											label: 'Progreso Promedio',
											value: '${(averageProgress * 100).toStringAsFixed(1)}%',
											icon: Icons.trending_up,
											color: AppColors.greenSuccess,
										),
										_PreviewMetricRow(
											label: 'Meta Total',
											value: _formatCurrency(campaignsGoalTotal),
											icon: Icons.flag,
											color: AppColors.bluePrimary,
										),
										_PreviewMetricRow(
											label: 'Tasa de Aprobación',
											value: '${widget.metrics.approvalRate.toStringAsFixed(1)}%',
											icon: Icons.analytics,
											color: AppColors.orangeAction,
										),
										
										if (_includeCampaignDetails) ...[
											const SizedBox(height: 24),
											_SectionTitle(
												icon: Icons.list_alt,
												title: 'Campañas Activas',
												color: AppColors.greenSuccess,
											),
											const SizedBox(height: 12),
											if (widget.activeCampaigns.isEmpty)
												const Center(
													child: Padding(
														padding: EdgeInsets.all(24),
														child: Text(
															'No hay campañas activas',
															style: TextStyle(
																color: Colors.black54,
																fontSize: 14,
															),
														),
													),
												)
											else
												...widget.activeCampaigns.take(5).map((campaign) {
													return Container(
														margin: const EdgeInsets.only(bottom: 12),
														padding: const EdgeInsets.all(12),
														decoration: BoxDecoration(
															color: Colors.grey.shade50,
															borderRadius: BorderRadius.circular(8),
															border: Border.all(
																color: Colors.grey.shade200,
															),
														),
														child: Row(
															children: [
																Expanded(
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			Text(
																				campaign.title,
																				style: const TextStyle(
																					fontSize: 13,
																					fontWeight: FontWeight.w600,
																					color: Colors.black87,
																				),
																				maxLines: 1,
																				overflow: TextOverflow.ellipsis,
																			),
																			const SizedBox(height: 4),
																			Row(
																				children: [
																					Text(
																						'${(campaign.completionRatio * 100).toStringAsFixed(0)}%',
																						style: TextStyle(
																							fontSize: 12,
																							fontWeight: FontWeight.w700,
																							color: AppColors.greenSuccess,
																						),
																					),
																					const SizedBox(width: 8),
																					Text(
																						'${_formatCurrency(campaign.raisedAmount)} / ${_formatCurrency(campaign.goalAmount)}',
																						style: const TextStyle(
																							fontSize: 11,
																							color: Colors.black54,
																						),
																					),
																				],
																			),
																		],
																	),
																),
															],
														),
													);
												}),
											if (widget.activeCampaigns.length > 5)
												Padding(
													padding: const EdgeInsets.only(top: 8),
													child: Text(
														'+ ${widget.activeCampaigns.length - 5} campañas más',
														style: const TextStyle(
															fontSize: 12,
															color: Colors.black54,
															fontStyle: FontStyle.italic,
														),
													),
												),
										],
										
										if (_includeComparisons) ...[
											const SizedBox(height: 24),
											_SectionTitle(
												icon: Icons.compare_arrows,
												title: 'Análisis Comparativo',
												color: AppColors.bluePrimary,
											),
											const SizedBox(height: 16),
											Container(
												padding: const EdgeInsets.all(16),
												decoration: BoxDecoration(
													color: AppColors.bluePrimary.withOpacity(0.05),
													borderRadius: BorderRadius.circular(8),
												),
												child: Column(
													children: [
														_ComparisonRow(
															label: 'Solicitudes Pendientes',
															value: widget.metrics.pendingRequests,
															total: widget.metrics.pendingRequests + widget.metrics.activeCampaigns,
														),
														const SizedBox(height: 12),
														_ComparisonRow(
															label: 'Donaciones Este Mes',
															value: widget.metrics.donationsThisMonth,
															total: widget.metrics.donationsThisMonth + widget.metrics.donationsLastMonth,
														),
														const SizedBox(height: 12),
														_ComparisonRow(
															label: 'Organizaciones Pendientes',
															value: widget.metrics.pendingOrganizations,
															total: widget.metrics.pendingOrganizations + widget.metrics.activeCampaigns,
														),
													],
												),
											),
										],
										
										const SizedBox(height: 24),
										// Footer
										Container(
											padding: const EdgeInsets.all(16),
											decoration: BoxDecoration(
												color: Colors.grey.shade50,
												borderRadius: BorderRadius.circular(8),
											),
											child: Row(
												children: [
													Icon(Icons.verified, size: 16, color: AppColors.bluePrimary),
													const SizedBox(width: 8),
													const Expanded(
														child: Text(
															'Reporte generado automáticamente por Manos Solidarias',
															style: TextStyle(
																fontSize: 11,
																color: Colors.black54,
															),
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
							color: Colors.black.withOpacity(0.1),
							blurRadius: 8,
							offset: const Offset(0, -2),
						),
					],
				),
				padding: const EdgeInsets.all(16),
				child: Row(
					children: [
						Expanded(
							child: OutlinedButton.icon(
								onPressed: () => Navigator.pop(context),
								style: OutlinedButton.styleFrom(
									padding: const EdgeInsets.symmetric(vertical: 16),
									side: BorderSide(color: Colors.grey.shade300, width: 1.5),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(10),
									),
								),
								icon: const Icon(Icons.close, size: 20),
								label: const Text(
									'Cancelar',
									style: TextStyle(
										fontSize: 15,
										fontWeight: FontWeight.w600,
									),
								),
							),
						),
						const SizedBox(width: 12),
						Expanded(
							flex: 2,
							child: ElevatedButton.icon(
								onPressed: () {
									Navigator.pop(context);
									_showExportProgress(context, _selectedFormat);
								},
								style: ElevatedButton.styleFrom(
									backgroundColor: AppColors.bluePrimary,
									foregroundColor: Colors.white,
									elevation: 2,
									padding: const EdgeInsets.symmetric(vertical: 16),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(10),
									),
								),
								icon: const Icon(Icons.download, size: 20),
								label: Text(
									'Exportar $_selectedFormat',
									style: const TextStyle(
										fontSize: 15,
										fontWeight: FontWeight.w700,
									),
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
			builder: (context) => AlertDialog(
				content: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						const CircularProgressIndicator(),
						const SizedBox(height: 24),
						Text(
							'Exportando reporte como $format...',
							style: const TextStyle(
								fontSize: 15,
								fontWeight: FontWeight.w600,
							),
							textAlign: TextAlign.center,
						),
						const SizedBox(height: 8),
						const Text(
							'Por favor espera',
							style: TextStyle(
								fontSize: 13,
								color: Colors.black54,
							),
						),
					],
				),
			),
		);

		// Simular exportación
		Future.delayed(const Duration(seconds: 2), () {
			Navigator.pop(context);
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Row(
						children: [
							const Icon(Icons.check_circle, color: Colors.white),
							const SizedBox(width: 12),
							Expanded(
								child: Text('Reporte exportado como $format exitosamente'),
							),
						],
					),
					backgroundColor: AppColors.greenSuccess,
					behavior: SnackBarBehavior.floating,
					duration: const Duration(seconds: 3),
				),
			);
		});
	}

	double _sum(List<AdminActiveCampaign> campaigns, double Function(AdminActiveCampaign) selector) {
		double total = 0;
		for (final campaign in campaigns) {
			total += selector(campaign);
		}
		return total;
	}

	String _formatCurrency(double value) {
		final formatted = value.toStringAsFixed(0).replaceAllMapped(
			RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
			(Match m) => '${m[1]},',
		);
		return 'Bs $formatted';
	}

	String _formatDate(DateTime date) {
		final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
		return '${date.day} ${months[date.month - 1]} ${date.year}';
	}
}

// Widget: Chip de formato
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
					padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
					decoration: BoxDecoration(
						color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
						borderRadius: BorderRadius.circular(10),
						border: Border.all(
							color: isSelected ? color : Colors.grey.shade300,
							width: isSelected ? 2 : 1,
						),
					),
					child: Row(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(
								icon,
								color: isSelected ? color : Colors.grey.shade600,
								size: 20,
							),
							const SizedBox(width: 6),
							Text(
								label,
								style: TextStyle(
									fontSize: 13,
									fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
									color: isSelected ? color : Colors.grey.shade700,
								),
							),
						],
					),
				),
			),
		);
	}
}

// Widget: Switch de opciones
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
			padding: const EdgeInsets.only(bottom: 4),
			child: Row(
				children: [
					Expanded(
						child: Text(
							label,
							style: TextStyle(
								fontSize: 13,
								color: enabled ? Colors.black87 : Colors.black38,
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

// Widget: Título de sección
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
					padding: const EdgeInsets.all(6),
					decoration: BoxDecoration(
						color: color.withOpacity(0.1),
						borderRadius: BorderRadius.circular(6),
					),
					child: Icon(icon, size: 18, color: color),
				),
				const SizedBox(width: 10),
				Text(
					title,
					style: TextStyle(
						fontSize: 16,
						fontWeight: FontWeight.w700,
						color: color,
					),
				),
			],
		);
	}
}

// Widget: Fila de métrica en preview
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
			padding: const EdgeInsets.only(bottom: 12),
			child: Row(
				children: [
					Icon(icon, size: 20, color: color.withOpacity(0.7)),
					const SizedBox(width: 12),
					Expanded(
						child: Text(
							label,
							style: const TextStyle(
								fontSize: 13,
								color: Colors.black87,
								fontWeight: FontWeight.w500,
							),
						),
					),
					Text(
						value,
						style: TextStyle(
							fontSize: 14,
							fontWeight: FontWeight.w700,
							color: color,
						),
					),
				],
			),
		);
	}
}

// Widget: Fila de comparación
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
		final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
		
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children: [
						Text(
							label,
							style: const TextStyle(
								fontSize: 12,
								color: Colors.black87,
								fontWeight: FontWeight.w600,
							),
						),
						Text(
							'$value ($percentage%)',
							style: const TextStyle(
								fontSize: 12,
								fontWeight: FontWeight.w700,
								color: AppColors.bluePrimary,
							),
						),
					],
				),
				const SizedBox(height: 6),
				ClipRRect(
					borderRadius: BorderRadius.circular(4),
					child: LinearProgressIndicator(
						value: total > 0 ? value / total : 0,
						backgroundColor: Colors.grey.shade200,
						valueColor: const AlwaysStoppedAnimation<Color>(AppColors.bluePrimary),
						minHeight: 6,
					),
				),
			],
		);
	}
}
