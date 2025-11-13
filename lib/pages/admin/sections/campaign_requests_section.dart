import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/admin_dashboard_controller.dart';
import '../../../models/admin_dashboard.dart';
import '../../../models/category.dart';
import '../../../models/solicitud.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import 'admin_section_widgets.dart';

class CampaignRequestsSection extends StatelessWidget {
	const CampaignRequestsSection({
		super.key,
		required this.items,
		required this.onReview,
	});

	final List<AdminPendingItem> items;
	final ValueChanged<AdminPendingItem> onReview;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				const AdminSectionHeading(
					title: 'Solicitudes solidarias',
					description: 'Revisa campañas y kermesses enviadas por los organizadores.',
				),
				const SizedBox(height: 18),
				if (items.isEmpty)
					const AdminEmptyState(message: 'No hay solicitudes de campaña pendientes.')
				else
					...items.indexed.map(
						(entry) => Padding(
							padding: EdgeInsets.only(bottom: entry.$1 == items.length - 1 ? 0 : 14),
							child: CampaignRequestCard(
								item: entry.$2,
								onReview: () => onReview(entry.$2),
							),
						),
					),
			],
		);
	}
}

class CampaignRequestCard extends StatelessWidget {
	const CampaignRequestCard({
		super.key,
		required this.item,
		required this.onReview,
	});

	final AdminPendingItem item;
	final VoidCallback onReview;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final subtitle = item.subtitle?.trim();
		final formattedDate = formatAdminDateTime(item.createdAt);
		final badge = item.solicitudTipo != null && item.solicitudTipo != SolicitudTipo.campania
				? SolicitudTypeBadge(tipo: item.solicitudTipo!)
				: null;

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
										color: AppColors.orangeAction.withValues(alpha: 0.2),
										borderRadius: BorderRadius.circular(14),
									),
									child: const Icon(Icons.assignment_outlined, color: AppColors.orangeAction),
								),
								const SizedBox(width: 14),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Row(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Expanded(
														child: Text(
															item.title,
															maxLines: 2,
															overflow: TextOverflow.ellipsis,
															style: theme.textTheme.titleMedium?.copyWith(
																		fontWeight: FontWeight.w700,
																		color: AppColors.darkText,
																	),
														),
													),
													if (badge != null) badge,
												],
											),
											const SizedBox(height: 6),
											Text(
												'Recibida el $formattedDate',
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
							child: FilledButton.icon(
								onPressed: onReview,
								icon: const Icon(Icons.rate_review_outlined),
								label: const Text('Revisar solicitud'),
							),
						),
					],
				),
			),
		);
	}
}

class SolicitudTypeBadge extends StatelessWidget {
	const SolicitudTypeBadge({super.key, required this.tipo});

	final SolicitudTipo tipo;

	@override
	Widget build(BuildContext context) {
		late final String label;
		late final Color color;
		late final IconData icon;

		switch (tipo) {
			case SolicitudTipo.kermesse:
				label = 'Kermesse';
				color = AppColors.greenHope;
				icon = Icons.festival_outlined;
				break;
			case SolicitudTipo.rifa:
				label = 'Rifa';
				color = AppColors.bluePrimary;
				icon = Icons.confirmation_number_outlined;
				break;
			case SolicitudTipo.campania:
				label = 'Campaña';
				color = AppColors.orangeAction;
				icon = Icons.flag_outlined;
				break;
		}

		final theme = Theme.of(context);
		return Container(
			margin: const EdgeInsets.only(left: 8),
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(999),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, size: 14, color: color),
					const SizedBox(width: 4),
					Text(
						label,
						style: theme.textTheme.labelSmall?.copyWith(
									color: color,
									fontWeight: FontWeight.w600,
								),
					),
				],
			),
		);
	}
}

enum CampaignReviewResult { approved, changesRequested }

Future<CampaignReviewResult?> showCampaignReviewSheet({
	required BuildContext context,
	required AdminPendingItem item,
	required Future<void> Function(String? categoriaId) onApprove,
	required Future<void> Function(String message) onRequestChanges,
}) {
	return showModalBottomSheet<CampaignReviewResult>(
		context: context,
		isScrollControlled: true,
		backgroundColor: Colors.transparent,
		builder: (context) => CampaignReviewSheet(
			item: item,
			onApprove: onApprove,
			onRequestChanges: onRequestChanges,
		),
	);
}

class CampaignReviewSheet extends StatefulWidget {
	const CampaignReviewSheet({
		super.key,
		required this.item,
		required this.onApprove,
		required this.onRequestChanges,
	});

	final AdminPendingItem item;
	final Future<void> Function(String? categoriaId) onApprove;
	final Future<void> Function(String message) onRequestChanges;

	@override
	State<CampaignReviewSheet> createState() => _CampaignReviewSheetState();
}

class _CampaignReviewSheetState extends State<CampaignReviewSheet> {
	final TextEditingController _messageCtrl = TextEditingController();
	bool _isSubmitting = false;
	String? _error;
	String? _selectedCategoryId;
	List<Category>? _categories;
	bool _loadingCategories = false;

	@override
	void initState() {
		super.initState();
		_selectedCategoryId = widget.item.categoriaId;
		_loadCategories();
	}

	Future<void> _loadCategories() async {
		if (widget.item.solicitudTipo != SolicitudTipo.campania) {
			return;
		}
		setState(() => _loadingCategories = true);
		try {
			final service = AdminService(Supabase.instance.client);
			final categories = await service.fetchActiveCategories();
			if (!mounted) return;
			setState(() {
				_categories = categories;
				_loadingCategories = false;
			});
		} catch (_) {
			if (!mounted) return;
			setState(() => _loadingCategories = false);
		}
	}

	@override
	void dispose() {
		_messageCtrl.dispose();
		super.dispose();
	}

	Future<void> _handleApprove() async {
		if (_isSubmitting) return;
		
		// Validate category for campaigns
		if (widget.item.solicitudTipo == SolicitudTipo.campania && _selectedCategoryId == null) {
			setState(() => _error = 'Debes seleccionar una categoría para aprobar esta campaña.');
			return;
		}

		setState(() {
			_isSubmitting = true;
			_error = null;
		});
		try {
			await widget.onApprove(_selectedCategoryId);
			if (!mounted) return;
			Navigator.of(context).pop(CampaignReviewResult.approved);
		} on AdminActionException catch (error) {
			if (!mounted) return;
			setState(() => _error = error.message);
		} finally {
			if (mounted) {
				setState(() => _isSubmitting = false);
			}
		}
	}

	Future<void> _handleRequestChanges() async {
		if (_isSubmitting) return;
		final message = _messageCtrl.text.trim();
		if (message.isEmpty) {
			setState(() => _error = 'Describe los ajustes que necesita la campaña.');
			return;
		}

		setState(() {
			_isSubmitting = true;
			_error = null;
		});
		try {
			await widget.onRequestChanges(message);
			if (!mounted) return;
			Navigator.of(context).pop(CampaignReviewResult.changesRequested);
		} on AdminActionException catch (error) {
			if (!mounted) return;
			setState(() => _error = error.message);
		} finally {
			if (mounted) {
				setState(() => _isSubmitting = false);
			}
		}
	}

	IconData _getCategoryIcon(String iconName) {
		switch (iconName) {
			case 'medical_services':
				return Icons.medical_services;
			case 'school':
				return Icons.school;
			case 'restaurant':
				return Icons.restaurant;
			case 'home':
				return Icons.home;
			case 'emergency':
				return Icons.emergency;
			case 'work':
				return Icons.work;
			case 'accessible':
				return Icons.accessible;
			case 'elderly':
				return Icons.elderly;
			case 'child_care':
				return Icons.child_care;
			case 'pets':
				return Icons.pets;
			case 'eco':
				return Icons.eco;
			case 'sports_soccer':
				return Icons.sports_soccer;
			case 'palette':
				return Icons.palette;
			case 'festival':
				return Icons.festival;
			case 'groups':
				return Icons.groups;
			case 'category':
			default:
				return Icons.category;
		}
	}

	Color _parseColor(String colorHex) {
		try {
			final hex = colorHex.replaceAll('#', '');
			return Color(int.parse('FF$hex', radix: 16));
		} catch (_) {
			return Colors.grey;
		}
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final formattedDate = formatAdminDate(widget.item.createdAt);

		return SafeArea(
			top: false,
			child: Container(
				decoration: const BoxDecoration(
					gradient: LinearGradient(
						begin: Alignment.topCenter,
						end: Alignment.bottomCenter,
						colors: [
							Colors.black54,
							Colors.transparent,
							Colors.transparent,
						],
					),
				),
				child: DraggableScrollableSheet(
					initialChildSize: 0.7,
					minChildSize: 0.45,
					maxChildSize: 0.9,
					builder: (context, controller) {
						return DecoratedBox(
							decoration: const BoxDecoration(
								color: Colors.white,
								borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
							),
							child: ListView(
								controller: controller,
								padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
								children: [
									Center(
										child: Container(
											width: 48,
											height: 4,
											decoration: BoxDecoration(
												color: AppColors.grayNeutral.withValues(alpha: 0.3),
												borderRadius: BorderRadius.circular(2),
											),
										),
									),
									const SizedBox(height: 20),
									Row(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Expanded(
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: const [
														Text(
															'Revisión de solicitud',
															style: TextStyle(
																fontWeight: FontWeight.bold,
																color: Colors.black,
																fontSize: 24,
															),
														),
														SizedBox(height: 4),
														Text(
															'Evalúa los detalles y decide si aprobar',
															style: TextStyle(
																color: Colors.black54,
																fontSize: 15,
															),
														),
													],
												),
											),
											const SizedBox(width: 12),
											_buildWaitingTimeBadge(context, widget.item.createdAt),
										],
									),
									const SizedBox(height: 24),
									// Título en negrita
									Text(
										widget.item.title,
										style: const TextStyle(
											fontWeight: FontWeight.w900,
											color: Colors.black,
											fontSize: 24,
											height: 1.3,
											letterSpacing: -0.5,
										),
									),
									const SizedBox(height: 12),
									// Badges
									Wrap(
										spacing: 8,
										runSpacing: 8,
										children: [
											if (widget.item.solicitudTipo != null)
												Container(
													padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
													decoration: BoxDecoration(
														color: AppColors.bluePrimary,
														borderRadius: BorderRadius.circular(6),
													),
													child: Row(
														mainAxisSize: MainAxisSize.min,
														children: [
															Icon(
																_getTypeIcon(widget.item.solicitudTipo!),
																size: 14,
																color: Colors.white,
															),
															const SizedBox(width: 6),
															Text(
																_getTypeLabel(widget.item.solicitudTipo!),
																style: const TextStyle(
																	fontSize: 13,
																	fontWeight: FontWeight.w600,
																	color: Colors.white,
																),
															),
														],
													),
												),
											Container(
												padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
												decoration: BoxDecoration(
													color: Colors.black87,
													borderRadius: BorderRadius.circular(6),
												),
												child: Row(
													mainAxisSize: MainAxisSize.min,
													children: [
														const Icon(
															Icons.calendar_today,
															size: 13,
															color: Colors.white,
														),
														const SizedBox(width: 6),
														Text(
															formattedDate,
															style: const TextStyle(
																fontSize: 13,
																fontWeight: FontWeight.w600,
																color: Colors.white,
															),
														),
													],
												),
											),
										],
									),
									const SizedBox(height: 24),
									// Descripción
									if ((widget.item.subtitle ?? '').trim().isNotEmpty) ...[
										Text(
											widget.item.subtitle!,
											style: const TextStyle(
												color: Colors.black87,
												fontSize: 16,
												height: 1.7,
											),
										),
										const SizedBox(height: 24),
									],
									// Datos del beneficiario
									if (widget.item.beneficiaryName != null) ...[
										const Text(
											'Datos del beneficiario',
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
												color: Colors.grey[100],
												borderRadius: BorderRadius.circular(12),
											),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Row(
														children: [
															const Text(
																'Nombre: ',
																style: TextStyle(
																	fontWeight: FontWeight.w700,
																	color: Colors.black,
																	fontSize: 15,
																),
															),
															Expanded(
																child: Text(
																	widget.item.beneficiaryName!,
																	style: const TextStyle(
																		color: Colors.black87,
																		fontSize: 15,
																	),
																),
															),
														],
													),
													if (widget.item.beneficiaryRelation != null) ...[
														const SizedBox(height: 8),
														Row(
															children: [
																const Text(
																	'Relación: ',
																	style: TextStyle(
																		fontWeight: FontWeight.w700,
																		color: Colors.black,
																		fontSize: 15,
																	),
																),
																Expanded(
																	child: Text(
																		widget.item.beneficiaryRelation!,
																		style: const TextStyle(
																			color: Colors.black87,
																			fontSize: 15,
																		),
																	),
																),
															],
														),
													],
												],
											),
										),
										const SizedBox(height: 24),
									],
									// Evidencias fotográficas
									if (widget.item.evidenceUrls != null && widget.item.evidenceUrls!.isNotEmpty) ...[
										const Text(
											'Evidencias fotográficas',
											style: TextStyle(
												fontWeight: FontWeight.w900,
												color: Colors.black,
												fontSize: 18,
											),
										),
										const SizedBox(height: 12),
										GridView.builder(
											shrinkWrap: true,
											physics: const NeverScrollableScrollPhysics(),
											gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
												crossAxisCount: 2,
												crossAxisSpacing: 12,
												mainAxisSpacing: 12,
												childAspectRatio: 1,
											),
											itemCount: widget.item.evidenceUrls!.length,
											itemBuilder: (context, index) {
												final url = widget.item.evidenceUrls![index];
												return ClipRRect(
													borderRadius: BorderRadius.circular(12),
													child: Image.network(
														url,
														fit: BoxFit.cover,
														loadingBuilder: (context, child, loadingProgress) {
															if (loadingProgress == null) return child;
															return Container(
																color: Colors.grey[200],
																child: const Center(
																	child: CircularProgressIndicator(strokeWidth: 2),
																),
															);
														},
														errorBuilder: (context, error, stackTrace) {
															return Container(
																color: Colors.grey[300],
																child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
															);
														},
													),
												);
											},
										),
										const SizedBox(height: 24),
									],
									// Información de Kermesse
									if (widget.item.solicitudTipo == SolicitudTipo.kermesse) ...[
										const Text(
											'Detalles del evento',
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
												color: Colors.grey[100],
												borderRadius: BorderRadius.circular(12),
											),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													if (widget.item.kermesseDate != null) ...[
														Row(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																const Icon(Icons.event, size: 20, color: AppColors.bluePrimary),
																const SizedBox(width: 10),
																Expanded(
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			const Text(
																				'Fecha y horario',
																				style: TextStyle(
																					fontWeight: FontWeight.w700,
																					color: Colors.black,
																					fontSize: 14,
																				),
																			),
																			const SizedBox(height: 4),
																			Text(
																				widget.item.kermesseDate!,
																				style: const TextStyle(
																					color: Colors.black87,
																					fontSize: 15,
																				),
																			),
																		],
																	),
																),
															],
														),
														const SizedBox(height: 16),
													],
													if (widget.item.kermesseBeneficiaries != null) ...[
														Row(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																const Icon(Icons.people, size: 20, color: AppColors.greenSuccess),
																const SizedBox(width: 10),
																Expanded(
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			const Text(
																				'Beneficiarios',
																				style: TextStyle(
																					fontWeight: FontWeight.w700,
																					color: Colors.black,
																					fontSize: 14,
																				),
																			),
																			const SizedBox(height: 4),
																			Text(
																				widget.item.kermesseBeneficiaries!,
																				style: const TextStyle(
																					color: Colors.black87,
																					fontSize: 15,
																				),
																			),
																		],
																	),
																),
															],
														),
														const SizedBox(height: 16),
													],
													if (widget.item.kermessePurpose != null) ...[
														Row(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																const Icon(Icons.attach_money, size: 20, color: AppColors.orangeAction),
																const SizedBox(width: 10),
																Expanded(
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			const Text(
																				'Uso de fondos',
																				style: TextStyle(
																					fontWeight: FontWeight.w700,
																					color: Colors.black,
																					fontSize: 14,
																				),
																			),
																			const SizedBox(height: 4),
																			Text(
																				widget.item.kermessePurpose!,
																				style: const TextStyle(
																					color: Colors.black87,
																					fontSize: 15,
																				),
																			),
																		],
																	),
																),
															],
														),
													],
												],
											),
										),
										const SizedBox(height: 16),
									],
									// Menú y Shows
									if (widget.item.solicitudTipo == SolicitudTipo.kermesse) ...[
										if (widget.item.kermesseMenu != null) ...[
											const Text(
												'Menú y precios',
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
													color: AppColors.orangeAction.withValues(alpha: 0.05),
													borderRadius: BorderRadius.circular(12),
													border: Border.all(
														color: AppColors.orangeAction.withValues(alpha: 0.2),
													),
												),
												child: Row(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														const Icon(Icons.restaurant_menu, size: 20, color: AppColors.orangeAction),
														const SizedBox(width: 12),
														Expanded(
															child: Text(
																widget.item.kermesseMenu!,
																style: const TextStyle(
																	color: Colors.black87,
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
										if (widget.item.kermesseShows != null) ...[
											const Text(
												'Entretenimiento y actividades',
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
													color: AppColors.greenSuccess.withValues(alpha: 0.05),
													borderRadius: BorderRadius.circular(12),
													border: Border.all(
														color: AppColors.greenSuccess.withValues(alpha: 0.2),
													),
												),
												child: Row(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														const Icon(Icons.celebration, size: 20, color: AppColors.greenSuccess),
														const SizedBox(width: 12),
														Expanded(
															child: Text(
																widget.item.kermesseShows!,
																style: const TextStyle(
																	color: Colors.black87,
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
									],
									// Ubicación de la Kermesse (solo para kermesses con ubicación)
									if (widget.item.solicitudTipo == SolicitudTipo.kermesse &&
											widget.item.kermesseLatitude != null &&
											widget.item.kermesseLongitude != null) ...[
										const Text(
											'Ubicación del evento',
											style: TextStyle(
												fontWeight: FontWeight.w900,
												color: Colors.black,
												fontSize: 18,
											),
										),
										const SizedBox(height: 12),
										if (widget.item.kermesseAddress != null) ...[
											Container(
												padding: const EdgeInsets.all(14),
												decoration: BoxDecoration(
													color: AppColors.bluePrimary.withValues(alpha: 0.1),
													borderRadius: BorderRadius.circular(10),
												),
												child: Row(
													children: [
														const Icon(
															Icons.location_on,
															color: AppColors.bluePrimary,
															size: 20,
														),
														const SizedBox(width: 10),
														Expanded(
															child: Text(
																widget.item.kermesseAddress!,
																style: const TextStyle(
																	color: Colors.black87,
																	fontSize: 15,
																	fontWeight: FontWeight.w500,
																),
															),
														),
													],
												),
											),
											const SizedBox(height: 12),
										],
										ClipRRect(
											borderRadius: BorderRadius.circular(12),
											child: SizedBox(
												height: 250,
												child: FlutterMap(
													options: MapOptions(
														initialCenter: LatLng(
															widget.item.kermesseLatitude!,
															widget.item.kermesseLongitude!,
														),
														initialZoom: 15.0,
														interactionOptions: const InteractionOptions(
															flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
														),
													),
													children: [
														TileLayer(
															urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
															userAgentPackageName: 'com.manoslibres.manos_solidarias',
														),
														MarkerLayer(
															markers: [
																Marker(
																	point: LatLng(
																		widget.item.kermesseLatitude!,
																		widget.item.kermesseLongitude!,
																	),
																	width: 40,
																	height: 40,
																	child: const Icon(
																		Icons.location_pin,
																		color: Colors.red,
																		size: 40,
																	),
																),
															],
														),
													],
												),
											),
										),
										const SizedBox(height: 24),
									],
									const SizedBox(height: 8),
									// Sección de comentarios
									const Text(
										'Comentarios para el organizador',
										style: TextStyle(
											fontWeight: FontWeight.w900,
											color: Colors.black,
											fontSize: 18,
										),
									),
									const SizedBox(height: 8),
									const Text(
										'Si necesitas cambios, describe qué ajustes requieres (opcional)',
										style: TextStyle(
											color: Colors.black54,
											fontSize: 14,
											height: 1.4,
										),
									),
									const SizedBox(height: 12),
									TextField(
										controller: _messageCtrl,
										enabled: !_isSubmitting,
										maxLines: 5,
										minLines: 3,
										decoration: InputDecoration(
											border: OutlineInputBorder(
												borderRadius: BorderRadius.circular(12),
											),
											hintText: 'Ej: Por favor agrega más evidencias fotográficas del beneficiario.',
											contentPadding: const EdgeInsets.all(16),
										),
									),
									if (_error != null) ...[
										const SizedBox(height: 12),
										Container(
											decoration: BoxDecoration(
												color: AppColors.orangeAction.withValues(alpha: 0.1),
												borderRadius: BorderRadius.circular(12),
											),
											padding: const EdgeInsets.all(12),
											child: Row(
												children: [
													const Icon(Icons.error_outline, size: 18, color: AppColors.orangeAction),
													const SizedBox(width: 8),
													Expanded(
														child: Text(
															_error!,
															style: theme.textTheme.bodySmall?.copyWith(color: AppColors.orangeAction),
														),
													),
												],
											),
										),
									],
									// Category selector for campaigns
									if (widget.item.solicitudTipo == SolicitudTipo.campania) ...[
										const SizedBox(height: 24),
										const Text(
											'Categoría de la campaña',
											style: TextStyle(
												fontWeight: FontWeight.w900,
												color: Colors.black,
												fontSize: 18,
											),
										),
										const SizedBox(height: 8),
										const Text(
											'Selecciona la categoría que mejor describe esta campaña',
											style: TextStyle(
												color: Colors.black54,
												fontSize: 14,
												height: 1.4,
											),
										),
										const SizedBox(height: 12),
										if (_loadingCategories)
											const Center(
												child: Padding(
													padding: EdgeInsets.all(16.0),
													child: CircularProgressIndicator(),
												),
											)
										else if (_categories != null && _categories!.isNotEmpty)
											Container(
												decoration: BoxDecoration(
													border: Border.all(color: Colors.grey.shade300),
													borderRadius: BorderRadius.circular(12),
												),
												padding: const EdgeInsets.symmetric(horizontal: 12),
												child: DropdownButtonHideUnderline(
													child: DropdownButton<String>(
														isExpanded: true,
														value: _selectedCategoryId,
														hint: const Text('Selecciona una categoría'),
														items: _categories!.map((category) {
															return DropdownMenuItem<String>(
																value: category.id,
																child: Row(
																	children: [
																		Icon(
																			_getCategoryIcon(category.icono),
																			size: 20,
																			color: _parseColor(category.color),
																		),
																		const SizedBox(width: 12),
																		Text(category.nombre),
																	],
																),
															);
														}).toList(),
														onChanged: _isSubmitting ? null : (value) {
															setState(() {
																_selectedCategoryId = value;
																_error = null;
															});
														},
													),
												),
											)
										else
											const Text(
												'No hay categorías disponibles',
												style: TextStyle(
													color: Colors.black54,
													fontSize: 14,
												),
											),
									],
									const SizedBox(height: 32),
									if (_isSubmitting) ...[
										const Center(
											child: CircularProgressIndicator(),
										),
										const SizedBox(height: 16),
									] else ...[
										// Botón de aprobar
										SizedBox(
											width: double.infinity,
											child: FilledButton.icon(
												onPressed: () => _showConfirmDialog(
													context,
													title: '¿Aprobar campaña?',
													message: 'La campaña será publicada y los usuarios podrán verla y donar.',
													confirmText: 'Aprobar',
													isDestructive: false,
													onConfirm: _handleApprove,
												),
												style: FilledButton.styleFrom(
													padding: const EdgeInsets.symmetric(vertical: 16),
													backgroundColor: AppColors.greenSuccess,
													shape: RoundedRectangleBorder(
														borderRadius: BorderRadius.circular(12),
													),
												),
												icon: const Icon(Icons.check_circle),
												label: const Text(
													'Aprobar campaña',
													style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
												),
											),
										),
										const SizedBox(height: 12),
										// Botón de solicitar cambios
										SizedBox(
											width: double.infinity,
											child: OutlinedButton.icon(
												onPressed: () => _showConfirmDialog(
													context,
													title: '¿Solicitar cambios?',
													message: 'Se notificará al organizador que debe realizar ajustes.',
													confirmText: 'Solicitar',
													isDestructive: false,
													onConfirm: _handleRequestChanges,
												),
												style: OutlinedButton.styleFrom(
													padding: const EdgeInsets.symmetric(vertical: 16),
													side: BorderSide(color: AppColors.grayNeutral.withValues(alpha: 0.3)),
													foregroundColor: AppColors.darkText,
													shape: RoundedRectangleBorder(
														borderRadius: BorderRadius.circular(12),
													),
												),
												icon: const Icon(Icons.rate_review_outlined),
												label: const Text(
													'Solicitar cambios',
													style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
												),
											),
										),
									],
								],
							),
						);
					},
				),
			),
		);
	}

	Future<void> _showConfirmDialog(
		BuildContext context, {
		required String title,
		required String message,
		required String confirmText,
		required bool isDestructive,
		required VoidCallback onConfirm,
	}) async {
		final confirmed = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: Row(
					children: [
						Icon(
							isDestructive ? Icons.warning_rounded : Icons.info_outline_rounded,
							color: isDestructive ? AppColors.orangeAction : AppColors.bluePrimary,
						),
						const SizedBox(width: 12),
						Expanded(
							child: Text(title),
						),
					],
				),
				content: Text(message),
				actions: [
					TextButton(
						onPressed: () => Navigator.of(context).pop(false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						onPressed: () => Navigator.of(context).pop(true),
						style: FilledButton.styleFrom(
							backgroundColor: isDestructive 
								? AppColors.orangeAction 
								: AppColors.greenSuccess,
						),
						child: Text(confirmText),
					),
				],
			),
		);

		if (confirmed == true) {
			onConfirm();
		}
	}

	IconData _getTypeIcon(SolicitudTipo type) {
		switch (type) {
			case SolicitudTipo.campania:
				return Icons.campaign_outlined;
			case SolicitudTipo.kermesse:
				return Icons.celebration_outlined;
			case SolicitudTipo.rifa:
				return Icons.card_giftcard_outlined;
		}
	}

	String _getTypeLabel(SolicitudTipo type) {
		return type.displayName;
	}

	Widget _buildWaitingTimeBadge(BuildContext context, DateTime createdAt) {
		final now = DateTime.now();
		final difference = now.difference(createdAt);
		final days = difference.inDays;
		final hours = difference.inHours;
		
		late final String label;
		late final Color color;
		
		if (days > 7) {
			label = '+7 días';
			color = AppColors.orangeAction;
		} else if (days > 3) {
			label = '$days días';
			color = AppColors.orangeAction.withValues(alpha: 0.8);
		} else if (days > 0) {
			label = '$days días';
			color = AppColors.bluePrimary;
		} else if (hours > 0) {
			label = '$hours hrs';
			color = AppColors.greenSuccess;
		} else {
			label = 'Nueva';
			color = AppColors.greenSuccess;
		}
		
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.15),
				borderRadius: BorderRadius.circular(20),
				border: Border.all(
					color: color.withValues(alpha: 0.3),
					width: 1.5,
				),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(
						Icons.access_time_rounded,
						size: 14,
						color: color,
					),
					const SizedBox(width: 4),
					Text(
						label,
						style: TextStyle(
							fontSize: 12,
							fontWeight: FontWeight.bold,
							color: color,
						),
					),
				],
			),
		);
	}
}
