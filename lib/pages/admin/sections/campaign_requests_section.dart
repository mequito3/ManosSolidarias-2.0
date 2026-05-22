import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/admin_dashboard_controller.dart';
import '../../../models/admin_dashboard.dart';
import '../../../models/category.dart';
import '../../../models/solicitud.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../ui/widgets/app_buttons.dart';
import '../../../ui/widgets/app_snackbar.dart';
import '../../../ui/widgets/image_redaction_editor.dart';
import '../../../ui/widgets/premium_empty_state.dart';
import '../../../ui/widgets/premium_hero.dart';
import 'admin_section_widgets.dart';

class CampaignRequestsSection extends StatefulWidget {
	const CampaignRequestsSection({
		super.key,
		required this.items,
		required this.onReview,
		this.organizationItems = const [],
		this.onReviewOrganization,
	});

	final List<AdminPendingItem> items;
	final ValueChanged<AdminPendingItem> onReview;
	final List<AdminPendingItem> organizationItems;
	final ValueChanged<AdminPendingItem>? onReviewOrganization;

	@override
	State<CampaignRequestsSection> createState() => _CampaignRequestsSectionState();
}

enum _RequestFilter { todas, campania, kermesse, rifa, organizacion }

class _CampaignRequestsSectionState extends State<CampaignRequestsSection> {
	_RequestFilter _activeFilter = _RequestFilter.todas;

	bool _isOrganization(AdminPendingItem item) =>
			item.type == AdminItemType.organizationReview;

	@override
	Widget build(BuildContext context) {
		final campaigns = widget.items;
		final orgs = widget.organizationItems;

		final countCampania = campaigns
				.where((e) => e.solicitudTipo == SolicitudTipo.campania || e.solicitudTipo == null)
				.length;
		final countKermesse =
				campaigns.where((e) => e.solicitudTipo == SolicitudTipo.kermesse).length;
		final countOrg = orgs.length;
		final totalCount = campaigns.length + countOrg;

		final List<AdminPendingItem> filtered;
		switch (_activeFilter) {
			case _RequestFilter.todas:
				filtered = [...campaigns, ...orgs]
						..sort((a, b) => b.createdAt.compareTo(a.createdAt));
				break;
			case _RequestFilter.campania:
				filtered = campaigns
						.where((e) =>
								e.solicitudTipo == SolicitudTipo.campania || e.solicitudTipo == null)
						.toList();
				break;
			case _RequestFilter.kermesse:
				filtered = campaigns
						.where((e) => e.solicitudTipo == SolicitudTipo.kermesse)
						.toList();
				break;
			case _RequestFilter.rifa:
				filtered =
						campaigns.where((e) => e.solicitudTipo == SolicitudTipo.rifa).toList();
				break;
			case _RequestFilter.organizacion:
				filtered = orgs;
				break;
		}

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				PremiumSectionHeader(
					title: 'Solicitudes solidarias',
					accentGradient: AppColors.actionGradient,
					count: totalCount == 0 ? null : totalCount,
					countColor: AppColors.orangeAction,
				),
				const SizedBox(height: 6),
				Text(
					'Revisa campañas, kermesses y organizaciones enviadas para aprobación.',
					style: Theme.of(context).textTheme.bodyMedium?.copyWith(
								color: AppColors.darkText.withValues(alpha: 0.68),
							),
				),
				const SizedBox(height: 14),
				SingleChildScrollView(
					scrollDirection: Axis.horizontal,
					child: Row(
						children: [
							_FilterChip(
								label: 'Todas',
								count: totalCount,
								isActive: _activeFilter == _RequestFilter.todas,
								icon: Icons.all_inclusive_rounded,
								onTap: () => setState(() => _activeFilter = _RequestFilter.todas),
							),
							const SizedBox(width: 8),
							_FilterChip(
								label: 'Campañas',
								count: countCampania,
								isActive: _activeFilter == _RequestFilter.campania,
								icon: Icons.campaign_outlined,
								onTap: () => setState(() => _activeFilter = _RequestFilter.campania),
							),
							const SizedBox(width: 8),
							_FilterChip(
								label: 'Kermesse',
								count: countKermesse,
								isActive: _activeFilter == _RequestFilter.kermesse,
								icon: Icons.festival_outlined,
								onTap: () => setState(() => _activeFilter = _RequestFilter.kermesse),
							),
							const SizedBox(width: 8),
							_FilterChip(
								label: 'Organizaciones',
								count: countOrg,
								isActive: _activeFilter == _RequestFilter.organizacion,
								icon: Icons.business_rounded,
								onTap: () =>
										setState(() => _activeFilter = _RequestFilter.organizacion),
							),
						],
					),
				),
				const SizedBox(height: 18),
				if (filtered.isEmpty)
					Padding(
						padding: const EdgeInsets.symmetric(vertical: 12),
						child: PremiumEmptyState(
							icon: Icons.inbox_rounded,
							iconColor: AppColors.orangeAction,
							title: _activeFilter == _RequestFilter.todas
									? 'Todo al día'
									: 'Sin solicitudes en este filtro',
							description: _activeFilter == _RequestFilter.todas
									? 'No hay solicitudes pendientes por revisar. Las nuevas aparecerán acá apenas los organizadores las envíen.'
									: 'Probá con otro filtro para ver las solicitudes pendientes.',
							blobColors: [
								AppColors.orangeAction.withValues(alpha: 0.10),
								AppColors.greenHope.withValues(alpha: 0.08),
							],
							hintChips: const [
								PremiumHintChip(
									icon: Icons.check_circle_outline_rounded,
									label: 'Bandeja vacía',
									color: AppColors.greenSuccess,
								),
								PremiumHintChip(
									icon: Icons.notifications_active_outlined,
									label: 'Alertas activas',
									color: AppColors.bluePrimary,
								),
							],
						),
					)
				else
					...filtered.indexed.map(
						(entry) {
							final item = entry.$2;
							final isOrg = _isOrganization(item);
							return Padding(
								padding: EdgeInsets.only(
										bottom: entry.$1 == filtered.length - 1 ? 0 : 14),
								child: CampaignRequestCard(
									item: item,
									isOrganization: isOrg,
									onReview: () {
										if (isOrg) {
											widget.onReviewOrganization?.call(item);
										} else {
											widget.onReview(item);
										}
									},
								),
							);
						},
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
		this.isOrganization = false,
	});

	final AdminPendingItem item;
	final VoidCallback onReview;
	final bool isOrganization;

	@override
	Widget build(BuildContext context) {
		final subtitle = item.subtitle?.trim();
		final typeColor =
				isOrganization ? AppColors.bluePrimary : _typeColor(item.solicitudTipo);
		final typeIcon =
				isOrganization ? Icons.business_rounded : _typeIcon(item.solicitudTipo);
		final typeLabel = isOrganization
				? 'Organización'
				: _typeLabel(item.solicitudTipo);
		// El anonimato solo aplica a campañas (una causa personal puede pedir
		// privacidad). Kermesses, rifas y organizaciones son públicas.
		final esCampania = !isOrganization &&
				(item.solicitudTipo == SolicitudTipo.campania ||
						item.solicitudTipo == null);
		final showAnon = item.esAnonimo && esCampania;

		return Container(
			decoration: BoxDecoration(
				color: AppColors.cardBackground,
				borderRadius: BorderRadius.circular(AppColors.radiusMd),
				boxShadow: AppColors.shadowSm,
			),
			padding: const EdgeInsets.all(AppColors.space16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					// ── Encabezado: tipo (ícono + palabra) + tiempo ─────────
					Row(
						children: [
							Container(
								width: 38,
								height: 38,
								decoration: BoxDecoration(
									color: typeColor,
									borderRadius: BorderRadius.circular(AppColors.radiusSm),
								),
								child: Icon(typeIcon, color: Colors.white, size: 20),
							),
							const SizedBox(width: AppColors.space12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									mainAxisSize: MainAxisSize.min,
									children: [
										Text(
											typeLabel,
											style: const TextStyle(
												color: AppColors.darkText,
												fontSize: AppColors.fontSizeBase,
												fontWeight: AppColors.fontWeightExtraBold,
												letterSpacing: -0.1,
											),
										),
										const SizedBox(height: 1),
										Text(
											_waitLabel(item.createdAt),
											style: const TextStyle(
												color: AppColors.mediumText,
												fontSize: AppColors.fontSizeXs,
											),
										),
									],
								),
							),
							if (showAnon) _AnonBadge(),
						],
					),
					const SizedBox(height: AppColors.space12),

					// ── Título ──────────────────────────────────────────────
					Text(
						item.title,
						maxLines: 2,
						overflow: TextOverflow.ellipsis,
						style: const TextStyle(
							fontWeight: AppColors.fontWeightBold,
							color: AppColors.darkText,
							fontSize: AppColors.fontSizeMd,
							letterSpacing: -0.3,
							height: 1.25,
						),
					),
					if (subtitle != null && subtitle.isNotEmpty) ...[
						const SizedBox(height: 6),
						Text(
							subtitle,
							maxLines: 2,
							overflow: TextOverflow.ellipsis,
							style: const TextStyle(
								color: AppColors.mediumText,
								fontSize: AppColors.fontSizeSm,
								height: 1.4,
							),
						),
					],
					const SizedBox(height: AppColors.space16),

					// ── Acción (azul de marca, uniforme) ────────────────────
					SizedBox(
						width: double.infinity,
						child: FilledButton.icon(
							onPressed: onReview,
							style: FilledButton.styleFrom(
								backgroundColor: AppColors.bluePrimary,
								foregroundColor: Colors.white,
								padding:
										const EdgeInsets.symmetric(vertical: AppColors.space12),
								shape: RoundedRectangleBorder(
									borderRadius: BorderRadius.circular(AppColors.radiusSm),
								),
								elevation: 0,
							),
							icon: const Icon(Icons.rate_review_outlined, size: 18),
							label: Text(
								isOrganization ? 'Revisar organización' : 'Revisar solicitud',
								style: const TextStyle(
									fontWeight: AppColors.fontWeightBold,
									fontSize: AppColors.fontSizeSm,
									letterSpacing: 0.2,
								),
							),
						),
					),
				],
			),
		);
	}

	String _typeLabel(SolicitudTipo? tipo) {
		switch (tipo) {
			case SolicitudTipo.kermesse:
				return 'Kermesse';
			case SolicitudTipo.rifa:
				return 'Rifa';
			case SolicitudTipo.campania:
			case null:
				return 'Campaña';
		}
	}

	String _waitLabel(DateTime createdAt) {
		final diff = DateTime.now().difference(createdAt);
		final days = diff.inDays;
		final hours = diff.inHours;
		if (days > 7) return 'hace +7 días';
		if (days > 1) return 'hace $days días';
		if (days == 1) return 'hace 1 día';
		if (hours > 0) return 'hace ${hours}h';
		return 'Nueva';
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

class _AnonBadge extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
			decoration: BoxDecoration(
				color: AppColors.grayNeutral.withValues(alpha: 0.14),
				borderRadius: BorderRadius.circular(AppColors.radiusRound),
			),
			child: const Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.mediumText),
					SizedBox(width: 4),
					Text(
						'Anónimo',
						style: TextStyle(
							color: AppColors.mediumText,
							fontWeight: AppColors.fontWeightBold,
							fontSize: AppColors.fontSizeXs,
							letterSpacing: 0.2,
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
		required this.icon,
		required this.onTap,
	});

	final String label;
	final int count;
	final bool isActive;
	final IconData icon;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		// Filtros neutros: solo el activo se pinta de azul de marca; los demás
		// quedan grises. Así la fila no es un arcoíris que marea.
		final fg = isActive ? Colors.white : AppColors.mediumText;
		return GestureDetector(
			onTap: onTap,
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 180),
				padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
				decoration: BoxDecoration(
					color: isActive ? AppColors.bluePrimary : AppColors.cardBackground,
					borderRadius: BorderRadius.circular(999),
					border: Border.all(
						color: isActive
								? AppColors.bluePrimary
								: AppColors.grayNeutral.withValues(alpha: 0.35),
					),
				),
				child: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(icon, size: 15, color: fg),
						const SizedBox(width: 6),
						Text(
							label,
							style: TextStyle(
								fontSize: 13,
								fontWeight: FontWeight.w700,
								color: isActive ? Colors.white : AppColors.darkText,
							),
						),
						if (count > 0) ...[
							const SizedBox(width: 6),
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
								decoration: BoxDecoration(
									color: isActive
											? Colors.white.withValues(alpha: 0.25)
											: AppColors.grayNeutral.withValues(alpha: 0.18),
									borderRadius: BorderRadius.circular(999),
								),
								child: Text(
									'$count',
									style: TextStyle(
										fontSize: 11,
										fontWeight: FontWeight.w800,
										color: isActive ? Colors.white : AppColors.mediumText,
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

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final formattedDate = formatAdminDate(widget.item.createdAt);
		final typeColor = _getTypeColor(widget.item.solicitudTipo);
		final hasCover = (widget.item.coverUrl ?? '').trim().isNotEmpty;
		final hasOriginalCover = widget.item.esAnonimo &&
				(widget.item.coverOriginalUrl ?? '').trim().isNotEmpty;

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

									// ── Hero header (cover + overlay oscuro neutro) ───────
									Container(
										margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
										height: 172,
										decoration: BoxDecoration(
											color: AppColors.darkText,
											borderRadius: BorderRadius.circular(20),
											boxShadow: AppColors.shadowSm,
										),
										child: ClipRRect(
											borderRadius: BorderRadius.circular(20),
											child: Stack(
												fit: StackFit.expand,
												children: [
													if (hasCover)
														Image.network(
															widget.item.coverUrl!,
															fit: BoxFit.cover,
															errorBuilder: (_, __, ___) => const SizedBox.shrink(),
														),
													// Overlay oscuro neutro (legibilidad del texto)
													Positioned.fill(
														child: DecoratedBox(
															decoration: BoxDecoration(
																gradient: LinearGradient(
																	begin: Alignment.topCenter,
																	end: Alignment.bottomCenter,
																	colors: [
																		Colors.black.withValues(alpha: 0.30),
																		Colors.black.withValues(alpha: 0.80),
																	],
																),
															),
														),
													),
													// Contenido
													Padding(
														padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
														child: Column(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																Row(
																	children: [
																		if (widget.item.solicitudTipo != null)
																			Container(
																				padding: const EdgeInsets.symmetric(
																						horizontal: 10, vertical: 5),
																				decoration: BoxDecoration(
																					color: Colors.white.withValues(alpha: 0.20),
																					borderRadius: BorderRadius.circular(20),
																					border: Border.all(
																						color: Colors.white.withValues(alpha: 0.35),
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
																		if (hasOriginalCover) ...[
																			_AdminOriginalBadge(
																				onTap: () => _showOriginalImageDialog(
																					context,
																					widget.item.coverOriginalUrl!,
																				),
																			),
																			const SizedBox(width: 6),
																			_AdminReRedactBadge(
																				onTap: () => _handleAdminReRedactCover(
																					context,
																					widget.item,
																					(url) => setState(() {}),
																				),
																			),
																			const SizedBox(width: 8),
																		],
																		_buildWaitingTimeBadge(context, widget.item.createdAt),
																	],
																),
																const Spacer(),
																Text(
																	widget.item.title,
																	maxLines: 2,
																	overflow: TextOverflow.ellipsis,
																	style: const TextStyle(
																		fontWeight: FontWeight.w800,
																		color: Colors.white,
																		fontSize: 21,
																		height: 1.2,
																		letterSpacing: -0.4,
																	),
																),
																const SizedBox(height: 6),
																Row(
																	children: [
																		const Icon(Icons.calendar_today_rounded,
																				size: 13, color: Colors.white70),
																		const SizedBox(width: 5),
																		Text(
																			'Enviado el $formattedDate',
																			style: const TextStyle(
																				fontSize: 12,
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
													// Si tenemos el registro enriquecido (id + url_original) y
													// la solicitud es anónima, mostramos overlay para ver
													// original y re-tachar.
													final evItem = (widget.item.evidenceItems != null &&
																	index < widget.item.evidenceItems!.length)
															? widget.item.evidenceItems![index]
															: null;
													final canReRedact = widget.item.esAnonimo &&
															evItem != null &&
															(evItem.urlOriginal?.trim().isNotEmpty ?? false);
													return ClipRRect(
														borderRadius: BorderRadius.circular(10),
														child: Stack(
															fit: StackFit.expand,
															children: [
																Image.network(
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
																if (canReRedact)
																	Positioned(
																		top: 6,
																		right: 6,
																		child: Row(
																			mainAxisSize: MainAxisSize.min,
																			children: [
																				_AdminEvidenceIconButton(
																					icon: Icons.visibility_rounded,
																					tooltip: 'Ver original',
																					background: Colors.black.withValues(alpha: 0.55),
																					onTap: () => _showOriginalImageDialog(
																						context,
																						evItem.urlOriginal!,
																					),
																				),
																				const SizedBox(width: 6),
																				_AdminEvidenceIconButton(
																					icon: Icons.edit_rounded,
																					tooltip: 'Re-tachar',
																					background: AppColors.orangeAction.withValues(alpha: 0.92),
																					onTap: () => _handleAdminReRedactEvidence(
																						context,
																						evidenciaId: evItem.id,
																						urlOriginal: evItem.urlOriginal!,
																						onUpdated: (_) => setState(() {}),
																					),
																				),
																			],
																		),
																	),
															],
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
										// Approve button — gradiente verde (semántico = éxito)
										DecoratedBox(
											decoration: BoxDecoration(
												gradient: AppColors.successGradient,
												borderRadius: BorderRadius.circular(AppColors.radiusMd),
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
													minimumSize: const Size(double.infinity, 54),
													backgroundColor: Colors.transparent,
													shadowColor: Colors.transparent,
													foregroundColor: Colors.white,
													padding: const EdgeInsets.symmetric(vertical: AppColors.space16),
													shape: RoundedRectangleBorder(
														borderRadius: BorderRadius.circular(AppColors.radiusMd),
													),
												),
												icon: const Icon(Icons.check_circle_rounded, size: 20),
												label: const Text(
													'Aprobar solicitud',
													style: TextStyle(
														fontSize: AppColors.fontSizeMd,
														fontWeight: AppColors.fontWeightBold,
														letterSpacing: AppColors.letterSpacingWide,
													),
												),
											),
										),
										const SizedBox(height: AppColors.space12),
										// Request changes button
										AppSecondaryButton(
											label: 'Solicitar cambios',
											icon: Icons.edit_note_rounded,
											onPressed: () => _showConfirmDialog(
												context,
												title: '¿Solicitar cambios?',
												message: 'Se notificará al organizador que debe realizar ajustes.',
												confirmText: 'Solicitar',
												isDestructive: false,
												onConfirm: _handleRequestChanges,
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

class _AdminOriginalBadge extends StatelessWidget {
	const _AdminOriginalBadge({required this.onTap});
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: Colors.white.withValues(alpha: 0.22),
			borderRadius: BorderRadius.circular(20),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(20),
				child: Container(
					padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(20),
						border: Border.all(
							color: Colors.white.withValues(alpha: 0.4),
							width: 1,
						),
					),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: const [
							Icon(Icons.visibility_rounded, size: 13, color: Colors.white),
							SizedBox(width: 5),
							Text(
								'Ver original',
								style: TextStyle(
									fontSize: 12,
									fontWeight: FontWeight.w700,
									color: Colors.white,
									letterSpacing: 0.2,
								),
							),
						],
					),
				),
			),
		);
	}
}

void _showOriginalImageDialog(BuildContext context, String url) {
	showDialog<void>(
		context: context,
		barrierColor: Colors.black.withValues(alpha: 0.92),
		builder: (ctx) => Dialog(
			backgroundColor: Colors.transparent,
			insetPadding: const EdgeInsets.all(12),
			child: Stack(
				children: [
					InteractiveViewer(
						child: Image.network(
							url,
							fit: BoxFit.contain,
							errorBuilder: (_, __, ___) => const Padding(
								padding: EdgeInsets.all(40),
								child: Text(
									'No pudimos cargar la imagen original.',
									textAlign: TextAlign.center,
									style: TextStyle(color: Colors.white),
								),
							),
						),
					),
					Positioned(
						top: 8,
						right: 8,
						child: SafeArea(
							child: Material(
								color: Colors.black.withValues(alpha: 0.6),
								shape: const CircleBorder(),
								child: IconButton(
									onPressed: () => Navigator.of(ctx).pop(),
									icon: const Icon(Icons.close_rounded, color: Colors.white),
									tooltip: 'Cerrar',
								),
							),
						),
					),
					Positioned(
						left: 12,
						bottom: 12,
						right: 12,
						child: SafeArea(
							child: Container(
								padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
								decoration: BoxDecoration(
									color: Colors.black.withValues(alpha: 0.6),
									borderRadius: BorderRadius.circular(10),
								),
								child: const Text(
									'Foto original sin tachar. Solo visible para admin.',
									textAlign: TextAlign.center,
									style: TextStyle(
										color: Colors.white,
										fontSize: 12,
									),
								),
							),
						),
					),
				],
			),
		),
	);
}

class _AdminReRedactBadge extends StatelessWidget {
	const _AdminReRedactBadge({required this.onTap});
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: AppColors.orangeAction.withValues(alpha: 0.32),
			borderRadius: BorderRadius.circular(20),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(20),
				child: Container(
					padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(20),
						border: Border.all(
							color: Colors.white.withValues(alpha: 0.55),
							width: 1,
						),
					),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: const [
							Icon(Icons.edit_rounded, size: 13, color: Colors.white),
							SizedBox(width: 5),
							Text(
								'Re-tachar',
								style: TextStyle(
									fontSize: 12,
									fontWeight: FontWeight.w700,
									color: Colors.white,
									letterSpacing: 0.2,
								),
							),
						],
					),
				),
			),
		);
	}
}

Future<void> _handleAdminReRedactCover(
	BuildContext context,
	AdminPendingItem item,
	ValueChanged<String> onUpdated,
) async {
	final url = item.coverOriginalUrl ?? item.coverUrl;
	if (url == null || url.trim().isEmpty) return;

	// Loading dialog mientras descarga la foto.
	showDialog<void>(
		context: context,
		barrierDismissible: false,
		builder: (_) => const Center(
			child: CircularProgressIndicator(color: AppColors.bluePrimary),
		),
	);

	try {
		final response = await http.get(Uri.parse(url));
		if (response.statusCode != 200) {
			if (context.mounted) Navigator.of(context).pop();
			if (context.mounted) {
				AppSnackBar.showError(context, 'No pudimos descargar la imagen original.');
			}
			return;
		}
		final bytes = response.bodyBytes;
		if (!context.mounted) return;
		Navigator.of(context).pop(); // cierro el loading

		final result = await ImageRedactionEditor.show(
			context,
			imageBytes: bytes,
		);
		if (result == null || !result.hasEdits) return;
		if (!context.mounted) return;

		// Reupload + UPDATE en BD
		showDialog<void>(
			context: context,
			barrierDismissible: false,
			builder: (_) => const Center(
				child: CircularProgressIndicator(color: AppColors.bluePrimary),
			),
		);
		final admin = AdminService(Supabase.instance.client);
		final newUrl = await admin.reRedactSolicitudCover(
			solicitudId: item.id,
			newRedactedBytes: result.bytes,
			contentType: 'image/jpeg',
			fileExtension: 'jpg',
		);
		if (context.mounted) Navigator.of(context).pop();
		onUpdated(newUrl);
		if (context.mounted) {
			AppSnackBar.showSuccess(context, 'Tachado actualizado. Refrescá la lista para ver el cambio.');
		}
	} catch (e) {
		if (context.mounted) Navigator.of(context).pop();
		if (context.mounted) {
			AppSnackBar.showError(context, 'Error al re-tachar: $e');
		}
	}
}

/// Botón circular pequeño usado como overlay encima de cada thumbnail de
/// evidencia (acciones "Ver original" / "Re-tachar"). Mantiene el mismo
/// look del overlay de portada pero compacto para no tapar la foto.
class _AdminEvidenceIconButton extends StatelessWidget {
	const _AdminEvidenceIconButton({
		required this.icon,
		required this.tooltip,
		required this.background,
		required this.onTap,
	});

	final IconData icon;
	final String tooltip;
	final Color background;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: background,
			shape: const CircleBorder(),
			child: InkWell(
				customBorder: const CircleBorder(),
				onTap: onTap,
				child: Tooltip(
					message: tooltip,
					child: Container(
						width: 30,
						height: 30,
						alignment: Alignment.center,
						decoration: BoxDecoration(
							shape: BoxShape.circle,
							border: Border.all(
								color: Colors.white.withValues(alpha: 0.55),
								width: 1,
							),
						),
						child: Icon(icon, size: 16, color: Colors.white),
					),
				),
			),
		);
	}
}

/// Descarga la evidencia original, abre el editor de tachado y sube la
/// nueva versión tachada actualizando la fila en `evidencias`. Mismo flow
/// que [_handleAdminReRedactCover] pero para evidencias individuales.
Future<void> _handleAdminReRedactEvidence(
	BuildContext context, {
	required String evidenciaId,
	required String urlOriginal,
	required ValueChanged<String> onUpdated,
}) async {
	if (urlOriginal.trim().isEmpty) return;

	showDialog<void>(
		context: context,
		barrierDismissible: false,
		builder: (_) => const Center(
			child: CircularProgressIndicator(color: AppColors.bluePrimary),
		),
	);

	try {
		final response = await http.get(Uri.parse(urlOriginal));
		if (response.statusCode != 200) {
			if (context.mounted) Navigator.of(context).pop();
			if (context.mounted) {
				AppSnackBar.showError(context, 'No pudimos descargar la evidencia original.');
			}
			return;
		}
		final bytes = response.bodyBytes;
		if (!context.mounted) return;
		Navigator.of(context).pop(); // cierro loading

		final result = await ImageRedactionEditor.show(
			context,
			imageBytes: bytes,
		);
		if (result == null || !result.hasEdits) return;
		if (!context.mounted) return;

		showDialog<void>(
			context: context,
			barrierDismissible: false,
			builder: (_) => const Center(
				child: CircularProgressIndicator(color: AppColors.bluePrimary),
			),
		);
		final admin = AdminService(Supabase.instance.client);
		final newUrl = await admin.reRedactEvidence(
			evidenciaId: evidenciaId,
			newRedactedBytes: result.bytes,
			contentType: 'image/jpeg',
			fileExtension: 'jpg',
		);
		if (context.mounted) Navigator.of(context).pop();
		onUpdated(newUrl);
		if (context.mounted) {
			AppSnackBar.showSuccess(context, 'Evidencia re-tachada. Refrescá la lista para ver el cambio.');
		}
	} catch (e) {
		if (context.mounted) Navigator.of(context).pop();
		if (context.mounted) {
			AppSnackBar.showError(context, 'Error al re-tachar evidencia: $e');
		}
	}
}
