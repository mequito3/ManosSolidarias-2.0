import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/kermesse_controller.dart';
import '../../models/kermesse.dart';
import '../../theme/app_colors.dart';
import '../home/menu_inferior/shared_states.dart';
import '../home/widgets/home_section.dart';

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
// ─────────────────────────────────────────────────────────────────────────────
// KermesseTabView — Scaffold-free version for embedding in NavigationBar tabs
// ─────────────────────────────────────────────────────────────────────────────

class KermesseTabView extends StatefulWidget {
  const KermesseTabView({
    super.key,
    required this.controller,
    this.onCreateKermesse,
  });

  final KermesseController controller;
  final VoidCallback? onCreateKermesse;

  @override
  State<KermesseTabView> createState() => _KermesseTabViewState();
}

class _KermesseTabViewState extends State<KermesseTabView> {
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
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        if (controller.isLoading && controller.kermesses.isEmpty) {
          return const HomeTabLoadingState();
        }

        if (controller.errorMessage != null && controller.kermesses.isEmpty) {
          return HomeTabErrorState(
            message: controller.errorMessage!,
            onRetry: controller.refreshKermesses,
          );
        }

        if (controller.kermesses.isEmpty) {
          return _EmptyKermesses(onCreate: widget.onCreateKermesse);
        }

        final featured = controller.kermesses.first;
        final rest = controller.kermesses.skip(1).toList();

        return RefreshIndicator(
          color: AppColors.bluePrimary,
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              HomeSection(
                title: 'Evento destacado',
                subtitle: 'El próximo evento solidario más cercano.',
                icon: Icons.local_activity_rounded,
                iconColor: AppColors.orangeAction,
                child: _KermesseFeatureCard(
                  kermesse: featured,
                  onTap: () => _openDetail(featured),
                ),
              ),
              if (rest.isNotEmpty)
                HomeSection(
                  title: 'Más eventos',
                  subtitle: 'Todos los eventos solidarios activos en tu comunidad.',
                  icon: Icons.grid_view_rounded,
                  iconColor: AppColors.grayNeutral,
                  child: Column(
                    children: rest
                        .map(
                          (k) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _KermesseCompactCard(
                              kermesse: k,
                              onTap: () => _openDetail(k),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
                    Icon(Icons.local_activity_rounded, size: 34, color: Colors.white.withValues(alpha: 0.9)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab-view widgets (KermesseTabView exclusive)
// ─────────────────────────────────────────────────────────────────────────────

class _KermesseFeatureCard extends StatelessWidget {
  const _KermesseFeatureCard({required this.kermesse, required this.onTap});

  final KermesseSummary kermesse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── Hero image (or branded fallback) ──────────────────
                      if (kermesse.hasCover)
                        Image.network(
                          kermesse.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _KermessePlaceholder(id: kermesse.id),
                        )
                      else
                        _KermessePlaceholder(id: kermesse.id),
                      // ── Bottom-to-top dark scrim for text legibility ──────
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        top: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xCC000000)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.93),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 6),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sell_rounded,
                                  size: 11, color: AppColors.orangeAction),
                              SizedBox(width: 4),
                              Text(
                                'Kermese solidaria',
                                style: TextStyle(
                                  color: AppColors.orangeAction,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Text(
                          kermesse.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            height: 1.25,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (kermesse.shortDescription.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
                  child: Text(
                    kermesse.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.darkText.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              if (kermesse.eventDateText != null ||
                  kermesse.locationName != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kermesse.eventDateText != null)
                        _TabMetaRow(
                          icon: Icons.event_outlined,
                          label: kermesse.eventDateText!,
                        ),
                      if (kermesse.locationName != null)
                        _TabMetaRow(
                          icon: Icons.place_outlined,
                          label: kermesse.locationName!,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _KermesseCompactCard extends StatelessWidget {
  const _KermesseCompactCard({required this.kermesse, required this.onTap});

  final KermesseSummary kermesse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.dividerColor.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: kermesse.hasCover
                      ? Image.network(
                          kermesse.coverUrl!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder: (_, __, ___) => _KermessePlaceholder(
                              id: kermesse.id, small: true),
                        )
                      : _KermessePlaceholder(id: kermesse.id, small: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppColors.orangeAction.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            '🎪 Evento',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orangeAction,
                            ),
                          ),
                        ),
                        if (kermesse.eventDateText != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              kermesse.eventDateText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    AppColors.darkText.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      kermesse.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.darkText,
                        height: 1.3,
                      ),
                    ),
                    if (kermesse.locationName != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 11,
                              color:
                                  AppColors.darkText.withValues(alpha: 0.45)),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              kermesse.locationName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.darkText
                                    .withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.darkText.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Branded placeholder shown when a kermesse has no cover image.
/// Uses a deterministic gradient derived from the event [id] so every
/// card looks distinct even without a real photo.
class _KermessePlaceholder extends StatelessWidget {
  const _KermessePlaceholder({required this.id, this.small = false});

  final String id;
  final bool small;

  static const List<List<Color>> _palettes = [
    [Color(0xFFFF8C42), Color(0xFFB04000)],
    [Color(0xFFE85D04), Color(0xFF9D0208)],
    [Color(0xFFF48C06), Color(0xFFAE2012)],
    [Color(0xFF0096C7), Color(0xFF023E8A)],
    [Color(0xFF2D6A4F), Color(0xFF1B4332)],
    [Color(0xFF7B2D8B), Color(0xFF3D0066)],
    [Color(0xFFD62828), Color(0xFF7A0000)],
    [Color(0xFFE9C46A), Color(0xFFF4A261)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = id.codeUnits.fold(0, (a, b) => a + b) % _palettes.length;
    final colors = _palettes[idx];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_activity_rounded,
          color: Colors.white.withValues(alpha: 0.55),
          size: small ? 26 : 64,
        ),
      ),
    );
  }
}

class _TabMetaRow extends StatelessWidget {
  const _TabMetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.orangeAction),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.darkText.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyKermesses extends StatelessWidget {
  const _EmptyKermesses({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
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
              const Icon(
                Icons.local_activity_rounded,
                color: AppColors.orangeAction,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                'Sin eventos por ahora',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cuando los organizadores registren sus kermeses y el equipo las apruebe, aparecerán aquí para que puedas participar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.7),
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
      ],
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
            expandedHeight: 220,
            backgroundColor: AppColors.orangeAction,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _DetailHeroBanner(kermesse: kermesse),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KermesseMetaPills(kermesse: kermesse),
                  if (kermesse.overview.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _DetailSection(
                      icon: Icons.info_outline_rounded,
                      title: 'Resumen del evento',
                      child: Text(
                        kermesse.overview,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: AppColors.darkText.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                  ],
                  if (kermesse.galleryImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      icon: Icons.photo_library_outlined,
                      title: 'Galería del evento',
                      child: _KermesseGallery(images: kermesse.galleryImages),
                    ),
                  ],
                  if (hasLocationSection) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      icon: Icons.place_outlined,
                      title: 'Ubicación y logística',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mapPoint != null) ...[
                            _KermesseMap(point: mapPoint),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _openExternalMap(
                                mapPoint,
                                kermesse.locationName ?? kermesse.address,
                              ),
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: const Text('Abrir en mapa'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.orangeAction,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (kermesse.locationName != null)
                            _DetailRow(label: 'Lugar', value: kermesse.locationName!),
                          if (kermesse.address != null)
                            _DetailRow(
                                label: 'Dirección de referencia', value: kermesse.address!),
                          if (mapPoint == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'El organizador no compartió coordenadas exactas. Contáctalo para más detalles.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: AppColors.darkText.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (kermesse.goalDescription != null ||
                      kermesse.beneficiaries != null) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      icon: Icons.groups_outlined,
                      title: 'Impacto solidario',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (kermesse.beneficiaries != null)
                            _DetailRow(
                                label: 'Beneficiarios', value: kermesse.beneficiaries!),
                          if (kermesse.goalDescription != null)
                            _DetailRow(
                                label: 'Uso de fondos', value: kermesse.goalDescription!),
                          if (kermesse.partners != null)
                            _DetailRow(
                                label: 'Aliados confirmados', value: kermesse.partners!),
                        ],
                      ),
                    ),
                  ],
                  if (kermesse.menuItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Menú solidario',
                      child: _CheckList(items: kermesse.menuItems),
                    ),
                  ],
                  if (kermesse.activities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      icon: Icons.celebration_outlined,
                      title: 'Actividades confirmadas',
                      child: _CheckList(items: kermesse.activities),
                    ),
                  ],
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

class _DetailHeroBanner extends StatelessWidget {
  const _DetailHeroBanner({required this.kermesse});

  final KermesseSummary kermesse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background: real image or branded placeholder ──────────────
        if (kermesse.hasCover)
          Image.network(
            kermesse.coverUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _KermessePlaceholder(id: kermesse.id),
          )
        else
          _KermessePlaceholder(id: kermesse.id),
        // ── Full-height fade so text stays readable ────────────────────
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55000000), Color(0xDD000000)],
              stops: [0.0, 1.0],
            ),
          ),
        ),
        // ── Text content ───────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_activity_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  kermesse.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (kermesse.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    kermesse.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KermesseMetaPills extends StatelessWidget {
  const _KermesseMetaPills({required this.kermesse});

  final KermesseSummary kermesse;

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[];
    if (kermesse.eventDateText != null) {
      pills.add(_MetaPill(
        icon: Icons.event_outlined,
        label: kermesse.eventDateText!,
      ));
    }
    if (kermesse.locationName != null) {
      pills.add(_MetaPill(
        icon: Icons.place_outlined,
        label: kermesse.locationName!,
      ));
    }
    if (pills.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 10, runSpacing: 10, children: pills);
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.orangeAction),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
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
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.orangeAction.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.orangeAction),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.darkText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// _SectionCard alias kept for KermesseListPage (standalone) compatibility
typedef _SectionCard = _DetailSection;

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
                      color: AppColors.orangeAction,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orangeAction.withValues(alpha: 0.38),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                        Icons.local_activity_rounded, color: Colors.white, size: 22),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.orangeAction,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orangeAction,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.darkText.withValues(alpha: 0.8),
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

class _CheckList extends StatelessWidget {
  const _CheckList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.orangeAction.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.orangeAction,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.darkText.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
    return _SectionCard(
      icon: icon,
      title: title,
      child: _CheckList(items: items),
    );
  }
}
