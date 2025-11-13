import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/kermesse_controller.dart';
import '../../models/kermesse.dart';
import '../../theme/app_colors.dart';

class KermesseListPage extends StatefulWidget {
  const KermesseListPage({super.key, required this.controller});

  final KermesseController controller;

  @override
  State<KermesseListPage> createState() => _KermesseListPageState();
}

class _KermesseListPageState extends State<KermesseListPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.hasLoaded) {
      widget.controller.loadKermesses();
    }
  }

  Future<void> _handleRefresh() => widget.controller.refreshKermesses();

  void _openDetail(KermesseSummary kermesse) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KermesseDetailPage(kermesse: kermesse),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kermesses solidarias')),
      backgroundColor: AppColors.lightBackground,
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          if (controller.isLoading && controller.kermesses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null && controller.kermesses.isEmpty) {
            return _KermesseErrorState(
              message: controller.errorMessage!,
              onRetry: controller.refreshKermesses,
            );
          }

          if (controller.kermesses.isEmpty) {
            return const _EmptyKermesses();
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: controller.kermesses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final kermesse = controller.kermesses[index];
                return _KermesseCard(
                  kermesse: kermesse,
                  onTap: () => _openDetail(kermesse),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _KermesseCard extends StatelessWidget {
  const _KermesseCard({required this.kermesse, required this.onTap});

  final KermesseSummary kermesse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.bluePrimary, AppColors.orangeAction],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.festival_outlined, size: 34, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(height: 10),
                    Text(
                      kermesse.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (kermesse.eventDateText != null || kermesse.locationName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kermesse.eventDateText != null)
                        _KermesseMetaRow(
                          icon: Icons.event_outlined,
                          value: kermesse.eventDateText!,
                        ),
                      if (kermesse.locationName != null)
                        _KermesseMetaRow(
                          icon: Icons.place_outlined,
                          value: kermesse.locationName!,
                        ),
                    ],
                  ),
                ),
              if (kermesse.shortDescription.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  kermesse.shortDescription,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.visibility_outlined, size: 18, color: AppColors.bluePrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Ver detalles',
                    style: theme.textTheme.labelLarge?.copyWith(color: AppColors.bluePrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KermesseMetaRow extends StatelessWidget {
  const _KermesseMetaRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.bluePrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}


class _EmptyKermesses extends StatelessWidget {
  const _EmptyKermesses();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: AppColors.grayNeutral),
          const SizedBox(height: 18),
          Text(
            'Aún no hay kermesses aprobadas.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando los organizadores registren sus eventos y el equipo los apruebe, aparecerán aquí para que puedas sumarte.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkText.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _KermesseErrorState extends StatelessWidget {
  const _KermesseErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 56, color: AppColors.orangeAction),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              onRetry();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class KermesseDetailPage extends StatelessWidget {
  const KermesseDetailPage({super.key, required this.kermesse});

  final KermesseSummary kermesse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapPoint = _resolveMapPoint(kermesse);
    final hasLocationSection = mapPoint != null ||
        kermesse.locationName != null ||
        kermesse.address != null;
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: AppColors.lightBackground,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
              title: SizedBox(
                width: double.infinity,
                child: Text(
                  kermesse.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              background: const _HeaderGradientBanner(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetadataChips(kermesse: kermesse),
                  const SizedBox(height: 18),
                  if (kermesse.overview.isNotEmpty)
                    _SectionCard(
                      icon: Icons.info_outline,
                      title: 'Resumen del evento',
                      child: Text(
                        kermesse.overview,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.8),
                          height: 1.45,
                        ),
                      ),
                    ),
                  if (kermesse.galleryImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.photo_library_outlined,
                      title: 'Galería del evento',
                      child: _KermesseGallery(images: kermesse.galleryImages),
                    ),
                  ],
                  if (hasLocationSection) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.place_outlined,
                      title: 'Ubicación y logística',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mapPoint != null) ...[
                            _KermesseMap(point: mapPoint),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => _openExternalMap(
                                  mapPoint,
                                  kermesse.locationName ?? kermesse.address,
                                ),
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Abrir en mapa'),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (kermesse.locationName != null)
                            _DetailRow(label: 'Lugar', value: kermesse.locationName!),
                          if (kermesse.address != null)
                            _DetailRow(label: 'Dirección de referencia', value: kermesse.address!),
                          if (mapPoint == null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'El organizador no compartió las coordenadas exactas, pero puedes contactar para más detalles.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.darkText.withValues(alpha: 0.7),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (kermesse.goalDescription != null || kermesse.beneficiaries != null)
                    ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        icon: Icons.groups_outlined,
                        title: 'Impacto solidario',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (kermesse.beneficiaries != null)
                              _DetailRow(label: 'Beneficiarios', value: kermesse.beneficiaries!),
                            if (kermesse.goalDescription != null)
                              _DetailRow(label: 'Uso de fondos', value: kermesse.goalDescription!),
                            if (kermesse.partners != null)
                              _DetailRow(label: 'Aliados confirmados', value: kermesse.partners!),
                          ],
                        ),
                      ),
                    ],
                  if (kermesse.menuItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ListSection(
                      icon: Icons.restaurant_menu,
                      title: 'Menú solidario',
                      items: kermesse.menuItems,
                    ),
                  ],
                  if (kermesse.activities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ListSection(
                      icon: Icons.celebration_outlined,
                      title: 'Actividades confirmadas',
                      items: kermesse.activities,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static LatLng? _resolveMapPoint(KermesseSummary kermesse) {
    final geo = kermesse.geoPoint;
    if (geo == null) {
      return null;
    }
    return LatLng(geo.latitude, geo.longitude);
  }

  static Future<void> _openExternalMap(LatLng point, String? label) async {
    final cleanedLabel = label?.trim();
    final fallbackName = cleanedLabel != null && cleanedLabel.isNotEmpty
        ? cleanedLabel
        : 'Kermesse solidaria';

    final geoUri = Uri.parse(
      'geo:${point.latitude},${point.longitude}?q=${point.latitude},${point.longitude}(${Uri.encodeComponent(fallbackName)})',
    );

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }

    final webUri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': '${point.latitude},${point.longitude} ($fallbackName)',
      },
    );

    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

class _HeaderGradientBanner extends StatelessWidget {
  const _HeaderGradientBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bluePrimary, AppColors.orangeAction],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.festival_outlined, size: 64, color: Colors.white70),
        ],
      ),
    );
  }
}

class _MetadataChips extends StatelessWidget {
  const _MetadataChips({required this.kermesse});

  final KermesseSummary kermesse;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (kermesse.eventDateText != null) {
      chips.add(_InfoChip(icon: Icons.event_outlined, label: kermesse.eventDateText!));
    }
    if (kermesse.locationName != null) {
      chips.add(_InfoChip(icon: Icons.place_outlined, label: kermesse.locationName!));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppColors.bluePrimary),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.bluePrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
      backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.12),
      side: BorderSide(color: AppColors.bluePrimary.withValues(alpha: 0.25)),
      shape: const StadiumBorder(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppColors.bluePrimary),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KermesseGallery extends StatelessWidget {
  const _KermesseGallery({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final url = images[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.grayNeutral.withValues(alpha: 0.2),
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.grayNeutral),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KermesseMap extends StatelessWidget {
  const _KermesseMap({required this.point});

  final LatLng point;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
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
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.place, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkText.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkText.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      icon: icon,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18, color: AppColors.greenHope),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.78),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
