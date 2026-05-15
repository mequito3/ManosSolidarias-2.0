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

    // Hero protagonista: la primera destacada (o reciente como fallback)
    final OrganizationSummary? hero = featured.isNotEmpty
        ? featured.first
        : (recent.isNotEmpty ? recent.first : null);
    final heroId = hero?.id;

    // Combinar destacadas + recientes (sin el hero), dedup por id
    final mergedIds = <String>{};
    final mergedHighlights = <OrganizationSummary>[];
    for (final org in [...featured, ...recent]) {
      if (org.id == heroId) continue;
      if (mergedIds.add(org.id)) mergedHighlights.add(org);
    }

    final highlightedIds = <String>{
      if (heroId != null) heroId,
      ...mergedIds,
      for (final item in contact) item.id,
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
          if (hero != null)
            _stagger(
              _fadeBanner,
              _FeaturedOrgHero(
                organization: hero,
                onTap: () => widget.onSelectOrganization(hero),
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: HomeTabInlineError(
                  message: error, onRetry: widget.onRefresh),
            ),
          if (mergedHighlights.isNotEmpty)
            _stagger(
              _fadeFeatured,
              HomeSection(
                title: 'Organizaciones aliadas',
                subtitle: 'Verificadas y activas en la comunidad',
                icon: Icons.verified_user_rounded,
                iconColor: AppColors.bluePrimary,
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: mergedHighlights.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final organization = mergedHighlights[index];
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
          const SizedBox(height: 160),
        ],
      ),
    );
  }
}

/// Hero protagonista del tab Organizaciones: card limpia blanca con logo
/// prominente a la izquierda, nombre/tipo/verificada a la derecha y descripcion
/// breve abajo. Estilo profile-card profesional, sin gradient azul de fondo.
class _FeaturedOrgHero extends StatelessWidget {
  const _FeaturedOrgHero({
    required this.organization,
    required this.onTap,
  });

  final OrganizationSummary organization;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        organization.description != null && organization.description!.isNotEmpty;
    final typeLabel = organization.type ?? 'Organización aliada';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Banda gradient sutil arriba (4px) — toque de marca, no fondo
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.bluePrimary,
                        AppColors.blueSecondary,
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fila superior: logo grande + info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo 84x84 con borde sutil
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.bluePrimary
                                    .withValues(alpha: 0.10),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.bluePrimary
                                      .withValues(alpha: 0.10),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: organization.hasLogo
                                  ? Image.network(
                                      organization.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.bluePrimary
                                            .withValues(alpha: 0.08),
                                        child: const Icon(
                                          Icons.business_rounded,
                                          color: AppColors.bluePrimary,
                                          size: 40,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.bluePrimary
                                          .withValues(alpha: 0.08),
                                      child: const Icon(
                                        Icons.business_rounded,
                                        color: AppColors.bluePrimary,
                                        size: 40,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tipo pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.bluePrimary
                                        .withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.domain_rounded,
                                        size: 11,
                                        color: AppColors.bluePrimary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          typeLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.bluePrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Nombre + verificada
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        organization.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.darkText,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                          height: 1.2,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    if (organization.isVerified) ...[
                                      const SizedBox(width: 6),
                                      const Padding(
                                        padding: EdgeInsets.only(top: 3),
                                        child: Icon(
                                          Icons.verified_rounded,
                                          size: 18,
                                          color: AppColors.bluePrimary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Descripcion
                      if (hasDescription) ...[
                        const SizedBox(height: 14),
                        Text(
                          organization.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: AppColors.darkText.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Footer link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Ver perfil',
                            style: TextStyle(
                              color: AppColors.bluePrimary
                                  .withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.bluePrimary
                                .withValues(alpha: 0.85),
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
