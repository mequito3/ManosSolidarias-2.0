import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/admin_dashboard_controller.dart';
import '../../models/admin_dashboard.dart';
import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../ui/widgets/app_logo.dart';
import 'sections/admin_section_widgets.dart';
import 'sections/campaign_requests_section.dart';
import 'sections/donations_section.dart';
import 'sections/organizations_section.dart';
import 'sections/metrics_section.dart';

class AdminDashboardPage extends StatefulWidget {
	const AdminDashboardPage({
		super.key,
		required this.onViewAsUser,
		required this.profile,
	});

	final VoidCallback onViewAsUser;
	final UserProfile profile;

	@override
	State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
		with SingleTickerProviderStateMixin {
	late final AdminDashboardController _controller;
	late final AnimationController _animationController;
	AdminDashboardSection _selectedSection = AdminDashboardSection.campaignRequests;

	@override
	void initState() {
		super.initState();
		_controller = AdminDashboardController(Supabase.instance.client);
		_controller.loadDashboard();

		// Suscribirse a notificaciones en tiempo real
		_controller.subscribeToRealtime();

		_animationController = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 280),
		)..forward();
	}

	@override
	void dispose() {
		_animationController.dispose();
		_controller.dispose();
		super.dispose();
	}

	Future<void> _handleRefresh() => _controller.refresh();

	Future<void> _openCampaignReview(AdminPendingItem item) async {
		final result = await showCampaignReviewSheet(
			context: context,
			item: item,
			onApprove: (categoriaId) => _controller.approveCampaignRequest(item.id, categoriaId: categoriaId),
			onRequestChanges: (message) => _controller.requestChangesForCampaign(item.id, message),
		);

		if (!mounted || result == null) {
			return;
		}

		final messenger = ScaffoldMessenger.of(context);
		switch (result) {
			case CampaignReviewResult.approved:
				messenger.showSnackBar(
					const SnackBar(content: Text('Solicitud aprobada correctamente.')),
				);
				break;
			case CampaignReviewResult.changesRequested:
				messenger.showSnackBar(
					const SnackBar(content: Text('Se solicitaron cambios a la campaña.')),
				);
				break;
		}

		await _handleRefresh();
	}

	Future<void> _openDonationDetail(AdminPendingItem item) async {
		if (!mounted) {
			return;
		}
		final result = await showDonationDetailSheet(
			context: context,
			item: item,
			loadDetail: () => _controller.fetchDonationDetail(item.id),
			onApprove: () => _controller.approveDonation(item.id),
			onReject: () => _controller.rejectDonation(item.id),
		);

		if (!mounted || result == null) {
			return;
		}

		final messenger = ScaffoldMessenger.of(context);
		switch (result) {
			case DonationReviewResult.approved:
				messenger.showSnackBar(
					const SnackBar(content: Text('Donación aprobada correctamente.')),
				);
				break;
			case DonationReviewResult.rejected:
				messenger.showSnackBar(
					const SnackBar(content: Text('Donación rechazada y removida de pendientes.')),
				);
				break;
		}
	}

	Future<void> _openOrganizationReview(AdminPendingItem item) async {
		if (!mounted) {
			return;
		}
		final result = await showOrganizationReviewSheet(
			context: context,
			item: item,
			loadDetail: () => _controller.fetchOrganizationDetail(item.id),
			onApprove: (notes) => _controller.approveOrganization(item.id, notes: notes),
			onReject: (message) => _controller.rejectOrganization(item.id, message),
		);

		if (!mounted || result == null) {
			return;
		}

		final messenger = ScaffoldMessenger.of(context);
		switch (result) {
			case OrganizationReviewResult.approved:
				messenger.showSnackBar(
					const SnackBar(content: Text('Organización aprobada correctamente.')),
				);
				break;
			case OrganizationReviewResult.rejected:
				messenger.showSnackBar(
					const SnackBar(content: Text('Organización rechazada y notificada.')),
				);
				break;
		}

		await _handleRefresh();
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final canPop = Navigator.of(context).canPop();

		return Scaffold(
			backgroundColor: AppColors.lightBackground,
			appBar: AppBar(
				backgroundColor: Colors.white,
				elevation: 0,
				titleSpacing: 0,
				leading: canPop
						? IconButton(
							icon: const Icon(Icons.arrow_back),
							onPressed: () => Navigator.of(context).maybePop(),
						)
						: null,
				title: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						const AppLogo(symbolSize: 28),
						const SizedBox(width: 12),
						Flexible(
							child: Text(
								'Panel administrativo',
								overflow: TextOverflow.ellipsis,
								style: theme.textTheme.titleLarge?.copyWith(
									fontWeight: FontWeight.w700,
									color: AppColors.darkText,
								),
							),
						),
					],
				),
				actions: [
					TextButton.icon(
						onPressed: widget.onViewAsUser,
						icon: const Icon(Icons.visibility_outlined),
						label: const Text('Ver como usuario'),
					),
					const SizedBox(width: 12),
				],
			),
			body: SafeArea(
				child: AnimatedBuilder(
					animation: _controller,
					builder: (context, _) {
						final isLoading = _controller.isLoading;
						final error = _controller.errorMessage;
						final metrics = _controller.metrics;

						if (isLoading && metrics == null) {
							return const Center(child: CircularProgressIndicator());
						}

						if (error != null && metrics == null) {
							return AdminErrorState(
								message: error,
								onRetry: _handleRefresh,
							);
						}

						return LayoutBuilder(
							builder: (context, constraints) {
								final isWide = constraints.maxWidth >= 960;
								final navigation = _buildNavigation(isWide: isWide);
								final content = _buildSectionContent(
									section: _selectedSection,
									metrics: metrics,
									activeCampaigns: _controller.activeCampaigns,
									isLoading: isLoading,
									isWide: isWide,
									maxWidth: constraints.maxWidth,
								);

								if (isWide) {
									return Row(
										children: [
											navigation,
											Expanded(child: content),
										],
									);
								}

								return Column(
									children: [
										Expanded(child: content),
										navigation,
									],
								);
							},
						);
					},
				),
			),
		);
	}

	Widget _buildNavigation({required bool isWide}) {
		final navItems = <AdminNavItem>[
			AdminNavItem(
				section: AdminDashboardSection.metrics,
				label: 'Métricas',
				icon: Icons.insights_outlined,
				count: 0, // Sin notificaciones en métricas
			),
			AdminNavItem(
				section: AdminDashboardSection.campaignRequests,
				label: 'Solicitudes',
				icon: Icons.assignment_outlined,
				count: _controller.pendingCampaigns.length,
			),
			AdminNavItem(
				section: AdminDashboardSection.donations,
				label: 'Donaciones',
				icon: Icons.receipt_long_outlined,
				count: _controller.pendingDonations.length,
			),
			AdminNavItem(
				section: AdminDashboardSection.organizations,
				label: 'Organizaciones',
				icon: Icons.approval_outlined,
				count: _controller.pendingOrganizations.length,
			),
		];

		final selectedIndex = _selectedSection.index;

		if (isWide) {
			return NavigationRail(
				selectedIndex: selectedIndex,
				onDestinationSelected: (value) {
					setState(() => _selectedSection = AdminDashboardSection.values[value]);
				},
				labelType: NavigationRailLabelType.all,
				destinations: [
					for (final item in navItems)
						NavigationRailDestination(
							icon: AdminNavIcon(icon: item.icon, count: item.count),
							selectedIcon: AdminNavIcon(
								icon: item.icon,
								count: item.count,
								selected: true,
							),
							label: Text(item.label),
						),
				],
			);
		}

		return DecoratedBox(
			decoration: BoxDecoration(
				color: Colors.white,
				border: Border(
					top: BorderSide(color: AppColors.grayNeutral.withOpacity(0.35), width: 1),
				),
				boxShadow: const [
					BoxShadow(
						color: Color(0x14000000),
						offset: Offset(0, -2),
						blurRadius: 10,
					),
				],
			),
			child: NavigationBar(
				backgroundColor: Colors.transparent,
				destinations: [
					for (final item in navItems)
						NavigationDestination(
							icon: AdminNavIcon(icon: item.icon, count: item.count),
							selectedIcon: AdminNavIcon(
								icon: item.icon,
								count: item.count,
								selected: true,
							),
							label: item.label,
						),
				],
				height: 64,
				labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
				selectedIndex: selectedIndex,
				onDestinationSelected: (value) {
					setState(() => _selectedSection = AdminDashboardSection.values[value]);
				},
				elevation: 0,
			),
		);
	}

	Widget _buildSectionContent({
		required AdminDashboardSection section,
		required AdminDashboardMetrics? metrics,
		required List<AdminActiveCampaign> activeCampaigns,
		required bool isLoading,
		required bool isWide,
		required double maxWidth,
	}) {
		final campaignItems = _controller.pendingCampaigns;
		final donationItems = _controller.pendingDonations;
		final organizationItems = _controller.pendingOrganizations;

		final baseWidth = isWide ? maxWidth - 112 : maxWidth;
		final contentMaxWidth = baseWidth.clamp(320.0, 960.0).toDouble();
		final children = <Widget>[];

		if (section == AdminDashboardSection.metrics) {
			if (metrics != null) {
				children.add(
					AdminMetricsPanel(
						metrics: metrics,
						activeCampaigns: activeCampaigns,
					),
				);
			} else {
				children.add(
					const AdminEmptyState(
						message: 'Aún no tenemos métricas disponibles. Intenta recargar el panel en unos segundos.',
					),
				);
			}
		} else {
			if (section == AdminDashboardSection.campaignRequests) {
				children.add(AdminWelcomeHeader(profile: widget.profile));
				children.add(const SizedBox(height: 24));
			}

			switch (section) {
				case AdminDashboardSection.metrics:
					break;
				case AdminDashboardSection.campaignRequests:
					children.add(
						CampaignRequestsSection(
							items: campaignItems,
							onReview: _openCampaignReview,
						),
					);
					break;
				case AdminDashboardSection.donations:
					children.add(
						DonationsSection(
							items: donationItems,
							onViewDetail: _openDonationDetail,
						),
					);
					break;
				case AdminDashboardSection.organizations:
					children.add(
						OrganizationsSection(
							items: organizationItems,
							onReview: _openOrganizationReview,
						),
					);
					break;
			}
		}

		if (isLoading) {
			children.add(const SizedBox(height: 12));
			children.add(_buildUpdatingBanner(context));
		}

		children.add(const SizedBox(height: 24));

		return FadeTransition(
			opacity: CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
			child: RefreshIndicator(
				color: AppColors.bluePrimary,
				onRefresh: _handleRefresh,
				child: ListView(
					physics: const AlwaysScrollableScrollPhysics(),
					padding: const EdgeInsets.symmetric(vertical: 24),
					children: [
						Center(
							child: ConstrainedBox(
								constraints: BoxConstraints(maxWidth: contentMaxWidth),
								child: Padding(
									padding: const EdgeInsets.symmetric(horizontal: 24),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: children,
									),
								),
							),
						),
					],
				),
			),
		);
	}

	Widget _buildUpdatingBanner(BuildContext context) {
		final theme = Theme.of(context);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
			decoration: BoxDecoration(
				color: AppColors.bluePrimary.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(14),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					const SizedBox.square(
						dimension: 18,
						child: CircularProgressIndicator(strokeWidth: 2.2),
					),
					const SizedBox(width: 12),
					Text(
						'Actualizando información…',
						style: theme.textTheme.bodyMedium?.copyWith(
							color: AppColors.bluePrimary,
							fontWeight: FontWeight.w600,
						),
					),
				],
			),
		);
	}
}

