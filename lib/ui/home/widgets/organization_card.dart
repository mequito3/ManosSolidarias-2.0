import 'package:flutter/material.dart';

import '../../../models/organization.dart';
import '../../../theme/app_colors.dart';

class OrganizationHighlightCard extends StatelessWidget {
  const OrganizationHighlightCard({
    super.key,
    required this.organization,
    this.onTap,
  });

  final OrganizationSummary organization;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con color de acento
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // Logo más grande
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.bluePrimary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: organization.logoUrl != null && organization.logoUrl!.isNotEmpty
                            ? Image.network(
                                organization.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.bluePrimary.withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.business_rounded,
                                    size: 28,
                                    color: AppColors.bluePrimary,
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.bluePrimary.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.business_rounded,
                                  size: 28,
                                  color: AppColors.bluePrimary,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Info básica
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            organization.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              fontSize: 15,
                            ),
                          ),
                          if (organization.type != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.bluePrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                organization.type!,
                                style: const TextStyle(
                                  color: AppColors.bluePrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Descripción
                      if (organization.description != null && organization.description!.isNotEmpty)
                        Expanded(
                          child: Text(
                            organization.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.darkText.withValues(alpha: 0.65),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 12),
                      
                      // Footer con features e indicador
                      Row(
                        children: [
                          // Features
                          if (organization.hasWebsite)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.bluePrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.language_rounded,
                                size: 14,
                                color: AppColors.bluePrimary,
                              ),
                            ),
                          if (organization.hasWebsite && organization.hasDirectContact)
                            const SizedBox(width: 6),
                          if (organization.hasDirectContact)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.greenSuccess.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: AppColors.greenSuccess,
                              ),
                            ),
                          if ((organization.hasWebsite || organization.hasDirectContact) && organization.hasAddress)
                            const SizedBox(width: 6),
                          if (organization.hasAddress)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.orangeAction.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: AppColors.orangeAction,
                              ),
                            ),
                          
                          const Spacer(),
                          
                          // Badge verificada
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.bluePrimary,
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
      ),
    );
  }
}

class OrganizationRecentCard extends StatelessWidget {
  const OrganizationRecentCard({
    super.key,
    required this.organization,
    this.onTap,
  });

  final OrganizationSummary organization;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.greenSuccess.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con badge "Nuevo"
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.greenSuccess,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fiber_new_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Nuevo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (organization.logoUrl != null && organization.logoUrl!.isNotEmpty)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.greenSuccess.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.network(
                            organization.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.greenSuccess.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.business_rounded,
                                size: 20,
                                color: AppColors.greenSuccess,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.greenSuccess.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          size: 20,
                          color: AppColors.greenSuccess,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Nombre
                Text(
                  organization.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Tipo
                if (organization.type != null)
                  Text(
                    organization.type!,
                    style: TextStyle(
                      color: AppColors.darkText.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                
                const Spacer(),
                
                // Divider
                Container(
                  height: 1,
                  width: double.infinity,
                  color: AppColors.greenSuccess.withValues(alpha: 0.15),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                ),
                
                // Footer con features
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (organization.hasWebsite) ...[
                          Icon(
                            Icons.language_rounded,
                            size: 14,
                            color: AppColors.greenSuccess.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (organization.hasDirectContact) ...[
                          Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: AppColors.greenSuccess.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (organization.hasAddress)
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.greenSuccess.withValues(alpha: 0.7),
                          ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.greenSuccess.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrganizationContactCard extends StatelessWidget {
  const OrganizationContactCard({
    super.key,
    required this.organization,
    this.onTap,
  });

  final OrganizationSummary organization;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhone = organization.phone != null && organization.phone!.isNotEmpty;
    final hasEmail = organization.email != null && organization.email!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Logo
                _OrganizationLogo(url: organization.logoUrl, size: 52),
                
                const SizedBox(width: 14),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        organization.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (organization.type != null)
                        Text(
                          organization.type!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.darkText.withValues(alpha: 0.5),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Botones de contacto
                      Row(
                        children: [
                          if (hasPhone)
                            _ContactButton(
                              icon: Icons.phone_rounded,
                              label: 'Llamar',
                              color: AppColors.greenSuccess,
                              onPressed: () {
                                // TODO: Implementar llamada
                              },
                            ),
                          if (hasPhone && hasEmail) const SizedBox(width: 8),
                          if (hasEmail)
                            _ContactButton(
                              icon: Icons.email_rounded,
                              label: 'Correo',
                              color: AppColors.bluePrimary,
                              onPressed: () {
                                // TODO: Implementar email
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Indicador
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.darkText.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrganizationCompactTile extends StatelessWidget {
  const OrganizationCompactTile({
    super.key,
    required this.organization,
    this.onTap,
    this.trailing,
  });

  final OrganizationSummary organization;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Logo
                _OrganizationLogo(url: organization.logoUrl, size: 44),
                
                const SizedBox(width: 12),
                
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      Text(
                        organization.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      
                      const SizedBox(height: 3),
                      
                      // Tipo
                      if (organization.type != null)
                        Text(
                          organization.type!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.darkText.withValues(alpha: 0.5),
                          ),
                        ),
                      
                      const SizedBox(height: 6),
                      
                      // Features
                      Row(
                        children: [
                          if (organization.hasWebsite) ...[
                            Icon(
                              Icons.language_rounded,
                              size: 14,
                              color: AppColors.bluePrimary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (organization.hasDirectContact) ...[
                            Icon(
                              Icons.phone_rounded,
                              size: 14,
                              color: AppColors.bluePrimary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (organization.hasAddress)
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppColors.bluePrimary.withValues(alpha: 0.6),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Flecha
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.darkText.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrganizationLogo extends StatelessWidget {
  const _OrganizationLogo({required this.url, this.size = 44});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 4),
          color: AppColors.blueSecondary.withValues(alpha: 0.2),
        ),
        child: const Icon(Icons.approval_outlined, color: AppColors.blueSecondary),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: AppColors.blueSecondary.withValues(alpha: 0.2),
          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.blueSecondary),
        ),
      ),
    );
  }
}


