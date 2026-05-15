import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/campaign.dart';
import '../models/organization.dart';
import '../services/campaign_service.dart';
import '../theme/app_colors.dart';
import '../ui/widgets/highlight_wrapper.dart';

class OrganizationDetailPage extends StatelessWidget {
  final OrganizationSummary organization;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;
  final VoidCallback? onOpenWebsite;
  final bool fromNotification;

  const OrganizationDetailPage({
    super.key,
    required this.organization,
    this.onCall,
    this.onEmail,
    this.onOpenWebsite,
    this.fromNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    // memberSince: Desde enero 2025
    String? memberSince;
    if (organization.createdAt != null) {
      final d = organization.createdAt!.toLocal();
      const _months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
      ];
      memberSince = 'Desde ${_months[d.month - 1]} ${d.year}';
    }

    // Extraer galería de documentos
    final galleryUrls = <String>[];
    if (organization.description != null && organization.description!.contains('https://')) {
      final lines = organization.description!.split('\n');
      for (final line in lines) {
        if (line.contains('https://') && (line.contains('.jpg') || line.contains('.png'))) {
          final url = line.trim().replaceAll('- ', '');
          if (url.startsWith('https://')) {
            galleryUrls.add(url);
          }
        }
      }
    }

    // Descripción limpia
    String cleanDescription = organization.description ?? 'Esta organización aún no ha compartido su misión e historia.';
    if (galleryUrls.isNotEmpty) {
      final lines = cleanDescription.split('\n');
      final cleanLines = lines.where((line) => !line.contains('https://')).toList();
      cleanDescription = cleanLines.join('\n').trim();
      if (cleanDescription.isEmpty) {
        cleanDescription = 'Esta organización aún no ha compartido su misión e historia.';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkText, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          organization.name,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 Banner de notificación de organización
            if (fromNotification)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: HighlightWrapper(
                  shouldHighlight: true,
                  highlightColor: AppColors.bluePrimary,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.bluePrimary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          color: AppColors.bluePrimary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Organización verificada',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.bluePrimary,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Esta organización ha sido aprobada y verificada',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.bluePrimary.withValues(alpha: 0.8),
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
            // Header limpio (sin gradient azul) — profile style
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  // Logo grande con borde sutil + shadow
                  _buildLogo(),
                  const SizedBox(height: 16),
                  // Nombre + verified inline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          organization.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (organization.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.bluePrimary,
                          size: 22,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Badges (tipo + miembro desde) — sutiles, tinte azul
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (organization.type != null)
                        _HeaderChip(
                          icon: Icons.domain_rounded,
                          label: organization.type!,
                          color: AppColors.bluePrimary,
                        ),
                      if (memberSince != null)
                        _HeaderChip(
                          icon: Icons.calendar_today_rounded,
                          label: memberSince,
                          color: AppColors.darkText.withValues(alpha: 0.55),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Banda gradient 3px sutil — toque de marca, no fondo
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.bluePrimary,
                    AppColors.blueSecondary,
                  ],
                ),
              ),
            ),
            
            // Descripción mejorada
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con icono
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.bluePrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Acerca de la organización',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  
                  // Contenedor con fondo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.bluePrimary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Misión/Descripción
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.bluePrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.bluePrimary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Descripción',
                                    style: TextStyle(
                                      color: AppColors.bluePrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cleanDescription,
                                    style: TextStyle(
                                      color: AppColors.darkText.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (organization.type != null) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          
                          // Tipo de organización
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.greenSuccess.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.business_center_rounded,
                                  color: AppColors.greenSuccess,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tipo de organización',
                                    style: TextStyle(
                                      color: AppColors.greenSuccess,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    organization.type!,
                                    style: TextStyle(
                                      color: AppColors.darkText.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Campañas activas de esta organización
            const SizedBox(height: 8),
            _OrgCampaignsSection(orgName: organization.name),

            // Galería
            if (galleryUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.greenSuccess,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Galería',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.greenSuccess.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${galleryUrls.length}',
                            style: const TextStyle(
                              color: AppColors.greenSuccess,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: galleryUrls.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            galleryUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.darkText.withValues(alpha: 0.05),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.darkText.withValues(alpha: 0.3),
                                  size: 32,
                                ),
                              ),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppColors.darkText.withValues(alpha: 0.05),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppColors.bluePrimary),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            
            // Ubicación con mapa
            if (organization.hasAddress) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.orangeAction,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ubicación',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    const SizedBox(height: 16),

                    // Mapa decorativo con dirección destacada
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.orangeAction.withValues(alpha: 0.08),
                            AppColors.orangeAction.withValues(alpha: 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.orangeAction.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.orangeAction.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.orangeAction,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dirección',
                                  style: TextStyle(
                                    color: AppColors.orangeAction,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  organization.address!,
                                  style: TextStyle(
                                    color: AppColors.darkText.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Botón para abrir en Google Maps
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final encoded = Uri.encodeComponent(organization.address!);
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$encoded',
                          );
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text('Abrir en Google Maps'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.orangeAction,
                          side: BorderSide(
                            color: AppColors.orangeAction.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Contacto
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header simple
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Contacto',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (organization.hasDirectContact || organization.hasWebsite) ...[
                    // Teléfono
                    if (organization.phone != null && organization.phone!.isNotEmpty)
                      _ContactItem(
                        icon: Icons.phone_rounded,
                        iconColor: AppColors.greenSuccess,
                        label: 'Teléfono',
                        value: organization.phone!,
                        actionLabel: 'Llamar',
                        onTap: onCall,
                      ),
                    
                    if (organization.phone != null && organization.phone!.isNotEmpty &&
                        organization.email != null && organization.email!.isNotEmpty)
                      const SizedBox(height: 12),
                    
                    // Email
                    if (organization.email != null && organization.email!.isNotEmpty)
                      _ContactItem(
                        icon: Icons.email_rounded,
                        iconColor: AppColors.bluePrimary,
                        label: 'Correo',
                        value: organization.email!,
                        actionLabel: 'Escribir',
                        onTap: onEmail,
                      ),
                    
                    if ((organization.phone != null && organization.phone!.isNotEmpty ||
                        organization.email != null && organization.email!.isNotEmpty) &&
                        organization.website != null && organization.website!.isNotEmpty)
                      const SizedBox(height: 12),
                    
                    // Website
                    if (organization.website != null && organization.website!.isNotEmpty)
                      _ContactItem(
                        icon: Icons.language_rounded,
                        iconColor: AppColors.orangeAction,
                        label: 'Sitio web',
                        value: organization.website!,
                        actionLabel: 'Visitar',
                        onTap: onOpenWebsite,
                      ),
                  ] else
                    Text(
                      'No hay información de contacto disponible',
                      style: TextStyle(
                        color: AppColors.darkText.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final url = organization.logoUrl;
    const size = 108.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.12),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: (url == null || url.isEmpty)
            ? Container(
                color: AppColors.bluePrimary.withValues(alpha: 0.08),
                child: Icon(
                  Icons.business_rounded,
                  size: size * 0.45,
                  color: AppColors.bluePrimary.withValues(alpha: 0.55),
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.bluePrimary.withValues(alpha: 0.08),
                  child: Icon(
                    Icons.business_rounded,
                    size: size * 0.45,
                    color: AppColors.bluePrimary.withValues(alpha: 0.55),
                  ),
                ),
              ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget simple para item de contacto
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback? onTap;

  const _ContactItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.20),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Badge de icono grande
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // CTA grande
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 14,
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

/// Lista las campañas activas de una organización filtrando por nombre.
/// Si no hay match (la org no tiene campañas o el join cliente-side falla),
/// no renderiza nada — silencioso por diseño.
class _OrgCampaignsSection extends StatefulWidget {
  const _OrgCampaignsSection({required this.orgName});

  final String orgName;

  @override
  State<_OrgCampaignsSection> createState() => _OrgCampaignsSectionState();
}

class _OrgCampaignsSectionState extends State<_OrgCampaignsSection> {
  late final Future<List<CampaignSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CampaignSummary>> _load() async {
    try {
      final service = CampaignService(Supabase.instance.client);
      final all = await service.fetchActiveCampaigns(limit: 100);
      final target = widget.orgName.trim().toLowerCase();
      return all
          .where((c) =>
              (c.organizerName ?? '').trim().toLowerCase() == target)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CampaignSummary>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final campaigns = snapshot.data ?? const <CampaignSummary>[];
        if (campaigns.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Campañas activas',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${campaigns.length}',
                      style: const TextStyle(
                        color: AppColors.bluePrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Iniciativas vigentes lideradas por esta organización.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.darkText.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 14),
              ...campaigns.take(5).map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OrgCampaignTile(campaign: c),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _OrgCampaignTile extends StatelessWidget {
  const _OrgCampaignTile({required this.campaign});

  final CampaignSummary campaign;

  @override
  Widget build(BuildContext context) {
    final pct = campaign.completionPercentage.clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: campaign.coverUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      campaign.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.volunteer_activism_rounded,
                        color: AppColors.bluePrimary,
                        size: 26,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.bluePrimary,
                    size: 26,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    minHeight: 6,
                    backgroundColor:
                        AppColors.bluePrimary.withValues(alpha: 0.10),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.bluePrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${pct.toStringAsFixed(0)}% recaudado',
                      style: const TextStyle(
                        color: AppColors.bluePrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.people_rounded,
                      size: 12,
                      color: AppColors.darkText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${campaign.donorCount}',
                      style: TextStyle(
                        color: AppColors.darkText.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

