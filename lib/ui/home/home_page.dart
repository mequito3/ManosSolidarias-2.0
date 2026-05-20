import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/campaign_controller.dart';
import '../../controllers/donation_history_controller.dart';
import '../../controllers/kermesse_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/organization_controller.dart';
import '../../controllers/donor_trophy_controller.dart';
import '../../models/campaign.dart';
import '../../models/organization.dart';
import '../../models/solicitud.dart';
import '../../models/user_profile.dart';
import '../../services/campaign_service.dart';
import '../../services/donation_history_service.dart';
import '../../services/kermesse_service.dart';
import '../../services/notification_service.dart';
import '../../services/organization_service.dart';
import '../../services/donor_trophy_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../donations/donation_history_page.dart';
import '../kermesses/kermesse_list_page.dart';
import '../profile/profile_overview_page.dart';
import '../profile/profile_settings_page.dart';
import '../rewards/donor_trophies_page.dart';
import 'completed_campaigns_page.dart';
import 'my_requests_page.dart';
import '../solicitudes/create_solicitud_page.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_snackbar.dart';
import '../../pages/organizations/create_organization_page.dart';
import '../../pages/organization_detail_page.dart';
import 'search/campaign_search_page.dart';
import 'menu_inferior/campaign_detail/campaign_detail_page.dart';
import 'favorites_page.dart';
import 'menu_inferior/campaign_tab_view.dart';
import 'notifications/notifications_page.dart';
import 'menu_inferior/organization_tab_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.showAdminShortcut = false,
    this.onOpenAdminPanel,
    required this.profile,
    this.onProfileUpdated,
  });

  final bool showAdminShortcut;
  final VoidCallback? onOpenAdminPanel;
  final UserProfile profile;
  final Future<void> Function()? onProfileUpdated;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final CampaignService _campaignService;
  late final CampaignController _campaignController;
  late final OrganizationService _organizationService;
  late final OrganizationController _organizationController;
  late final KermesseController _kermesseController;
  late final DonationHistoryController _donationHistoryController;
  late final NotificationController _notificationController;
  late final DonorTrophyController _donorTrophyController;
  late final ProfileService _profileService;
  late UserProfile _profile;

  int _navigationIndex = 0;
  CampaignSortOption _sortOption = CampaignSortOption.recommended;
  String? _selectedCategory; // Filtro de categoría

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _campaignService = CampaignService(client);
    _organizationService = OrganizationService(client);
    _profileService = ProfileService(client);
    final notificationService = NotificationService(client);
    final donorTrophyService = DonorTrophyService(client);
    _kermesseController = KermesseController(KermesseService(client));
    _donationHistoryController =
        DonationHistoryController(DonationHistoryService(client));

    // 1. Cargar solo lo crítico para la primera pantalla
    _campaignController = CampaignController(_campaignService)
      ..loadCampaigns()
      ..subscribeToRealtime();
    _notificationController = NotificationController(notificationService)
      ..loadNotifications()
      ..subscribeToRealtime();

    _organizationController = OrganizationController(_organizationService);
    _donorTrophyController = DonorTrophyController(donorTrophyService);

    // 2. Diferir la carga pesada secundaria al finalizar el primer frame para no bloquear la UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _organizationController
        ..ensureLoaded()
        ..subscribeToRealtime();
      _donorTrophyController
        ..loadLeaderboard()
        ..subscribeToRealtime();
      _kermesseController.loadKermesses();
    });

    _profile = widget.profile;
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      setState(() => _profile = widget.profile);
    }
  }

  @override
  void dispose() {
    _campaignController.dispose();
    _organizationController.dispose();
    _kermesseController.dispose();
    _donationHistoryController.dispose();
    _notificationController.dispose();
  _donorTrophyController.dispose();
    super.dispose();
  }

  Future<void> _refreshCampaigns() => _campaignController.refreshCampaigns();
  Future<void> _refreshOrganizations() =>
      _organizationController.refreshOrganizations();

  void _openSearch() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CampaignSearchPage(
        campaignService: _campaignService,
        onOpenCampaign: (campaign) {
          Navigator.of(context).pop();
          _openCampaignDetail(campaign);
        },
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  void _openCampaignDetail(CampaignSummary campaign) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CampaignDetailPage(
          campaignSummary: campaign,
          campaignService: _campaignService,
          userProfile: widget.profile,
        ),
      ),
    );
  }

  void _handleSupport(CampaignSummary campaign) {
    _openCampaignDetail(campaign);
  }

  Future<void> _handleToggleFavorite(
    CampaignSummary campaign, {
    BuildContext? messengerContext,
  }) async {
    final result = await _campaignController.toggleFavorite(campaign);
    final contextForFeedback = messengerContext ?? (mounted ? context : null);
    if (contextForFeedback == null) {
      return;
    }

    if (result == null) {
      AppSnackBar.showError(
        contextForFeedback,
        'No pudimos actualizar tus favoritos. Intenta nuevamente.',
      );
      return;
    }

    if (result) {
      AppSnackBar.showSuccess(contextForFeedback, 'Añadido a tus favoritos.');
    } else {
      AppSnackBar.showInfo(contextForFeedback, 'Eliminado de tus favoritos.');
    }
  }

  Future<UserProfile?> _openProfileSettings({bool showSuccessMessage = false}) async {
    if (!mounted) {
      return null;
    }

    final updated = await Navigator.of(context).push<UserProfile?>(
      MaterialPageRoute(
        builder: (_) => ProfileSettingsPage(
          initialProfile: _profile,
          profileService: _profileService,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _profile = updated);
      if (widget.onProfileUpdated != null) {
        await widget.onProfileUpdated!();
        if (!mounted) {
          return updated;
        }
      }
      if (showSuccessMessage && updated.meetsCompletionCriteria) {
        AppSnackBar.showSuccess(
          context,
          'Perfil verificado. ¡Gracias por completar tu información!',
        );
      }
    }

    return updated;
  }

  Future<bool> _ensureProfileReady() async {
    if (_profile.meetsCompletionCriteria) {
      return true;
    }

    final updated = await _openProfileSettings(showSuccessMessage: true);
    if (updated?.meetsCompletionCriteria ?? false) {
      return true;
    }

    if (mounted) {
      AppSnackBar.showWarning(
        context,
        'Debes completar tu perfil antes de solicitar una campaña.',
      );
    }
    return false;
  }

  Future<void> _openCreateKermesse() async {
    if (!mounted) return;
    final ready = await _ensureProfileReady();
    if (!ready || !mounted) return;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateSolicitudPage(
          profile: _profile,
          initialTipo: SolicitudTipo.kermesse,
        ),
      ),
    );

    if (created == true && mounted) {
      _kermesseController.loadKermesses();
      AppSnackBar.showSuccess(
        context,
        'Tu kermesse fue registrada. La estamos revisando.',
      );
    }
  }

  Future<void> _openCreateSolicitud() async {
    if (!mounted) {
      return;
    }

    final ready = await _ensureProfileReady();
    if (!ready || !mounted) {
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateSolicitudPage(
          profile: _profile,
          initialTipo: SolicitudTipo.campania,
        ),
      ),
    );

    if (created == true && mounted) {
      _refreshCampaigns();
      AppSnackBar.showSuccess(
        context,
        'Gracias por compartir tu causa. La estamos revisando.',
      );
    }
  }

  void _handleMenuTap() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _handleNotificationsTap() {
    if (!mounted) return;
    _notificationController.loadNotifications();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(controller: _notificationController),
      ),
    );
  }

  void _openFavorites() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FavoriteCampaignsPage(
          controller: _campaignController,
          onOpenCampaign: _openCampaignDetail,
          onToggleFavorite: (context, campaign) => _handleToggleFavorite(
            campaign,
            messengerContext: context,
          ),
          onSupport: _handleSupport,
        ),
      ),
    );
  }

  void _openNotifications() {
    if (!mounted) return;
    _handleNotificationsTap();
  }

  void _openDonationHistory() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DonationHistoryPage(
          controller: _donationHistoryController,
        ),
      ),
    );
  }

  void _openRewards() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DonorTrophiesPage(controller: _donorTrophyController),
      ),
    );
  }

  void _openCompletedCampaigns() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompletedCampaignsPage(
          controller: _campaignController,
          campaignService: _campaignService,
          userProfile: _profile,
        ),
      ),
    );
  }

  void _openMyRequests() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyRequestsPage(
          campaignService: _campaignController.service,
          onOpenCampaign: _openCampaignDetail,
        ),
      ),
    );
  }

  void _handleDestinationSelected(int index) {
    if (!mounted) return;
    setState(() => _navigationIndex = index);
    if (index == 1) {
      _kermesseController.loadKermesses();
    } else if (index == 2) {
      _organizationController.ensureLoaded();
    }
  }

  Future<void> _openProfileOverview() async {
    if (!mounted) {
      return;
    }

    final updated = await Navigator.of(context).push<UserProfile?>(
      MaterialPageRoute(
        builder: (_) => ProfileOverviewPage(
          initialProfile: _profile,
          profileService: _profileService,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _profile = updated);
      if (widget.onProfileUpdated != null) {
        await widget.onProfileUpdated!();
      }
    }
  }

  void _handleSortSelected(CampaignSortOption option) {
    if (!mounted) return;
    if (_sortOption == option) {
      return;
    }
    setState(() => _sortOption = option);
  }

  Future<void> _handleSignOut() async {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'No pudimos cerrar sesión. Intenta nuevamente.',
      );
    }
  }

  Widget _buildCampaignTab() {
    return CampaignTabView(
      controller: _campaignController,
      profile: _profile,
      sortOption: _sortOption,
      onSortSelected: _handleSortSelected,
      onRefresh: _refreshCampaigns,
      onToggleFavorite: (campaign) => _handleToggleFavorite(campaign),
      onOpenCampaign: _openCampaignDetail,
      onSupportCampaign: _handleSupport,
      onCompleteProfile: () => _openProfileSettings(),
      campaignService: _campaignService,
      categoryFilter: _selectedCategory, // Filtro de categoría
      onClearCategoryFilter: _clearCategoryFilter,
    );
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _navigationIndex = 0; // Cambiar a tab de campañas
    });
  }

  void _clearCategoryFilter() {
    setState(() {
      _selectedCategory = null;
    });
  }

  Widget _buildOrganizationTab() {
    return OrganizationTabView(
      controller: _organizationController,
      onRefresh: _refreshOrganizations,
      onSelectOrganization: _openOrganizationDetail,
      onCreateOrganization: _openCreateOrganization,
    );
  }

  Future<void> _openCreateOrganization() async {
    if (!mounted) {
      return;
    }

    final ready = await _ensureProfileReady();
    if (!ready || !mounted) {
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateOrganizationPage(profile: _profile),
      ),
    );

    if (created == true && mounted) {
      AppSnackBar.showInfo(
        context,
        'Tu organización quedó en revisión. Recibirás una notificación al aprobarse.',
      );
    }
  }

  Widget? _buildFloatingActionButton() {
    switch (_navigationIndex) {
      case 0:
        // MEJORA: FAB con gradiente y mejor diseño
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.actionGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
            boxShadow: AppColors.shadowLg,
          ),
          child: FloatingActionButton.extended(
            onPressed: _openCreateSolicitud,
            icon: const Icon(Icons.add_circle_rounded, size: 24), // MEJORA: Ícono rounded
            label: const Text(
              'Crear campaña',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.0,
              ),
            ),
            backgroundColor: Colors.transparent, // MEJORA: Transparente para mostrar gradiente
            elevation: 0, // MEJORA: Sin elevación porque el Container tiene sombra
          ),
        );
      case 1:
        // Kermesses — FAB para crear nueva kermesse (consistencia con otros tabs)
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.actionGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
            boxShadow: AppColors.shadowLg,
          ),
          child: FloatingActionButton.extended(
            onPressed: _openCreateKermesse,
            icon: const Icon(Icons.festival_rounded, size: 24),
            label: const Text(
              'Crear kermesse',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.0,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );
      case 2:
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.actionGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
            boxShadow: AppColors.shadowLg,
          ),
          child: FloatingActionButton.extended(
            onPressed: _openCreateOrganization,
            icon: const Icon(Icons.add_business_rounded, size: 24),
            label: const Text(
              'Registrar organización',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.0,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );
      default:
        return null;
    }
  }

  Widget _buildNotificationsAction() {
    return AnimatedBuilder(
      animation: _notificationController,
      builder: (context, _) {
        final initialLoading =
            _notificationController.isLoading && !_notificationController.hasLoaded;
        final unread = _notificationController.unreadCount;
        final hasUnread = unread > 0;
        final iconWidget = initialLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Icon(
                hasUnread
                    ? Icons.notifications_active_rounded // MEJORA: Ícono rounded
                    : Icons.notifications_none_rounded, // MEJORA: Ícono rounded
              );

        final button = IconButton(
          icon: iconWidget,
          tooltip: 'Notificaciones',
          onPressed: _handleNotificationsTap,
        );

        if (hasUnread && !initialLoading) {
          final labelText = unread > 9 ? '9+' : unread.toString();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              button,
              Positioned(
                right: 8, // MEJORA: Mejor posicionamiento
                top: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppColors.space8,
                      vertical: AppColors.space4,
                    ), // MEJORA: Usar sistema de espaciados
                    decoration: BoxDecoration(
                      gradient: AppColors.actionGradient, // MEJORA: Usar gradiente
                      borderRadius: BorderRadius.circular(AppColors.radiusRound),
                      boxShadow: [ // MEJORA: Sombra para profundidad
                        BoxShadow(
                          color: AppColors.orangeAction.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      labelText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2, // MEJORA: Mejor legibilidad
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return button;
      },
    );
  }

  void _openOrganizationDetail(OrganizationSummary organization) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrganizationDetailPage(
          organization: organization,
          onCall: organization.phone != null && organization.phone!.isNotEmpty
              ? () {
                  _launchUriWithFeedback(
                    Uri.parse('tel:${_sanitizePhone(organization.phone!)}'),
                    failureMessage: 'No pudimos abrir la app de llamadas.',
                  );
                  Navigator.of(context).pop();
                }
              : null,
          onEmail: organization.email != null && organization.email!.isNotEmpty
              ? () {
                  _launchUriWithFeedback(
                    Uri(
                      scheme: 'mailto',
                      path: organization.email!.trim(),
                    ),
                    failureMessage: 'No pudimos redactar el correo.',
                  );
                  Navigator.of(context).pop();
                }
              : null,
          onOpenWebsite:
              organization.website != null && organization.website!.isNotEmpty
                  ? () {
                      _launchUriWithFeedback(
                        Uri.parse(organization.website!),
                        failureMessage:
                            'No pudimos abrir el sitio web de la organización.',
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
        ),
      ),
    );
  }

  Future<void> _launchUriWithFeedback(
    Uri uri, {
    required String failureMessage,
  }) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        AppSnackBar.showError(context, failureMessage);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, failureMessage);
    }
  }

  String _sanitizePhone(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      final char = String.fromCharCode(rune);
      if (RegExp(r'[0-9+]').hasMatch(char)) {
        buffer.write(char);
      }
    }
    final sanitized = buffer.toString();
    return sanitized.isEmpty ? raw.trim() : sanitized;
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar TANTO campaignController COMO notificationController
    return ListenableBuilder(
      listenable: Listenable.merge([_campaignController, _notificationController]),
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.lightBackground,
          floatingActionButton: _buildFloatingActionButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          appBar: _HomeTopBar(
            onMenuTap: _handleMenuTap,
            onSearchTap: _openSearch,
            notificationsButton: _buildNotificationsAction(),
            showAdminShortcut: widget.showAdminShortcut,
            onAdminTap: widget.onOpenAdminPanel,
          ),
          drawer: _HomeDrawer(
            profile: _profile,
            onSignOut: _handleSignOut,
            onFavoritesTap: _openFavorites,
            onMyRequestsTap: _openMyRequests,
            onProfileTap: _openProfileOverview,
            onViewDonationHistory: _openDonationHistory,
            onViewRewards: _openRewards,
            onViewCompletedCampaigns: _openCompletedCampaigns,
            campaigns: _campaignController.campaigns,
            onCategorySelected: _filterByCategory,
          ),
      bottomNavigationBar: _HomeBottomNav(
        selectedIndex: _navigationIndex,
        onDestinationSelected: _handleDestinationSelected,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _navigationIndex,
          children: [
            AnimatedBuilder(
              animation: _campaignController,
              builder: (_, __) => _buildCampaignTab(),
            ),
            KermesseTabView(
              controller: _kermesseController,
              onCreateKermesse: _openCreateKermesse,
            ),
            AnimatedBuilder(
              animation: _organizationController,
              builder: (_, __) => _buildOrganizationTab(),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}

class _HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeTopBar({
    required this.onMenuTap,
    required this.onSearchTap,
    required this.notificationsButton,
    this.showAdminShortcut = false,
    this.onAdminTap,
  });

  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final Widget notificationsButton;
  final bool showAdminShortcut;
  final VoidCallback? onAdminTap;

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.darkText,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(color: Colors.transparent),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, size: 26),
        onPressed: onMenuTap,
        tooltip: 'Menú',
      ),
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: AppLogo(
          symbolSize: 32,
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.darkText,
            letterSpacing: -0.5,
          ),
        ),
      ),
      centerTitle: false,
      actions: [
        if (showAdminShortcut && onAdminTap != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppColors.radiusRound),
                boxShadow: AppColors.shadowSm,
              ),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.space16,
                    vertical: AppColors.space8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusRound),
                  ),
                ),
                onPressed: onAdminTap,
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                label: const Text(
                  'Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        // Search pill button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Material(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onSearchTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
        ),
        notificationsButton,
        const SizedBox(width: 6),
      ],
    );
  }
}

// ─── Bottom Navigation Bar ──────────────────────────────────────────────────

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    _NavDestination(
      label: 'Campañas',
      icon: Icons.volunteer_activism_outlined,
      activeIcon: Icons.volunteer_activism_rounded,
    ),
    _NavDestination(
      label: 'Kermeses',
      icon: Icons.diversity_3_outlined,
      activeIcon: Icons.diversity_3_rounded,
    ),
    _NavDestination(
      label: 'Organizaciones',
      icon: Icons.business_outlined,
      activeIcon: Icons.business_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top gradient accent line
          Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  for (int i = 0; i < _destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        destination: _destinations[i],
                        isSelected: selectedIndex == i,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(AppColors.radiusRound),
              ),
              child: Icon(
                isSelected ? destination.activeIcon : destination.icon,
                size: 24,
                color: isSelected
                    ? Colors.white
                    : AppColors.darkText.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.bluePrimary
                    : AppColors.darkText.withValues(alpha: 0.45),
                letterSpacing: isSelected ? 0.2 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Drawer ──────────────────────────────────────────────────────────────────

class _HomeDrawer extends StatefulWidget {
  const _HomeDrawer({
    required this.profile,
    required this.onSignOut,
    required this.onFavoritesTap,
    required this.onMyRequestsTap,
    required this.onProfileTap,
    required this.onViewDonationHistory,
    required this.onViewRewards,
    required this.onViewCompletedCampaigns,
    required this.campaigns,
    required this.onCategorySelected,
  });

  final UserProfile profile;
  final Future<void> Function() onSignOut;
  final VoidCallback onFavoritesTap;
  final VoidCallback onMyRequestsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onViewDonationHistory;
  final VoidCallback onViewRewards;
  final VoidCallback onViewCompletedCampaigns;
  final List<CampaignSummary> campaigns;
  final void Function(String category) onCategorySelected;

  @override
  State<_HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<_HomeDrawer> {
  bool _categoriesExpanded = false;

  List<String> get _availableCategories {
    final categories = <String>{};
    for (final campaign in widget.campaigns) {
      if (campaign.category.isNotEmpty) categories.add(campaign.category);
    }
    return categories.toList()..sort();
  }

  @override
  void didUpdateWidget(_HomeDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaigns != widget.campaigns) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = _availableCategories;

    return Drawer(
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      child: Column(
        children: [
          _DrawerHeader(profile: widget.profile),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              children: [
                _DrawerSectionLabel(label: 'Mi cuenta'),
                _DrawerTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.bluePrimary,
                  title: 'Perfil',
                  subtitle: 'Actualiza tu información',
                  onTap: widget.onProfileTap,
                ),
                _DrawerTile(
                  icon: Icons.favorite_border_rounded,
                  iconColor: const Color(0xFFE91E63),
                  title: 'Mis favoritos',
                  subtitle: 'Campañas guardadas',
                  onTap: widget.onFavoritesTap,
                ),
                _DrawerTile(
                  icon: Icons.campaign_outlined,
                  iconColor: AppColors.orangeAction,
                  title: 'Mis solicitudes',
                  subtitle: 'Campañas que creaste',
                  onTap: widget.onMyRequestsTap,
                ),

                if (availableCategories.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _DrawerSectionLabel(label: 'Explorar'),
                  _DrawerTile(
                    icon: Icons.grid_view_rounded,
                    iconColor: AppColors.orangeAction,
                    title: 'Categorías',
                    subtitle: '${availableCategories.length} disponibles',
                    trailing: AnimatedRotation(
                      turns: _categoriesExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.darkText.withValues(alpha: 0.45),
                        size: 20,
                      ),
                    ),
                    onTap: () => setState(
                        () => _categoriesExpanded = !_categoriesExpanded),
                    popOnTap: false,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: _categoriesExpanded
                        ? Column(
                            children: availableCategories.map((category) {
                              final count = widget.campaigns
                                  .where((c) => c.category == category)
                                  .length;
                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onCategorySelected(category);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      54, 0, 20, 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: AppColors.dividerColor
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.darkText
                                                  .withValues(alpha: 0.85),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.darkText
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],

                const SizedBox(height: 18),
                _DrawerSectionLabel(label: 'Actividad'),
                _DrawerTile(
                  icon: Icons.emoji_events_outlined,
                  iconColor: const Color(0xFFFFB300),
                  title: 'Ranking solidario',
                  subtitle: 'Top donantes y trofeos',
                  onTap: widget.onViewRewards,
                ),
                _DrawerTile(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.greenSuccess,
                  title: 'Campañas completadas',
                  subtitle: 'Metas alcanzadas',
                  onTap: widget.onViewCompletedCampaigns,
                ),
                _DrawerTile(
                  icon: Icons.history_rounded,
                  iconColor: AppColors.blueSecondary,
                  title: 'Historial de donaciones',
                  subtitle: 'Recibos y comprobantes',
                  onTap: widget.onViewDonationHistory,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Logout fijo abajo ─────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                border: Border(
                  top: BorderSide(
                    color: AppColors.dividerColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: _DrawerTile(
                icon: Icons.logout_rounded,
                iconColor: AppColors.error,
                title: 'Cerrar sesión',
                subtitle: 'Salir de tu cuenta',
                titleColor: AppColors.error,
                onTap: widget.onSignOut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer header ─────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.profile});

  final UserProfile profile;

  String get _displayName {
    final name = profile.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Tu cuenta';
  }

  String? get _email {
    return Supabase.instance.client.auth.currentUser?.email;
  }

  String get _initials {
    final name = profile.displayName?.trim() ?? '';
    if (name.isEmpty) {
      final email = _email ?? '';
      return email.isNotEmpty ? email[0].toUpperCase() : 'M';
    }
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  String get _roleLabel => profile.isAdmin ? 'ADMINISTRADOR' : 'MIEMBRO';

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final email = _email;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Row(
            children: [
              // Avatar 56px a la izquierda
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: hasAvatar
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _InitialsAvatar(
                            initials: _initials,
                          ),
                        ),
                      )
                    : _InitialsAvatar(initials: _initials),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _roleLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
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
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bluePrimary, AppColors.blueSecondary],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

// ── Drawer section label ──────────────────────────────────────────────────────

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.darkText.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ── Drawer tile ───────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
    this.popOnTap = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool popOnTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (popOnTap) {
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 250), () {
              onTap?.call();
            });
          } else {
            onTap?.call();
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.3,
                        color: titleColor ?? AppColors.darkText,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: (titleColor ?? AppColors.darkText)
                            .withValues(alpha: 0.5),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.darkText.withValues(alpha: 0.25),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CampaignSearchDelegate extends SearchDelegate<CampaignSummary?> {
  CampaignSearchDelegate(this._service);

  final CampaignService _service;

  @override
  String get searchFieldLabel => 'Buscar campañas solidarias...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: AppColors.darkText.withValues(alpha: 0.35),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        icon: const Icon(Icons.close_rounded, size: 22),
        onPressed: () => query = '',
        tooltip: 'Limpiar',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: () => close(context, null),
      tooltip: 'Volver',
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildResultsView(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _EmptySuggestions(onExplore: () async {
        final results = await _service.fetchActiveCampaigns(limit: 10);
        if (!context.mounted) return;
        close(context, results.isNotEmpty ? results.first : null);
      });
    }
    return _buildResultsView(context);
  }

  Widget _buildResultsView(BuildContext context) {
    return FutureBuilder<List<CampaignSummary>>(
      future: _service.searchCampaigns(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.bluePrimary,
              strokeWidth: 2.5,
            ),
          );
        }

        if (snapshot.hasError) {
          var message = 'No pudimos buscar campañas. Intenta nuevamente.';
          final error = snapshot.error;
          if (error is CampaignServiceException) message = error.message;
          return _SearchError(
            message: message,
            onRetry: () => showResults(context),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) return const _SearchEmptyState();

        return Container(
          color: AppColors.lightBackground,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final campaign = results[index];
              return _SearchResultTile(
                campaign: campaign,
                onTap: () => close(context, campaign),
              );
            },
          ),
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.campaign,
    required this.onTap,
  });

  final CampaignSummary campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = campaign.goalAmount > 0
        ? (campaign.raisedAmount / campaign.goalAmount).clamp(0.0, 1.0)
        : 0.0;
    final pct = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.bluePrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: -0.2,
                          color: AppColors.darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.bluePrimary
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              campaign.category,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.bluePrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${campaign.donorCount} donadores',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  AppColors.darkText.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor:
                              AppColors.dividerColor.withValues(alpha: 0.5),
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.bluePrimary),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$pct% completado',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.bluePrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.darkText.withValues(alpha: 0.25),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: 0.05, curve: Curves.easeOutQuad);
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightBackground,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.grayNeutral.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.search_off_rounded,
                      size: 36, color: AppColors.grayNeutral),
                ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                const Text(
                  'Sin resultados',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.3,
                    color: AppColors.darkText,
                  ),
                ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
                const SizedBox(height: 6),
                Text(
                  'No encontramos campañas con ese término.\nPrueba con otras palabras.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.darkText.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ).animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.orangeAction),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySuggestions extends StatelessWidget {
  const _EmptySuggestions({required this.onExplore});

  final Future<void> Function() onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightBackground,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bluePrimary.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    size: 40,
                    color: AppColors.bluePrimary,
                  ),
                ).animate().fade(duration: 500.ms).scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                const Text(
                  '¿Qué campaña buscas?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.5,
                    color: AppColors.darkText,
                  ),
                ).animate().fade(duration: 400.ms, delay: 150.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
                const SizedBox(height: 8),
                Text(
                  'Escribe un nombre, causa o categoría\npara encontrar campañas solidarias.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkText.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                ).animate().fade(duration: 400.ms, delay: 250.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppColors.radiusRound),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusRound),
                      ),
                    ),
                    onPressed: onExplore,
                    icon: const Icon(Icons.explore_rounded, size: 20),
                    label: const Text(
                      'Ver campañas destacadas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ).animate().fade(duration: 400.ms, delay: 350.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad).shimmer(delay: 1000.ms, duration: 1500.ms, color: Colors.white.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

