import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/campaign.dart';
import '../models/organization.dart';
import '../services/campaign_service.dart';
import '../services/location_geocoder.dart';
import '../theme/app_colors.dart';
import '../ui/widgets/app_network_image.dart';
import '../ui/widgets/detail_section.dart';
import '../ui/widgets/glass_circle_button.dart';
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
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      memberSince = 'Desde ${_months[d.month - 1]} ${d.year}';
    }

    // Extraer galería de documentos
    final galleryUrls = <String>[];
    if (organization.description != null &&
        organization.description!.contains('https://')) {
      final lines = organization.description!.split('\n');
      for (final line in lines) {
        if (line.contains('https://') &&
            (line.contains('.jpg') || line.contains('.png'))) {
          final url = line.trim().replaceAll('- ', '');
          if (url.startsWith('https://')) {
            galleryUrls.add(url);
          }
        }
      }
    }

    // Descripción limpia
    String cleanDescription =
        organization.description ??
        'Esta organización aún no ha compartido su misión e historia.';
    if (galleryUrls.isNotEmpty) {
      final lines = cleanDescription.split('\n');
      final cleanLines = lines
          .where((line) => !line.contains('https://'))
          .toList();
      cleanDescription = cleanLines.join('\n').trim();
      if (cleanDescription.isEmpty) {
        cleanDescription =
            'Esta organización aún no ha compartido su misión e historia.';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: GlassCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            child: GlassCircleButton(
              icon: Icons.ios_share_rounded,
              onTap: () => _handleShareOrganization(context),
              tooltip: 'Compartir organización',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── COVER hero detrás del AppBar transparente ─────────────
            _OrgCoverHero(imageUrl: _coverImageUrlForType(organization.type)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner de notificación de organización
                  if (fromNotification) ...[
                    _buildNotificationCard(context),
                    const SizedBox(height: 14),
                  ],
                  // ── HEADER profile (tarjeta flotante) ───────────────
                  _buildProfileCard(memberSince),
                  const SizedBox(height: 14),
                  // ── ACERCA DE ───────────────────────────────────────
                  DetailSection(
                    accent: AppColors.bluePrimary,
                    title: 'Acerca de',
                    child: Text(
                      cleanDescription,
                      style: TextStyle(
                        color: AppColors.darkText.withValues(alpha: 0.78),
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── CONTACTO ─────────────────────────────────────────────
                  DetailSection(
                    accent: AppColors.bluePrimary,
                    title: 'Contacto',
                    child:
                        (organization.hasDirectContact ||
                            organization.hasWebsite)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (organization.phone != null &&
                                  organization.phone!.isNotEmpty)
                                _ContactItem(
                                  accentColor: AppColors.greenSuccess,
                                  icon: Icons.phone_rounded,
                                  label: 'Teléfono',
                                  value: organization.phone!,
                                  actionLabel: 'Llamar',
                                  onTap: onCall,
                                ),
                              if (organization.phone != null &&
                                  organization.phone!.isNotEmpty &&
                                  organization.email != null &&
                                  organization.email!.isNotEmpty)
                                const SizedBox(height: 10),
                              if (organization.email != null &&
                                  organization.email!.isNotEmpty)
                                _ContactItem(
                                  accentColor: AppColors.bluePrimary,
                                  icon: Icons.email_rounded,
                                  label: 'Correo',
                                  value: organization.email!,
                                  actionLabel: 'Escribir',
                                  onTap: onEmail,
                                ),
                              if ((organization.phone != null &&
                                          organization.phone!.isNotEmpty ||
                                      organization.email != null &&
                                          organization.email!.isNotEmpty) &&
                                  organization.website != null &&
                                  organization.website!.isNotEmpty)
                                const SizedBox(height: 10),
                              if (organization.website != null &&
                                  organization.website!.isNotEmpty)
                                _ContactItem(
                                  accentColor: AppColors.orangeAction,
                                  icon: Icons.language_rounded,
                                  label: 'Sitio web',
                                  value: organization.website!,
                                  actionLabel: 'Visitar',
                                  onTap: onOpenWebsite,
                                ),
                            ],
                          )
                        : Text(
                            'No hay información de contacto disponible',
                            style: TextStyle(
                              color: AppColors.darkText.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                  ),
                  // ── CAMPAÑAS ACTIVAS (FutureBuilder, conditional) ─────────
                  _OrgCampaignsSection(orgName: organization.name),

                  // ── UBICACION ─────────────────────────────────────────────
                  if (organization.hasAddress) ...[
                    const SizedBox(height: 14),
                    DetailSection(
                      accent: AppColors.orangeAction,
                      title: 'Ubicación',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.orangeAction.withValues(
                                alpha: 0.06,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.orangeAction.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              organization.address!,
                              style: TextStyle(
                                color: AppColors.darkText.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Mapa real (geocode con Nominatim + flutter_map)
                          _OrgLocationMap(address: organization.address!),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                final encoded = Uri.encodeComponent(
                                  organization.address!,
                                );
                                final uri = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$encoded',
                                );
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.orangeAction,
                                side: BorderSide(
                                  color: AppColors.orangeAction.withValues(
                                    alpha: 0.40,
                                  ),
                                  width: 1.4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Abrir en Google Maps',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── GALERIA (al final, contenido secundario) ──────────────
                  if (galleryUrls.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    DetailSection(
                      accent: AppColors.greenSuccess,
                      title: 'Galería',
                      trailingBadge: '${galleryUrls.length}',
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: galleryUrls.length,
                        itemBuilder: (context, index) {
                          return AppNetworkImage(
                            url: galleryUrls[index],
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(10),
                            placeholder: Container(
                              color: AppColors.darkText.withValues(alpha: 0.05),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.bluePrimary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: Container(
                              color: AppColors.darkText.withValues(alpha: 0.05),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.darkText.withValues(
                                    alpha: 0.3,
                                  ),
                                  size: 28,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShareOrganization(BuildContext context) async {
    final lines = <String>[
      organization.name,
      if (organization.type != null) organization.type!,
      if (organization.address != null) '📍 ${organization.address}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Organización copiada al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLogo() {
    final url = organization.logoUrl;
    const size = 84.0;

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
            : AppNetworkImage(
                url: url,
                fit: BoxFit.cover,
                errorWidget: Container(
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

  /// Banner "organización verificada" cuando se llega desde una notificación.
  Widget _buildNotificationCard(BuildContext context) {
    return HighlightWrapper(
      shouldHighlight: true,
      highlightColor: AppColors.bluePrimary,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bluePrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.bluePrimary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
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
    );
  }

  /// Tarjeta flotante con el logo, nombre y chips de la organización. Mismo
  /// estilo de tarjeta (blanca, radio 20, sombra doble) que [DetailSection].
  Widget _buildProfileCard(String? memberSince) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 12),
          Text(
            organization.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              if (organization.type != null)
                _HeaderChip(
                  label: organization.type!,
                  color: AppColors.bluePrimary,
                ),
              if (organization.isVerified)
                _HeaderChip(label: 'Verificada', color: AppColors.greenSuccess),
              if (memberSince != null)
                _HeaderChip(
                  label: memberSince,
                  color: AppColors.darkText.withValues(alpha: 0.55),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.color});

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
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// Item de contacto: label + valor (vía DetailInfoRow compartido) + CTA solido
class _ContactItem extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback? onTap;

  const _ContactItem({
    required this.accentColor,
    required this.icon,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: accentColor.withValues(alpha: 0.20),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Info (label + valor) reutilizando el widget compartido para
              // que se vea idéntica a campaña/kermesse.
              Expanded(
                child: DetailInfoRow(
                  label: label,
                  value: value,
                  icon: icon,
                  accent: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              // CTA solido (sin icono ni flecha)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
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
          .where((c) => (c.organizerName ?? '').trim().toLowerCase() == target)
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

        return Column(
          children: [
            const SizedBox(height: 14),
            DetailSection(
              accent: AppColors.bluePrimary,
              title: 'Campañas activas',
              trailingBadge: '${campaigns.length}',
              child: Column(
                children: [
                  for (var i = 0; i < campaigns.take(5).length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == campaigns.take(5).length - 1 ? 0 : 10,
                      ),
                      child: _OrgCampaignTile(campaign: campaigns[i]),
                    ),
                ],
              ),
            ),
          ],
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
                    child: AppNetworkImage(
                      url: campaign.coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: const Icon(
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
                    backgroundColor: AppColors.bluePrimary.withValues(
                      alpha: 0.10,
                    ),
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
                    const SizedBox(width: 12),
                    Text(
                      '${campaign.donorCount} donadores',
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

/// Mapa tipo -> URL Unsplash curada. Imagenes elegidas por temaitica
/// solidaria/comunitaria. Si la URL falla, errorBuilder muestra fallback
/// gradient (la pagina no se rompe).
const Map<String, String> _orgTypeImages = {
  'Fundación':
      'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=900&q=70&auto=format&fit=crop',
  'Asociación':
      'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=900&q=70&auto=format&fit=crop',
  'Colectivo':
      'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=900&q=70&auto=format&fit=crop',
  'Cooperativa':
      'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=900&q=70&auto=format&fit=crop',
  'Emprendimiento social':
      'https://images.unsplash.com/photo-1559136555-9303baea8ebd?w=900&q=70&auto=format&fit=crop',
  'Otro':
      'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=900&q=70&auto=format&fit=crop',
};

const String _orgDefaultCoverImage =
    'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?w=900&q=70&auto=format&fit=crop';

String _coverImageUrlForType(String? type) {
  if (type == null) return _orgDefaultCoverImage;
  return _orgTypeImages[type] ?? _orgDefaultCoverImage;
}

/// Cover banner ambiente (180h) con overlay sutil para futura legibilidad
/// si se quiere superponer texto. Si la imagen falla, fallback a gradient.
class _OrgCoverHero extends StatelessWidget {
  const _OrgCoverHero({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            url: imageUrl,
            fit: BoxFit.cover,
            placeholder: _fallbackGradient(),
            errorWidget: _fallbackGradient(),
          ),
          // Overlay sutil para conectar con el header blanco abajo
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x33000000)],
                stops: [0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackGradient() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blueSecondary, AppColors.bluePrimaryDark],
        ),
      ),
    );
  }
}

/// Mapa real de la ubicacion. Geocodifica la direccion con Nominatim
/// (LocationGeocoder) y renderiza un flutter_map con marcador. Si la
/// geocodificacion falla o esta cargando, muestra placeholder.
class _OrgLocationMap extends StatefulWidget {
  const _OrgLocationMap({required this.address});

  final String address;

  @override
  State<_OrgLocationMap> createState() => _OrgLocationMapState();
}

class _OrgLocationMapState extends State<_OrgLocationMap> {
  late final Future<LatLng?> _future;

  @override
  void initState() {
    super.initState();
    _future = kermesseLocationGeocoder.geocode(widget.address);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _placeholder('Cargando mapa…');
        }
        final point = snapshot.data;
        if (point == null) {
          return _placeholder('No pudimos ubicar esta dirección en el mapa');
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.manos.solidarias',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.orangeAction,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orangeAction.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.place_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder(String message) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.orangeAction.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orangeAction.withValues(alpha: 0.15),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.darkText.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
