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

class CampaignRequestsSection extends StatefulWidget {
	const CampaignRequestsSection({
		super.key,
		required this.items,
		required this.onReview,
	});

	final List<AdminPendingItem> items;
	final ValueChanged<AdminPendingItem> onReview;

	@override
	State<CampaignRequestsSection> createState() => _CampaignRequestsSectionState();
}

class _CampaignRequestsSectionState extends State<CampaignRequestsSection> {
	SolicitudTipo? _activeFilter;

	@override
	Widget build(BuildContext context) {
		final filtered = _activeFilter == null
				? widget.items
				: widget.items.where((e) => e.solicitudTipo == _activeFilter).toList();

		final countCampania = widget.items
				.where((e) => e.solicitudTipo == SolicitudTipo.campania || e.solicitudTipo == null)
				.length;
		final countKermesse =
				widget.items.where((e) => e.solicitudTipo == SolicitudTipo.kermesse).length;
		final countRifa =
				widget.items.where((e) => e.solicitudTipo == SolicitudTipo.rifa).length;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				const AdminSectionHeading(
					title: 'Solicitudes solidarias',
					description: 'Revisa campañas y kermesses enviadas por los organizadores.',
				),
				const SizedBox(height: 14),
				SingleChildScrollView(
					scrollDirection: Axis.horizontal,
					child: Row(
						children: [
							_FilterChip(
								label: 'Todas',
								count: widget.items.length,
								isActive: _activeFilter == null,
								color: AppColors.bluePrimary,
								icon: Icons.all_inclusive_rounded,
								onTap: () => setState(() => _activeFilter = null),
							),
							const SizedBox(width: 8),
							_FilterChip(
								label: 'Campañas',
								count: countCampania,
								isActive: _activeFilter == SolicitudTipo.campania,
								color: AppColors.orangeAction,
								icon: Icons.campaign_outlined,
								onTap: () => setState(() => _activeFilter = SolicitudTipo.campania),
							),
							const SizedBox(width: 8),
							_FilterChip(
								label: 'Kermesse',
								count: countKermesse,
								isActive: _activeFilter == SolicitudTipo.kermesse,
								color: AppColors.greenHope,
								icon: Icons.festival_outlined,
								onTap: () => setState(() => _activeFilter = SolicitudTipo.kermesse),
							),
							const SizedBox(width: 8),
							_FilterChip(
								label: 'Rifas',
								count: countRifa,
								isActive: _activeFilter == SolicitudTipo.rifa,
								color: const Color(0xFF6750A4),
								icon: Icons.confirmation_number_outlined,
								onTap: () => setState(() => _activeFilter = SolicitudTipo.rifa),
							),
						],
					),
				),
				const SizedBox(height: 18),
				if (filtered.isEmpty)
					const AdminEmptyState(message: 'No hay solicitudes de campaña pendientes.')
				else
					...filtered.indexed.map(
						(entry) => Padding(
							padding: EdgeInsets.only(bottom: entry.$1 == filtered.length - 1 ? 0 : 14),
							child: CampaignRequestCard(
								item: entry.$2,
								onReview: () => widget.onReview(entry.$2),
							),
						),
					),
			],
		);
	}
}

// ── Private review widgets ──────────────────────────────────────────────────

class _ReviewSectionCard extends StatelessWidget {
	const _ReviewSectionCard({
		required this.icon,
		required this.iconColor,
		required this.title,
		required this.child,
		this.subtitle,
	});

	final IconData icon;
	final Color iconColor;
	final String title;
	final Widget child;
	final String? subtitle;

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(16),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withValues(alpha: 0.04),
						blurRadius: 10,
						offset: const Offset(0, 3),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
						child: Row(
							children: [
								Container(
									padding: const EdgeInsets.all(8),
									decoration: BoxDecoration(
										color: iconColor.withValues(alpha: 0.12),
										borderRadius: BorderRadius.circular(10),
									),
									child: Icon(icon, size: 16, color: iconColor),
								),
								const SizedBox(width: 10),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												title,
												style: TextStyle(
													fontWeight: FontWeight.w800,
													color: AppColors.darkText,
													fontSize: 14,
												),
											),
											if (subtitle != null) ...[
												const SizedBox(height: 2),
												Text(
													subtitle!,
													style: TextStyle(
														color: Colors.grey.shade500,
														fontSize: 12,
													),
												),
											],
										],
									),
								),
							],
						),
					),
					Divider(
						height: 16,
						indent: 14,
						endIndent: 14,
						color: Colors.grey.shade100,
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
						child: child,
					),
				],
			),
		);
	}
}

class _ReviewInfoRow extends StatelessWidget {
	const _ReviewInfoRow({
		required this.label,
		required this.value,
		this.icon,
		this.iconColor,
	});

	final String label;
	final String value;
	final IconData? icon;
	final Color? iconColor;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.only(bottom: 10),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					if (icon != null) ...[
						Container(
							margin: const EdgeInsets.only(top: 2),
							padding: const EdgeInsets.all(6),
							decoration: BoxDecoration(
								color: (iconColor ?? AppColors.bluePrimary).withValues(alpha: 0.10),
								borderRadius: BorderRadius.circular(8),
							),
							child: Icon(
								icon,
								size: 14,
								color: iconColor ?? AppColors.bluePrimary,
							),
						),
						const SizedBox(width: 10),
					],
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									label,
									style: const TextStyle(
										fontWeight: FontWeight.w600,
										color: AppColors.darkText,
										fontSize: 12,
									),
								),
								const SizedBox(height: 2),
								Text(
									value,
									style: const TextStyle(
										color: Colors.black87,
										fontSize: 13,
										height: 1.4,
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
		final typeColor = _typeColor(item.solicitudTipo);
		final typeIcon = _typeIcon(item.solicitudTipo);

		return Container(
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(20),
				border: Border(
					left: BorderSide(color: typeColor, width: 4),
				),
				boxShadow: [
					BoxShadow(
						color: typeColor.withValues(alpha: 0.10),
						blurRadius: 14,
						offset: const Offset(0, 4),
					),
				],
			),
			child: Padding(
				padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
										color: typeColor.withValues(alpha: 0.12),
										borderRadius: BorderRadius.circular(14),
									),
									child: Icon(typeIcon, color: typeColor, size: 22),
								),
								const SizedBox(width: 12),
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
											const SizedBox(height: 4),
											Row(
												children: [
													Icon(Icons.access_time_rounded,
															size: 12,
															color: AppColors.darkText.withValues(alpha: 0.40)),
													const SizedBox(width: 4),
													Text(
														'Recibida el $formattedDate',
														style: theme.textTheme.bodySmall?.copyWith(
																color: AppColors.darkText.withValues(alpha: 0.55),
															),
													),
												],
											),
										],
									),
								),
								const SizedBox(width: 8),
								_WaitTimeBadge(createdAt: item.createdAt),
							],
						),
						if (item.solicitudTipo != null)
							Padding(
								padding: const EdgeInsets.only(top: 10),
								child: SolicitudTypeBadge(tipo: item.solicitudTipo!),
							),
						if (subtitle != null && subtitle.isNotEmpty) ...[
							const SizedBox(height: 10),
							Text(
								subtitle,
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
								style: theme.textTheme.bodyMedium?.copyWith(
										color: AppColors.darkText.withValues(alpha: 0.68),
										height: 1.35,
									),
							),
						],
						const SizedBox(height: 14),
						Divider(height: 1, color: AppColors.grayNeutral.withValues(alpha: 0.18)),
						const SizedBox(height: 12),
						SizedBox(
							width: double.infinity,
							child: FilledButton.icon(
								onPressed: onReview,
								style: FilledButton.styleFrom(
									backgroundColor: typeColor,
									padding: const EdgeInsets.symmetric(vertical: 11),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(12),
									),
								),
								icon: const Icon(Icons.rate_review_outlined, size: 18),
								label: const Text(
									'Revisar solicitud',
									style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
								),
							),
						),
					],
				),
			),
		);
	}

	Color _typeColor(SolicitudTipo? tipo) {
		switch (tipo) {
			case SolicitudTipo.kermesse:
				return AppColors.greenHope;
			case SolicitudTipo.rifa:
				return const Color(0xFF6750A4);
			case SolicitudTipo.campania:
			case null:
				return AppColors.orangeAction;
		}
	}

	IconData _typeIcon(SolicitudTipo? tipo) {
		switch (tipo) {
			case SolicitudTipo.kermesse:
				return Icons.festival_outlined;
			case SolicitudTipo.rifa:
				return Icons.confirmation_number_outlined;
			case SolicitudTipo.campania:
			case null:
				return Icons.campaign_outlined;
		}
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

class _WaitTimeBadge extends StatelessWidget {
	const _WaitTimeBadge({required this.createdAt});

	final DateTime createdAt;

	@override
	Widget build(BuildContext context) {
		final diff = DateTime.now().difference(createdAt);
		final days = diff.inDays;
		final hours = diff.inHours;

		late final String label;
		late final Color color;
		if (days > 7) {
			label = '+7d';
			color = AppColors.orangeAction;
		} else if (days > 3) {
			label = '${days}d';
			color = AppColors.orangeAction;
		} else if (days > 0) {
			label = '${days}d';
			color = AppColors.bluePrimary;
		} else if (hours > 0) {
			label = '${hours}h';
			color = AppColors.greenSuccess;
		} else {
			label = 'Nueva';
			color = AppColors.greenSuccess;
		}

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.10),
				borderRadius: BorderRadius.circular(999),
				border: Border.all(color: color.withValues(alpha: 0.30)),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(Icons.schedule_rounded, size: 12, color: color),
					const SizedBox(width: 3),
					Text(
						label,
						style: TextStyle(
							fontSize: 11,
							fontWeight: FontWeight.w700,
							color: color,
						),
					),
				],
			),
		);
	}
}

class _FilterChip extends StatelessWidget {
	const _FilterChip({
		required this.label,
		required this.count,
		required this.isActive,
		required this.color,
		required this.icon,
		required this.onTap,
	});

	final String label;
	final int count;
	final bool isActive;
	final Color color;
	final IconData icon;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return GestureDetector(
			onTap: onTap,
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 180),
				padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
				decoration: BoxDecoration(
					color: isActive ? color : color.withValues(alpha: 0.07),
					borderRadius: BorderRadius.circular(999),
					border: Border.all(
						color: isActive ? color : color.withValues(alpha: 0.25),
					),
				),
				child: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(icon, size: 14, color: isActive ? Colors.white : color),
						const SizedBox(width: 6),
						Text(
							label,
							style: TextStyle(
								fontSize: 13,
								fontWeight: FontWeight.w600,
								color: isActive ? Colors.white : color,
							),
						),
						if (count > 0) ...[
							const SizedBox(width: 6),
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
								decoration: BoxDecoration(
									color: isActive
											? Colors.white.withValues(alpha: 0.25)
											: color.withValues(alpha: 0.15),
									borderRadius: BorderRadius.circular(999),
								),
								child: Text(
									'$count',
									style: TextStyle(
										fontSize: 11,
										fontWeight: FontWeight.w700,
										color: isActive ? Colors.white : color,
									),
								),
							),
						],
					],
				),
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

	/// Returns the gradient for the header based on the solicitud type.
	LinearGradient _getTypeGradient(SolicitudTipo? tipo) {
		switch (tipo) {
			case SolicitudTipo.kermesse:
				return LinearGradient(
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
					colors: [AppColors.greenHope, AppColors.greenHope.withValues(alpha: 0.7)],
				);
			case SolicitudTipo.rifa:
				return const LinearGradient(
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
					colors: [Color(0xFF6750A4), Color(0xFF9C84D4)],
				);
			case SolicitudTipo.campania:
			case null:
				return AppColors.actionGradient as LinearGradient;
		}
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final formattedDate = formatAdminDate(widget.item.createdAt);
		final typeColor = _getTypeColor(widget.item.solicitudTipo);
		final hasCover = (widget.item.coverUrl ?? '').trim().isNotEmpty;

		return SafeArea(
			top: false,
			child: DraggableScrollableSheet(
					initialChildSize: 0.75,
					minChildSize: 0.45,
					maxChildSize: 0.95,
					builder: (context, controller) {
						return DecoratedBox(
							decoration: const BoxDecoration(
								color: Color(0xFFF8F9FB),
								borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
							),
							child: ListView(
								controller: controller,
								padding: EdgeInsets.zero,
								children: [
									// ── Drag handle ──────────────────────────────────────
									Center(
										child: Padding(
											padding: const EdgeInsets.only(top: 10, bottom: 4),
											child: Container(
												width: 44,
												height: 4,
												decoration: BoxDecoration(
													color: Colors.white.withValues(alpha: 0.5),
													borderRadius: BorderRadius.circular(2),
												),
											),
										),
									),

									// ── Hero header with gradient ─────────────────────────
									Container(
										margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
										decoration: BoxDecoration(
											gradient: LinearGradient(
												begin: Alignment.topLeft,
												end: Alignment.bottomRight,
												colors: [
													typeColor,
													typeColor.withValues(alpha: 0.75),
												],
											),
											borderRadius: BorderRadius.circular(20),
											boxShadow: [
												BoxShadow(
													color: typeColor.withValues(alpha: 0.35),
													blurRadius: 16,
													offset: const Offset(0, 6),
												),
											],
										),
										child: ClipRRect(
											borderRadius: BorderRadius.circular(20),
											child: Stack(
												children: [
													// Cover image behind header (if present)
													if (hasCover)
														Positioned.fill(
															child: Image.network(
																widget.item.coverUrl!,
																fit: BoxFit.cover,
																errorBuilder: (_, __, ___) => const SizedBox.shrink(),
															),
														),
													if (hasCover)
														Positioned.fill(
															child: Container(
																decoration: BoxDecoration(
																	gradient: LinearGradient(
																		begin: Alignment.topCenter,
																		end: Alignment.bottomCenter,
																		colors: [
																			typeColor.withValues(alpha: 0.55),
																			typeColor.withValues(alpha: 0.95),
																		],
																	),
																),
															),
														),
													// Header content
													Padding(
														padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
														child: Column(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																// Type badge + wait badge row
																Row(
																	children: [
																		if (widget.item.solicitudTipo != null)
																			Container(
																				padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
																				decoration: BoxDecoration(
																					color: Colors.white.withValues(alpha: 0.22),
																					borderRadius: BorderRadius.circular(20),
																					border: Border.all(
																						color: Colors.white.withValues(alpha: 0.4),
																						width: 1,
																					),
																				),
																				child: Row(
																					mainAxisSize: MainAxisSize.min,
																					children: [
																						Icon(
																							_getTypeIcon(widget.item.solicitudTipo!),
																							size: 13,
																							color: Colors.white,
																						),
																						const SizedBox(width: 5),
																						Text(
																							_getTypeLabel(widget.item.solicitudTipo!),
																							style: const TextStyle(
																								fontSize: 12,
																								fontWeight: FontWeight.w700,
																								color: Colors.white,
																								letterSpacing: 0.2,
																							),
																						),
																					],
																				),
																			),
																		const Spacer(),
																		_buildWaitingTimeBadge(context, widget.item.createdAt),
																	],
																),
																const SizedBox(height: 14),
																// Title
																Text(
																	widget.item.title,
																	style: const TextStyle(
																		fontWeight: FontWeight.w900,
																		color: Colors.white,
																		fontSize: 22,
																		height: 1.25,
																		letterSpacing: -0.4,
																		shadows: [
																			Shadow(color: Colors.black38, blurRadius: 6),
																		],
																	),
																),
																const SizedBox(height: 8),
																// Date row
																Row(
																	children: [
																		const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white70),
																		const SizedBox(width: 5),
																		Text(
																			'Enviado el $formattedDate',
																			style: const TextStyle(
																				fontSize: 13,
																				color: Colors.white70,
																				fontWeight: FontWeight.w500,
																			),
																		),
																	],
																),
															],
														),
													),
												],
											),
										),
									),

									// ── Content padding ───────────────────────────────────
									Padding(
										padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												// Descripción
												if ((widget.item.subtitle ?? '').trim().isNotEmpty) ...[
													_ReviewSectionCard(
														icon: Icons.description_rounded,
														iconColor: typeColor,
														title: 'Descripción',
														child: Text(
															widget.item.subtitle!,
															style: const TextStyle(
																color: Colors.black87,
																fontSize: 15,
																height: 1.65,
															),
														),
													),
													const SizedBox(height: 12),
												],

									// Datos del beneficiario
									if (widget.item.beneficiaryName != null) ...[
										_ReviewSectionCard(
											icon: Icons.person_rounded,
											iconColor: typeColor,
											title: 'Datos del beneficiario',
											child: Column(
												children: [
													_ReviewInfoRow(
														label: 'Nombre',
														value: widget.item.beneficiaryName!,
													),
													if (widget.item.beneficiaryRelation != null)
														_ReviewInfoRow(
															label: 'Relación',
															value: widget.item.beneficiaryRelation!,
														),
												],
											),
										),
										const SizedBox(height: 12),
									],

									// Evidencias fotográficas
									if (widget.item.evidenceUrls != null && widget.item.evidenceUrls!.isNotEmpty) ...[
										_ReviewSectionCard(
											icon: Icons.photo_library_rounded,
											iconColor: typeColor,
											title: 'Evidencias fotográficas',
											child: GridView.builder(
												shrinkWrap: true,
												physics: const NeverScrollableScrollPhysics(),
												gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
													crossAxisCount: 2,
													crossAxisSpacing: 10,
													mainAxisSpacing: 10,
													childAspectRatio: 1,
												),
												itemCount: widget.item.evidenceUrls!.length,
												itemBuilder: (context, index) {
													final url = widget.item.evidenceUrls![index];
													return ClipRRect(
														borderRadius: BorderRadius.circular(10),
														child: Image.network(
															url,
															fit: BoxFit.cover,
															loadingBuilder: (context, child, loadingProgress) {
																if (loadingProgress == null) return child;
																return Container(
																	color: Colors.grey[200],
																	child: Center(
																		child: CircularProgressIndicator(
																			strokeWidth: 2,
																			color: typeColor,
																		),
																	),
																);
															},
															errorBuilder: (context, error, stackTrace) {
																return Container(
																	color: Colors.grey[200],
																	child: const Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
																);
															},
														),
													);
												},
											),
										),
										const SizedBox(height: 12),
									],
									// Información de Kermesse
									if (widget.item.solicitudTipo == SolicitudTipo.kermesse) ...[
										_ReviewSectionCard(
											icon: Icons.event_rounded,
											iconColor: AppColors.greenHope,
											title: 'Detalles del evento',
											child: Column(
												children: [
													if (widget.item.kermesseDate != null)
														_ReviewInfoRow(
															icon: Icons.access_time_rounded,
															iconColor: AppColors.bluePrimary,
															label: 'Fecha y horario',
															value: widget.item.kermesseDate!,
														),
													if (widget.item.kermesseBeneficiaries != null)
														_ReviewInfoRow(
															icon: Icons.people_rounded,
															iconColor: AppColors.greenSuccess,
															label: 'Beneficiarios',
															value: widget.item.kermesseBeneficiaries!,
														),
													if (widget.item.kermessePurpose != null)
														_ReviewInfoRow(
															icon: Icons.attach_money_rounded,
															iconColor: AppColors.orangeAction,
															label: 'Uso de fondos',
															value: widget.item.kermessePurpose!,
														),
												],
											),
										),
										const SizedBox(height: 12),
										if (widget.item.kermesseMenu != null) ...[
											_ReviewSectionCard(
												icon: Icons.restaurant_menu_rounded,
												iconColor: AppColors.orangeAction,
												title: 'Menú y precios',
												child: Text(
													widget.item.kermesseMenu!,
													style: const TextStyle(
														color: Colors.black87,
														fontSize: 15,
														height: 1.55,
													),
												),
											),
											const SizedBox(height: 12),
										],
										if (widget.item.kermesseShows != null) ...[
											_ReviewSectionCard(
												icon: Icons.celebration_rounded,
												iconColor: AppColors.greenSuccess,
												title: 'Entretenimiento y actividades',
												child: Text(
													widget.item.kermesseShows!,
													style: const TextStyle(
														color: Colors.black87,
														fontSize: 15,
														height: 1.55,
													),
												),
											),
											const SizedBox(height: 12),
										],
									],

									// Ubicación de la Kermesse
									if (widget.item.solicitudTipo == SolicitudTipo.kermesse &&
											widget.item.kermesseLatitude != null &&
											widget.item.kermesseLongitude != null) ...[
										_ReviewSectionCard(
											icon: Icons.location_on_rounded,
											iconColor: Colors.red,
											title: 'Ubicación del evento',
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													if (widget.item.kermesseAddress != null) ...[
														Container(
															padding: const EdgeInsets.all(12),
															decoration: BoxDecoration(
																color: AppColors.bluePrimary.withValues(alpha: 0.07),
																borderRadius: BorderRadius.circular(10),
																border: Border.all(
																	color: AppColors.bluePrimary.withValues(alpha: 0.18),
																),
															),
															child: Row(
																children: [
																	const Icon(Icons.location_on_rounded, color: AppColors.bluePrimary, size: 18),
																	const SizedBox(width: 8),
																	Expanded(
																		child: Text(
																			widget.item.kermesseAddress!,
																			style: const TextStyle(
																				color: Colors.black87,
																				fontSize: 14,
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
															height: 220,
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
																				child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
																			),
																		],
																	),
																],
															),
														),
													),
												],
											),
										),
										const SizedBox(height: 12),
									],
									// ── Comments + Actions ──────────────────────────────
									// Sección de comentarios
									_ReviewSectionCard(
										icon: Icons.rate_review_rounded,
										iconColor: typeColor,
										title: 'Comentarios para el organizador',
										subtitle: 'Si necesitas cambios, describe qué ajustes requieres (opcional)',
										child: TextField(
											controller: _messageCtrl,
											enabled: !_isSubmitting,
											maxLines: 5,
											minLines: 3,
											decoration: InputDecoration(
												filled: true,
												fillColor: Colors.grey.shade50,
												border: OutlineInputBorder(
													borderRadius: BorderRadius.circular(12),
													borderSide: BorderSide(color: Colors.grey.shade200),
												),
												enabledBorder: OutlineInputBorder(
													borderRadius: BorderRadius.circular(12),
													borderSide: BorderSide(color: Colors.grey.shade200),
												),
												focusedBorder: OutlineInputBorder(
													borderRadius: BorderRadius.circular(12),
													borderSide: BorderSide(color: typeColor, width: 1.5),
												),
												hintText: 'Ej: Por favor agrega más evidencias fotográficas del beneficiario.',
												hintStyle: TextStyle(
													color: Colors.grey.shade400,
													fontSize: 14,
												),
												contentPadding: const EdgeInsets.all(14),
											),
										),
									),

									if (_error != null) ...[
										const SizedBox(height: 10),
										Container(
											margin: const EdgeInsets.symmetric(horizontal: 2),
											decoration: BoxDecoration(
												color: AppColors.error.withValues(alpha: 0.08),
												borderRadius: BorderRadius.circular(12),
												border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
											),
											padding: const EdgeInsets.all(12),
											child: Row(
												children: [
													Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
													const SizedBox(width: 8),
													Expanded(
														child: Text(
															_error!,
															style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
														),
													),
												],
											),
										),
									],

									// Category selector for campaigns
									if (widget.item.solicitudTipo == SolicitudTipo.campania) ...[
										const SizedBox(height: 12),
										_ReviewSectionCard(
											icon: Icons.category_rounded,
											iconColor: AppColors.bluePrimary,
											title: 'Categoría de la campaña',
											subtitle: 'Selecciona la que mejor describe esta campaña',
											child: _loadingCategories
												? Center(
													child: Padding(
														padding: const EdgeInsets.all(16),
														child: CircularProgressIndicator(color: typeColor),
													),
												)
												: (_categories != null && _categories!.isNotEmpty)
													? Container(
														decoration: BoxDecoration(
															color: Colors.white,
															border: Border.all(
																color: _selectedCategoryId != null
																	? typeColor.withValues(alpha: 0.5)
																	: Colors.grey.shade200,
																width: _selectedCategoryId != null ? 1.5 : 1,
															),
															borderRadius: BorderRadius.circular(12),
														),
														padding: const EdgeInsets.symmetric(horizontal: 14),
														child: DropdownButtonHideUnderline(
															child: DropdownButton<String>(
																isExpanded: true,
																value: _selectedCategoryId,
																hint: Row(
																	children: [
																		Icon(Icons.category_outlined, size: 18, color: Colors.grey.shade400),
																		const SizedBox(width: 8),
																		Text(
																			'Selecciona una categoría',
																			style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
																		),
																	],
																),
																icon: Icon(Icons.keyboard_arrow_down_rounded, color: typeColor),
																items: _categories!.map((category) {
																	return DropdownMenuItem<String>(
																		value: category.id,
																		child: Row(
																			children: [
																				Container(
																					padding: const EdgeInsets.all(6),
																					decoration: BoxDecoration(
																						color: _parseColor(category.color).withValues(alpha: 0.12),
																						borderRadius: BorderRadius.circular(8),
																					),
																					child: Icon(
																						_getCategoryIcon(category.icono),
																						size: 18,
																						color: _parseColor(category.color),
																					),
																				),
																				const SizedBox(width: 10),
																				Text(
																					category.nombre,
																					style: const TextStyle(
																						fontWeight: FontWeight.w500,
																						fontSize: 14,
																					),
																				),
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
													: Container(
														padding: const EdgeInsets.all(12),
														decoration: BoxDecoration(
															color: Colors.grey.shade50,
															borderRadius: BorderRadius.circular(10),
														),
														child: Row(
															children: [
																Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
																const SizedBox(width: 8),
																const Text(
																	'No hay categorías disponibles',
																	style: TextStyle(color: Colors.black54, fontSize: 14),
																),
															],
														),
													),
										),
									],

									const SizedBox(height: 20),

									// ── Action buttons ────────────────────────────────────
									if (_isSubmitting)
										Container(
											alignment: Alignment.center,
											padding: const EdgeInsets.all(20),
											child: CircularProgressIndicator(color: typeColor),
										)
									else ...[
										// Approve button
										Container(
											decoration: BoxDecoration(
												gradient: const LinearGradient(
													colors: [AppColors.greenHope, AppColors.greenSuccess],
													begin: Alignment.centerLeft,
													end: Alignment.centerRight,
												),
												borderRadius: BorderRadius.circular(14),
												boxShadow: [
													BoxShadow(
														color: AppColors.greenSuccess.withValues(alpha: 0.38),
														blurRadius: 12,
														offset: const Offset(0, 4),
													),
												],
											),
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
													minimumSize: const Size(double.infinity, 52),
													backgroundColor: Colors.transparent,
													shadowColor: Colors.transparent,
													foregroundColor: Colors.white,
													shape: RoundedRectangleBorder(
														borderRadius: BorderRadius.circular(14),
													),
												),
												icon: const Icon(Icons.check_circle_rounded, size: 20),
												label: const Text(
													'Aprobar solicitud',
													style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
												),
											),
										),
										const SizedBox(height: 10),
										// Request changes button
										OutlinedButton.icon(
											onPressed: () => _showConfirmDialog(
												context,
												title: '¿Solicitar cambios?',
												message: 'Se notificará al organizador que debe realizar ajustes.',
												confirmText: 'Solicitar',
												isDestructive: false,
												onConfirm: _handleRequestChanges,
											),
											style: OutlinedButton.styleFrom(
												minimumSize: const Size(double.infinity, 50),
												padding: const EdgeInsets.symmetric(vertical: 14),
												side: BorderSide(
													color: typeColor.withValues(alpha: 0.5),
													width: 1.5,
												),
												foregroundColor: typeColor,
												shape: RoundedRectangleBorder(
													borderRadius: BorderRadius.circular(14),
												),
											),
											icon: const Icon(Icons.edit_note_rounded, size: 20),
											label: const Text(
												'Solicitar cambios',
												style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
											),
										),
									],
								],
							),
						),
								],
							),
						);
					},
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
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
				title: Row(
					children: [
						Container(
							padding: const EdgeInsets.all(8),
							decoration: BoxDecoration(
								color: (isDestructive ? AppColors.orangeAction : AppColors.greenSuccess)
										.withValues(alpha: 0.12),
								borderRadius: BorderRadius.circular(10),
							),
							child: Icon(
								isDestructive ? Icons.warning_rounded : Icons.check_circle_rounded,
								color: isDestructive ? AppColors.orangeAction : AppColors.greenSuccess,
								size: 22,
							),
						),
						const SizedBox(width: 12),
						Expanded(child: Text(title)),
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

	Color _getTypeColor(SolicitudTipo? tipo) {
		switch (tipo) {
			case SolicitudTipo.kermesse:
				return AppColors.greenHope;
			case SolicitudTipo.rifa:
				return const Color(0xFF6750A4);
			case SolicitudTipo.campania:
			case null:
				return AppColors.orangeAction;
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
