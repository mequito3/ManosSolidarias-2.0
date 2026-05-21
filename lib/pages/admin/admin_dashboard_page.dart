import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/admin_dashboard_controller.dart';
import '../../models/admin_dashboard.dart';
import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../ui/widgets/premium_app_bar.dart';
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
	AdminDashboardSection _selectedSection = AdminDashboardSection.metrics;

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
		final canPop = Navigator.of(context).canPop();

		return Scaffold(
			backgroundColor: AppColors.lightBackground,
			appBar: PremiumAppBar(
				title: 'Panel admin',
				showBack: canPop,
				onBack: () => Navigator.of(context).maybePop(),
				actions: [
					_ViewAsUserButton(onTap: widget.onViewAsUser),
					_AdminAvatarButton(
						profile: widget.profile,
						onTap: () => _showAdminProfileSheet(context, widget.profile),
					),
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
					top: BorderSide(color: AppColors.grayNeutral.withValues(alpha: 0.35), width: 1),
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

		// Welcome header visible only in metrics
		if (section == AdminDashboardSection.metrics) {
			children.add(AdminWelcomeHeader(
				profile: widget.profile,
				pendingCampaigns: _controller.pendingCampaigns.length,
				pendingDonations: _controller.pendingDonations.length,
				pendingOrganizations: _controller.pendingOrganizations.length,
			));
			children.add(const SizedBox(height: 20));
		}

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

// ──────────────── Acciones del AppBar admin ──────────────────────────────────

/// Botón pill "Vista usuario" — pasa al modo no-admin de la app.
class _ViewAsUserButton extends StatelessWidget {
  const _ViewAsUserButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Tooltip(
        message: 'Ver como usuario',
        child: Material(
          color: AppColors.bluePrimary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppColors.radiusRound),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppColors.space12,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove_red_eye_rounded,
                      color: AppColors.bluePrimary, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Vista usuario',
                    style: TextStyle(
                      color: AppColors.bluePrimary,
                      fontSize: AppColors.fontSizeXs,
                      fontWeight: AppColors.fontWeightExtraBold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar circular del admin que abre el bottom sheet de perfil.
class _AdminAvatarButton extends StatelessWidget {
  const _AdminAvatarButton({required this.profile, required this.onTap});
  final UserProfile profile;
  final VoidCallback onTap;

  String get _initial {
    final name = profile.displayName?.trim() ?? '';
    return name.isNotEmpty ? name.characters.first.toUpperCase() : 'A';
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = (profile.avatarUrl ?? '').trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space8,
        vertical: 10,
      ),
      child: Tooltip(
        message: profile.displayName ?? 'Perfil',
        child: Material(
          shape: const CircleBorder(),
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasAvatar ? null : AppColors.primaryGradient,
                color: hasAvatar ? Colors.white : null,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.bluePrimary.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(
                        profile.avatarUrl!.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initialFallback(),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return _initialFallback();
                        },
                      )
                    : _initialFallback(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _initialFallback() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: AppColors.fontWeightExtraBold,
          fontSize: AppColors.fontSizeBase,
        ),
      ),
    );
  }
}

class _AdminProfileSheetAvatar extends StatelessWidget {
  const _AdminProfileSheetAvatar({required this.profile, required this.initial});
  final UserProfile profile;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = (profile.avatarUrl ?? '').trim().isNotEmpty;
    final fallback = Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppColors.fontSize2xl,
          fontWeight: AppColors.fontWeightExtraBold,
        ),
      ),
    );
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                profile.avatarUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return fallback;
                },
              )
            : fallback,
      ),
    );
  }
}

void _showAdminProfileSheet(BuildContext context, UserProfile profile) {
  final initial = (profile.displayName?.trim().isNotEmpty ?? false)
      ? profile.displayName!.characters.first.toUpperCase()
      : 'A';
  final email = Supabase.instance.client.auth.currentUser?.email;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppColors.space12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppColors.radiusXl),
          boxShadow: AppColors.shadowLg,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.radiusXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero: tarjeta de identidad ──────────────────────
              _AdminProfileHero(
                profile: profile,
                initial: initial,
                email: email,
              ),

              // ── Cuerpo: info de cuenta ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppColors.space20,
                  AppColors.space20,
                  AppColors.space20,
                  AppColors.space16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProfileSectionLabel(text: 'Detalles de cuenta'),
                    const SizedBox(height: AppColors.space12),
                    if ((profile.phone ?? '').trim().isNotEmpty)
                      _ProfileInfoTile(
                        icon: Icons.phone_rounded,
                        label: 'Teléfono',
                        value: profile.phone!.trim(),
                      ),
                    if ((profile.city ?? '').trim().isNotEmpty)
                      _ProfileInfoTile(
                        icon: Icons.place_rounded,
                        label: 'Ciudad',
                        value: profile.city!.trim(),
                      ),
                    if ((profile.phone ?? '').trim().isEmpty &&
                        (profile.city ?? '').trim().isEmpty)
                      _ProfileEmptyTile(),
                    const SizedBox(height: AppColors.space16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.space12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusSm),
                        border: Border.all(
                          color: AppColors.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color:
                                AppColors.mediumText.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: AppColors.space8),
                          const Expanded(
                            child: Text(
                              'Sesión segura. Solo administradores tienen acceso a este panel.',
                              style: TextStyle(
                                color: AppColors.mediumText,
                                fontSize: AppColors.fontSizeXs,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
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
  );
}

class _AdminProfileHero extends StatelessWidget {
  const _AdminProfileHero({
    required this.profile,
    required this.initial,
    required this.email,
  });

  final UserProfile profile;
  final String initial;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        // Blobs decorativos
        Positioned(
          top: -36,
          right: -28,
          child: _HeroBlob(
            size: 140,
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        Positioned(
          bottom: -36,
          left: -24,
          child: _HeroBlob(
            size: 120,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppColors.space20,
            AppColors.space16,
            AppColors.space20,
            AppColors.space20,
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppColors.space16),
              _AdminProfileSheetAvatar(profile: profile, initial: initial),
              const SizedBox(height: AppColors.space12),
              Text(
                profile.displayName ?? 'Administrador',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppColors.fontSizeXl,
                  fontWeight: AppColors.fontWeightExtraBold,
                  letterSpacing: -0.4,
                  shadows: [
                    Shadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
              ),
              if ((email ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: AppColors.fontSizeSm,
                    fontWeight: AppColors.fontWeightMedium,
                  ),
                ),
              ],
              const SizedBox(height: AppColors.space12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppColors.space12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppColors.radiusRound),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Administrador del sistema',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppColors.fontSizeXs,
                        fontWeight: AppColors.fontWeightExtraBold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBlob extends StatelessWidget {
  const _HeroBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel({required this.text});
  final String text;

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
          text,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: AppColors.fontSizeSm,
            fontWeight: AppColors.fontWeightExtraBold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppColors.space8),
      padding: const EdgeInsets.all(AppColors.space12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Icon(icon, size: 18, color: AppColors.bluePrimary),
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mediumText,
                    fontSize: AppColors.fontSizeXs,
                    fontWeight: AppColors.fontWeightSemiBold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeBase,
                    fontWeight: AppColors.fontWeightSemiBold,
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

class _ProfileEmptyTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.bluePrimary,
          ),
          const SizedBox(width: AppColors.space12),
          const Expanded(
            child: Text(
              'Aún no agregaste teléfono ni ciudad a tu perfil.',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: AppColors.fontSizeSm,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
