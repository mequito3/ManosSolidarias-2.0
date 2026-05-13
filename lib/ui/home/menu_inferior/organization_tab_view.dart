import 'package:flutter/material.dart';

import '../../../controllers/organization_controller.dart';
import '../../../models/organization.dart';
import '../../../theme/app_colors.dart';
import '../widgets/home_section.dart';
import '../widgets/organization_card.dart';
import 'shared_states.dart';

class OrganizationTabView extends StatefulWidget {
  const OrganizationTabView({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.onSelectOrganization,
    required this.onCreateOrganization,
  });

  final OrganizationController controller;
  final RetryCallback onRefresh;
  final ValueChanged<OrganizationSummary> onSelectOrganization;
  final VoidCallback onCreateOrganization;

  @override
  State<OrganizationTabView> createState() => _OrganizationTabViewState();
}

class _OrganizationTabViewState extends State<OrganizationTabView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  // Stagger animations: each section fades + slides in with an offset interval
  late final Animation<double> _fadeBanner;
  late final Animation<double> _fadeFeatured;
  late final Animation<double> _fadeRecent;
  late final Animation<double> _fadeContact;
  late final Animation<double> _fadeAll;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeBanner = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.00, 0.40, curve: Curves.easeOut),
    );
    _fadeFeatured = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.12, 0.52, curve: Curves.easeOut),
    );
    _fadeRecent = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );
    _fadeContact = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.38, 0.78, curve: Curves.easeOut),
    );
    _fadeAll = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.50, 0.90, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _stagger(Animation<double> anim, Widget child) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.controller.isLoading;
    final hasLoaded = widget.controller.hasLoadedInitially;
    final error = widget.controller.errorMessage;
    final organizations = widget.controller.organizations;
    final featured = widget.controller.featuredOrganizations;
    final contact = widget.controller.contactOrganizations;
    final recent = widget.controller.recentOrganizations;

    if (isLoading && !hasLoaded) {
      return const HomeTabLoadingState();
    }

    if (error != null && organizations.isEmpty) {
      return HomeTabErrorState(
        message: error,
        onRetry: widget.onRefresh,
      );
    }

    if (organizations.isEmpty) {
      return OrganizationEmptyState(
          onCreateOrganization: widget.onCreateOrganization);
    }

    final highlightedIds = <String>{
      for (final item in featured) item.id,
      for (final item in contact) item.id,
      for (final item in recent) item.id,
    };

    final remainingOrganizations = organizations
        .where((org) => !highlightedIds.contains(org.id))
        .toList();

    return RefreshIndicator(
      color: AppColors.bluePrimary,
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _stagger(
            _fadeBanner,
            OrganizationIntroBanner(organizationCount: organizations.length),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: HomeTabInlineError(
                  message: error, onRetry: widget.onRefresh),
            ),
          if (featured.isNotEmpty)
            _stagger(
              _fadeFeatured,
              HomeSection(
                title: 'Destacadas',
                subtitle: 'Organizaciones con presencia activa',
                icon: Icons.verified_user_rounded,
                iconColor: AppColors.bluePrimary,
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: featured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final organization = featured[index];
                      return OrganizationHighlightCard(
                        organization: organization,
                        onTap: () => widget.onSelectOrganization(organization),
                      );
                    },
                  ),
                ),
                padding: const EdgeInsets.only(top: 28, bottom: 24),
              ),
            ),
          if (recent.isNotEmpty)
            _stagger(
              _fadeRecent,
              HomeSection(
                title: 'Recientes',
                subtitle: 'Nuevas organizaciones registradas',
                icon: Icons.fiber_new_rounded,
                iconColor: AppColors.greenSuccess,
                child: SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recent.length > 8 ? 8 : recent.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return OrganizationRecentCard(
                        organization: recent[index],
                        onTap: () =>
                            widget.onSelectOrganization(recent[index]),
                      );
                    },
                  ),
                ),
                padding: const EdgeInsets.only(top: 16, bottom: 20),
              ),
            ),
          if (contact.isNotEmpty)
            _stagger(
              _fadeContact,
              HomeSection(
                title: 'Contacto rápido',
                subtitle: 'Comunícate directamente con estas organizaciones',
                icon: Icons.phone_in_talk_rounded,
                iconColor: AppColors.greenSuccess,
                child: Column(
                  children: contact
                      .take(5)
                      .map(
                        (organization) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OrganizationContactCard(
                            organization: organization,
                            onTap: () =>
                                widget.onSelectOrganization(organization),
                          ),
                        ),
                      )
                      .toList(),
                ),
                padding: const EdgeInsets.only(top: 16, bottom: 20),
              ),
            ),
          if (remainingOrganizations.isNotEmpty)
            _stagger(
              _fadeAll,
              HomeSection(
                title: 'Todas las organizaciones',
                subtitle: 'Red completa de entidades verificadas',
                icon: Icons.domain_rounded,
                iconColor: AppColors.bluePrimary,
                child: Column(
                  children: List.generate(
                    remainingOrganizations.take(20).length,
                    (i) {
                      final org = remainingOrganizations[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OrganizationCompactTile(
                          organization: org,
                          index: i,
                          onTap: () => widget.onSelectOrganization(org),
                        ),
                      );
                    },
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 20),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: AppColors.bluePrimary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  '${organizations.length} organizaciones verificadas',
                  style: TextStyle(
                    color: AppColors.darkText.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class OrganizationIntroBanner extends StatelessWidget {
  const OrganizationIntroBanner({super.key, this.organizationCount = 0});

  final int organizationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bluePrimary, AppColors.blueSecondary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -32,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Organizaciones verificadas',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        organizationCount > 0
                            ? '$organizationCount aliados revisados por el equipo'
                            : 'Aliados confiables revisados por el equipo',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
    );
  }
}



class OrganizationEmptyState extends StatelessWidget {
  const OrganizationEmptyState({super.key, required this.onCreateOrganization});

  final VoidCallback onCreateOrganization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.business_rounded, color: AppColors.bluePrimary, size: 40),
              const SizedBox(height: 16),
              Text(
                'Todavía no hay organizaciones públicas',
                style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nuestro equipo está verificando la documentación de las primeras organizaciones. Vuelve pronto para conocerlas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.72),
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}
