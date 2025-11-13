import 'package:flutter/material.dart';

import '../../../controllers/organization_controller.dart';
import '../../../models/organization.dart';
import '../../../theme/app_colors.dart';
import '../widgets/home_section.dart';
import '../widgets/organization_card.dart';
import 'shared_states.dart';

class OrganizationTabView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isLoading = controller.isLoading;
    final hasLoaded = controller.hasLoadedInitially;
    final error = controller.errorMessage;
    final organizations = controller.organizations;
    final featured = controller.featuredOrganizations;
    final contact = controller.contactOrganizations;
    final recent = controller.recentOrganizations;

    if (isLoading && !hasLoaded) {
      return const HomeTabLoadingState();
    }

    if (error != null && organizations.isEmpty) {
      return HomeTabErrorState(
        message: error,
        onRetry: onRefresh,
      );
    }

    if (organizations.isEmpty) {
      return OrganizationEmptyState(onCreateOrganization: onCreateOrganization);
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
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const OrganizationIntroBanner(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: HomeTabInlineError(message: error, onRetry: onRefresh),
            ),
          if (featured.isNotEmpty)
            HomeSection(
              title: 'Destacadas',
              subtitle: 'Organizaciones con presencia activa',
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
                      onTap: () => onSelectOrganization(organization),
                    );
                  },
                ),
              ),
              padding: const EdgeInsets.only(top: 28, bottom: 24),
            ),
          if (recent.isNotEmpty)
            HomeSection(
              title: 'Recientes',
              subtitle: 'Nuevas organizaciones registradas',
              child: SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recent.length > 8 ? 8 : recent.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return OrganizationRecentCard(
                      organization: recent[index],
                      onTap: () => onSelectOrganization(recent[index]),
                    );
                  },
                ),
              ),
              padding: const EdgeInsets.only(top: 16, bottom: 20),
            ),
          if (contact.isNotEmpty)
            HomeSection(
              title: 'Contacto rápido',
              subtitle: 'Comunícate directamente con estas organizaciones',
              child: Column(
                children: contact
                    .take(5)
                    .map(
                      (organization) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OrganizationContactCard(
                          organization: organization,
                          onTap: () => onSelectOrganization(organization),
                        ),
                      ),
                    )
                    .toList(),
              ),
              padding: const EdgeInsets.only(top: 16, bottom: 20),
            ),
          if (remainingOrganizations.isNotEmpty)
            HomeSection(
              title: 'Todas las organizaciones',
              subtitle: 'Red completa de entidades verificadas',
              child: Column(
                children: remainingOrganizations
                    .take(20)
                    .map(
                      (organization) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OrganizationCompactTile(
                          organization: organization,
                          onTap: () => onSelectOrganization(organization),
                        ),
                      ),
                    )
                    .toList(),
              ),
              padding: const EdgeInsets.only(bottom: 20),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              '${organizations.length} organizaciones verificadas',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 12,
              ).copyWith(
                color: AppColors.darkText.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class OrganizationIntroBanner extends StatelessWidget {
  const OrganizationIntroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.bluePrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Organizaciones verificadas',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aliados confiables revisados por el equipo',
                  style: TextStyle(
                    color: AppColors.darkText.withValues(alpha: 0.6),
                    fontSize: 12,
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
              const Icon(Icons.approval_outlined, color: AppColors.bluePrimary, size: 40),
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
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreateOrganization,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Registrar organización'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}
