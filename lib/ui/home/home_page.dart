import 'package:flutter/material.dart';
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

    _campaignController = CampaignController(_campaignService)
      ..loadCampaigns();
    _organizationController = OrganizationController(_organizationService)
      ..ensureLoaded();
    _notificationController = NotificationController(notificationService)
      ..loadNotifications();
    _notificationController.subscribeToRealtime();
    _donorTrophyController = DonorTrophyController(donorTrophyService)
      ..loadLeaderboard();
    _kermesseController.loadKermesses();
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
    showSearch<CampaignSummary?>(
      context: context,
      delegate: CampaignSearchDelegate(_campaignService),
    ).then((campaign) {
      if (!mounted || campaign == null) {
        return;
      }
      _openCampaignDetail(campaign);
    });
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
          startAtTypeSelection: true,
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
    _notificationController.loadNotifications(forceRefresh: true);
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

  void _openKermesses() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KermesseListPage(controller: _kermesseController),
      ),
    );
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
        builder: (_) => CompletedCampaignsPage(controller: _campaignController),
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
      donorTrophyController: _donorTrophyController,
      onViewLeaderboard: _openRewards,
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
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.transparent, // MEJORA: Transparente para mostrar gradiente
            elevation: 0, // MEJORA: Sin elevación porque el Container tiene sombra
          ),
        );
      case 1:
        // MEJORA: FAB con gradiente primary
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
            boxShadow: AppColors.shadowLg,
          ),
          child: FloatingActionButton.extended(
            onPressed: _openCreateOrganization,
            icon: const Icon(Icons.add_business_rounded, size: 24), // MEJORA: Ícono rounded
            label: const Text(
              'Registrar organización',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
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
            onSignOut: _handleSignOut,
            onFavoritesTap: _openFavorites,
            onMyRequestsTap: _openMyRequests,
            onProfileTap: _openProfileOverview,
            onViewKermesses: _openKermesses,
            onViewDonationHistory: _openDonationHistory,
            onViewRewards: _openRewards,
            onViewCompletedCampaigns: _openCompletedCampaigns,
            campaigns: _campaignController.campaigns,
            onCategorySelected: _filterByCategory,
          ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navigationIndex,
        onDestinationSelected: _handleDestinationSelected,
        elevation: 8, // MEJORA: Sombra sutil
        backgroundColor: AppColors.cardBackground, // MEJORA: Fondo consistente
        surfaceTintColor: Colors.transparent, // MEJORA: Sin tinte
        indicatorColor: AppColors.bluePrimary.withValues(alpha: 0.15), // MEJORA: Indicador más sutil
        height: 70, // MEJORA: Más altura para mejor touch target
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism_rounded), // MEJORA: Ícono rounded cuando está seleccionado
            label: 'Campañas',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business_rounded), // MEJORA: Ícono rounded cuando está seleccionado
            label: 'Organizaciones',
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _navigationIndex,
          children: [
            AnimatedBuilder(
              animation: _campaignController,
              builder: (_, __) => _buildCampaignTab(),
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
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0, // MEJORA: Sin elevación inicial
      scrolledUnderElevation: 2, // MEJORA: Sombra cuando se hace scroll
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white, // MEJORA: Sin tinte al hacer scroll
      foregroundColor: AppColors.darkText,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, size: 26), // MEJORA: Ícono rounded y más grande
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
            letterSpacing: -0.5, // MEJORA: Mejor spacing
          ),
        ),
      ),
      centerTitle: false,
      actions: [
        if (showAdminShortcut && onAdminTap != null)
          Padding(
            padding: const EdgeInsets.only(right: AppColors.space8),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient, // MEJORA: Gradiente
                borderRadius: BorderRadius.circular(AppColors.radiusRound),
                boxShadow: AppColors.shadowSm, // MEJORA: Sombra sutil
              ),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white, // MEJORA: Texto blanco sobre gradiente
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.space16,
                    vertical: AppColors.space8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusRound),
                  ),
                ),
                onPressed: onAdminTap,
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 18), // MEJORA: Ícono rounded
                label: const Text(
                  'Panel admin',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.search_rounded, size: 26), // MEJORA: Ícono rounded y más grande
          tooltip: 'Buscar campañas',
          onPressed: onSearchTap,
        ),
        notificationsButton,
        const SizedBox(width: AppColors.space8), // MEJORA: Usar sistema de espaciados
      ],
    );
  }
}

class _HomeDrawer extends StatefulWidget {
  const _HomeDrawer({
    required this.onSignOut,
    required this.onFavoritesTap,
    required this.onMyRequestsTap,
    required this.onProfileTap,
    required this.onViewKermesses,
    required this.onViewDonationHistory,
    required this.onViewRewards,
    required this.onViewCompletedCampaigns,
    required this.campaigns,
    required this.onCategorySelected,
  });

  final Future<void> Function() onSignOut;
  final VoidCallback onFavoritesTap;
  final VoidCallback onMyRequestsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onViewKermesses;
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

  // Obtener categorías con campañas activas
  List<String> get _availableCategories {
    final categories = <String>{};
    for (final campaign in widget.campaigns) {
      if (campaign.category.isNotEmpty) {
        categories.add(campaign.category);
      }
    }
    final list = categories.toList()..sort();
    return list;
  }

  @override
  void didUpdateWidget(_HomeDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si las campañas cambiaron, recalcular categorías
    if (oldWidget.campaigns != widget.campaigns) {
      setState(() {
        // Forzar rebuild para actualizar categorías
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = _availableCategories;
    
    return Drawer(
      child: Column(
        children: [
          // Header simple
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 15, 24, 24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(
                    symbolSize: 32,
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Juntos hacemos la diferencia',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Opciones principales
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerTile(
                  icon: Icons.account_circle_rounded,
                  title: 'Perfil',
                  subtitle: 'Actualiza tu información personal',
                  onTap: widget.onProfileTap,
                ),
                _DrawerTile(
                  icon: Icons.favorite_rounded,
                  title: 'Mis favoritos',
                  subtitle: 'Accede rápido a tus apoyos',
                  onTap: widget.onFavoritesTap,
                ),
                _DrawerTile(
                  icon: Icons.campaign_rounded,
                  title: 'Mis solicitudes',
                  subtitle: 'Gestiona las campañas que creaste',
                  onTap: widget.onMyRequestsTap,
                ),
                
                // Sección de categorías desplegable
                if (availableCategories.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.orangeAction.withValues(alpha: 0.1),
                      child: Icon(Icons.category_rounded, color: AppColors.orangeAction, size: 22),
                    ),
                    title: const Text(
                      'Categorías',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${availableCategories.length} disponibles',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mediumText.withValues(alpha: 0.7),
                      ),
                    ),
                    trailing: Icon(
                      _categoriesExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.bluePrimary,
                    ),
                    onTap: () {
                      setState(() {
                        _categoriesExpanded = !_categoriesExpanded;
                      });
                    },
                  ),
                  if (_categoriesExpanded)
                    ...availableCategories.map((category) {
                      final count = widget.campaigns.where((c) => c.category == category).length;
                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 72, right: 16),
                        title: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bluePrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.bluePrimary,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onCategorySelected(category);
                        },
                      );
                    }).toList(),
                  const Divider(height: 1),
                ],
                
                _DrawerTile(
                  icon: Icons.emoji_events_rounded,
                  title: 'Ranking solidario',
                  subtitle: 'Descubre los trofeos y el Top 3 de donantes',
                  onTap: widget.onViewRewards,
                ),
                _DrawerTile(
                  icon: Icons.check_circle_rounded,
                  title: 'Campañas completadas',
                  subtitle: 'Celebra las metas alcanzadas',
                  onTap: widget.onViewCompletedCampaigns,
                ),
                _DrawerTile(
                  icon: Icons.storefront_rounded,
                  title: 'Ver kermesses',
                  subtitle: 'Encuentra eventos solidarios en tu comunidad',
                  onTap: widget.onViewKermesses,
                ),
                _DrawerTile(
                  icon: Icons.history_rounded,
                  title: 'Historial de donaciones',
                  subtitle: 'Consulta tus recibos y comprobantes',
                  onTap: widget.onViewDonationHistory,
                ),
              ],
            ),
          ),
          // Cerrar sesión en la parte inferior
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
            onTap: widget.onSignOut,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
        child: Icon(icon, color: AppColors.bluePrimary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.mediumText.withValues(alpha: 0.7),
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        if (onTap != null) {
          onTap!();
        }
      },
    );
  }
}

class CampaignSearchDelegate extends SearchDelegate<CampaignSummary?> {
  CampaignSearchDelegate(this._service);

  final CampaignService _service;

  @override
  String get searchFieldLabel => 'Buscar campañas solidarias';

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) {
      return null;
    }
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsView();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _EmptySuggestions(onExplore: () async {
        final results = await _service.fetchActiveCampaigns(limit: 10);
        if (!context.mounted) {
          return;
        }
        close(context, results.isNotEmpty ? results.first : null);
      });
    }
    return _buildResultsView();
  }

  Widget _buildResultsView() {
    return FutureBuilder<List<CampaignSummary>>(
      future: _service.searchCampaigns(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          var message = 'No pudimos buscar campañas. Intenta nuevamente.';
          final error = snapshot.error;
          if (error is CampaignServiceException) {
            message = error.message;
          }
          return _SearchError(
            message: message,
            onRetry: () => showResults(context),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const _SearchEmptyState();
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final campaign = results[index];
            return ListTile(
              title: Text(campaign.title),
              subtitle:
                  Text('${campaign.category} · ${campaign.donorCount} donadores'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => close(context, campaign),
            );
          },
        );
      },
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.grayNeutral),
            const SizedBox(height: 12),
            Text(
              'No encontramos campañas con ese término.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba con otra palabra clave o explora las campañas destacadas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.7),
                  ),
            ),
          ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore,
                size: 48, color: AppColors.bluePrimary),
            const SizedBox(height: 12),
            Text(
              'Empieza a buscar campañas solidarias.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onExplore,
              child: const Text('Ver campañas destacadas'),
            ),
          ],
        ),
      ),
    );
  }
}

