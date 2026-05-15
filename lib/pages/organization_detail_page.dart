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
            // ── HEADER profile ────────────────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
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
                        _HeaderChip(
                          label: 'Verificada',
                          color: AppColors.greenSuccess,
                        ),
                      if (memberSince != null)
                        _HeaderChip(
                          label: memberSince,
                          color: AppColors.darkText.withValues(alpha: 0.55),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const _SectionDivider(),

            // ── ACERCA DE ─────────────────────────────────────────────
            _SectionContainer(
              accentColor: AppColors.bluePrimary,
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
            const _SectionDivider(),

            // ── CONTACTO (movido arriba — accion principal) ──────────
            _SectionContainer(
              accentColor: AppColors.bluePrimary,
              title: 'Contacto',
              child: (organization.hasDirectContact || organization.hasWebsite)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (organization.phone != null &&
                            organization.phone!.isNotEmpty)
                          _ContactItem(
                            accentColor: AppColors.greenSuccess,
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
            const _SectionDivider(),

            // ── CAMPAÑAS ACTIVAS (FutureBuilder, conditional) ─────────
            _OrgCampaignsSection(orgName: organization.name),

            // ── UBICACION ─────────────────────────────────────────────
            if (organization.hasAddress) ...[
              const _SectionDivider(),
              _SectionContainer(
                accentColor: AppColors.orangeAction,
                title: 'Ubicación',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.orangeAction.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.orangeAction.withValues(alpha: 0.18),
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        organization.address!,
                        style: TextStyle(
                          color: AppColors.darkText.withValues(alpha: 0.85),
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final encoded = Uri.encodeComponent(
                              organization.address!);
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$encoded',
                          );
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.orangeAction,
                          side: BorderSide(
                            color: AppColors.orangeAction
                                .withValues(alpha: 0.40),
                            width: 1.4,
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
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
              const _SectionDivider(),
              _SectionContainer(
                accentColor: AppColors.greenSuccess,
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
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        galleryUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.darkText.withValues(alpha: 0.05),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color:
                                  AppColors.darkText.withValues(alpha: 0.3),
                              size: 28,
                            ),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color:
                                AppColors.darkText.withValues(alpha: 0.05),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.bluePrimary),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
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
    required this.label,
    required this.color,
  });

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

// Item de contacto sin iconos: label + valor + CTA solido
class _ContactItem extends StatelessWidget {
  final Color accentColor;
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback? onTap;

  const _ContactItem({
    required this.accentColor,
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
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: accentColor,
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
              const SizedBox(width: 12),
              // CTA solido (sin icono ni flecha)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
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

        return Column(
          children: [
            const _SectionDivider(),
            _SectionContainer(
              accentColor: AppColors.bluePrimary,
              title: 'Campañas activas',
              trailingBadge: '${campaigns.length}',
              child: Column(
                children: [
                  for (var i = 0; i < campaigns.take(5).length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: i == campaigns.take(5).length - 1 ? 0 : 10),
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

/// Container blanco con padding ajustado y header de seccion (barra accent
/// + titulo + badge opcional). Reemplaza los Container+Column repetidos.
class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.accentColor,
    required this.title,
    required this.child,
    this.trailingBadge,
  });

  final Color accentColor;
  final String title;
  final String? trailingBadge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trailingBadge!,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Divider hairline 1px entre secciones (en lugar de SizedBox vacio).
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.darkText.withValues(alpha: 0.06),
    );
  }
}
