import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/kermesse_controller.dart';
import '../../models/kermesse.dart';
import '../../services/kermesse_map_launcher.dart';
import '../../services/location_geocoder.dart';
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
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.darkText,
        title: const Text(
          'Kermesses solidarias',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: AnimatedBuilder(
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
            return const _EmptyKermesses();
          }

          return RefreshIndicator(
            color: AppColors.bluePrimary,
            onRefresh: _handleRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: controller.kermesses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final kermesse = controller.kermesses[index];
                return _KermesseFeatureCard(
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
            children: [
              HomeSection(
                title: 'Evento destacado',
                subtitle: 'El próximo evento solidario más cercano.',
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
                  iconColor: AppColors.bluePrimary,
                  child: Column(
                    children: rest
                        .map(
                          (k) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _KermesseFeatureCard(
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (kermesse.hasCover)
                        Image.network(
                          kermesse.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _KermessePlaceholder(id: kermesse.id),
                        )
                      else
                        _KermessePlaceholder(id: kermesse.id),
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
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
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
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_activity_rounded,
                                size: 11,
                                color: AppColors.orangeAction,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Kermesse',
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _EventStatsRow(
                    eventDateText: kermesse.eventDateText,
                    locationName: kermesse.locationName,
                  ),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ver detalles',
                      style: TextStyle(
                        color: AppColors.bluePrimary.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.bluePrimary.withValues(alpha: 0.85),
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

class _EventStatsRow extends StatelessWidget {
  const _EventStatsRow({this.eventDateText, this.locationName});

  final String? eventDateText;
  final String? locationName;

  @override
  Widget build(BuildContext context) {
    final hasDate = eventDateText != null && eventDateText!.trim().isNotEmpty;
    final hasLocation =
        locationName != null && locationName!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDate)
          Expanded(
            child: _EventStatItem(
              icon: Icons.calendar_today_rounded,
              label: eventDateText!,
            ),
          ),
        if (hasDate && hasLocation) const SizedBox(width: 12),
        if (hasLocation)
          Expanded(
            child: _EventStatItem(
              icon: Icons.location_on_rounded,
              label: locationName!,
            ),
          ),
      ],
    );
  }
}

class _EventStatItem extends StatelessWidget {
  const _EventStatItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: AppColors.orangeAction),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: AppColors.darkText.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Branded placeholder shown when a kermesse has no cover image.
/// Uses a deterministic gradient derived from the event [id] so every
/// card looks distinct even without a real photo.
class _KermessePlaceholder extends StatelessWidget {
  const _KermessePlaceholder({required this.id});

  final String id;

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
          size: 56,
        ),
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
          padding: const EdgeInsets.all(28),
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.orangeAction.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_activity_rounded,
                  color: AppColors.orangeAction,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sin eventos por ahora',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                  letterSpacing: -0.4,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cuando los organizadores registren sus kermeses y el equipo las apruebe, aparecerán aquí para que puedas participar.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkText.withValues(alpha: 0.65),
                ),
              ),
              if (onCreate != null) ...[
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangeAction,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Registrar una kermesse',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}


class KermesseDetailPage extends StatelessWidget {
  const KermesseDetailPage({super.key, required this.kermesse});

  final KermesseSummary kermesse;

  static final RegExp _emojiRegExp = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2300}-\u{23FF}\u{2900}-\u{297F}\u{1F000}-\u{1F2FF}\u{FE00}-\u{FE0F}\u{200D}]',
    unicode: true,
  );

  String _stripEmojis(String s) {
    return s
        .replaceAll(_emojiRegExp, '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final mapPoint = _resolveMapPoint(kermesse);
    final hasLocationSection = mapPoint != null ||
        kermesse.locationName != null ||
        kermesse.address != null;
    final cleanOverview = _stripEmojis(kermesse.overview);

    final hasEssentialInfo = kermesse.locationName != null ||
        kermesse.eventDateText != null ||
        kermesse.goalDescription != null;

    final sections = <Widget>[
      if (hasEssentialInfo)
        _DetailSection(
          eyebrow: 'Info esencial',
          title: 'Lo importante en un vistazo',
          accentColor: AppColors.orangeAction,
          child: _EssentialInfoBlock(
            locationName: kermesse.locationName,
            address: kermesse.address,
            eventDateText: kermesse.eventDateText,
            goalDescription: kermesse.goalDescription,
          ),
        ),
      if (cleanOverview.isNotEmpty)
        _DetailSection(
          eyebrow: 'Sobre el evento',
          title: 'Qué vas a encontrar',
          child: _OrganizerQuote(narrative: cleanOverview),
        ),
      if (kermesse.galleryImages.isNotEmpty)
        _DetailSection(
          eyebrow: 'Galería',
          title: 'Fotos del evento',
          counter:
              '${kermesse.galleryImages.length} ${kermesse.galleryImages.length == 1 ? 'foto' : 'fotos'}',
          child: _KermesseGallery(images: kermesse.galleryImages),
        ),
      if (hasLocationSection)
        _DetailSection(
          eyebrow: 'Ubicación',
          title: 'Punto de encuentro',
          child: _LocationBlock(
            initialMapPoint: mapPoint,
            locationName: kermesse.locationName,
            address: kermesse.address,
            onOpenMap: (resolvedPoint) async {
              await kermesseMapLauncher.open(
                point: mapPoint ?? resolvedPoint,
                query: kermesse.locationName ?? kermesse.address,
                label: kermesse.locationName ?? kermesse.address,
              );
            },
          ),
        ),
      if (kermesse.beneficiaries != null || kermesse.partners != null)
        _DetailSection(
          eyebrow: 'Impacto',
          title: 'A quién ayuda esta kermesse',
          accentColor: AppColors.greenHope,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kermesse.beneficiaries != null)
                _DetailRow(
                    label: 'Beneficiarios', value: kermesse.beneficiaries!),
              if (kermesse.partners != null)
                _DetailRow(
                    label: 'Aliados confirmados',
                    value: kermesse.partners!),
            ],
          ),
        ),
      if (kermesse.menuItems.isNotEmpty)
        _DetailSection(
          eyebrow: 'Menú',
          title: 'Lo que vas a encontrar',
          counter:
              '${kermesse.menuItems.length} ${kermesse.menuItems.length == 1 ? 'plato' : 'platos'}',
          accentColor: AppColors.orangeAction,
          child: _PricedList(items: kermesse.menuItems),
        ),
      if (kermesse.musicItems.isNotEmpty)
        _DetailSection(
          eyebrow: 'Música',
          title: 'Programa musical',
          counter:
              '${kermesse.musicItems.length} ${kermesse.musicItems.length == 1 ? 'show' : 'shows'}',
          accentColor: AppColors.bluePrimary,
          child: _MusicList(items: kermesse.musicItems),
        ),
      if (kermesse.activities.isNotEmpty)
        _DetailSection(
          eyebrow: 'Actividades',
          title: 'Programa del evento',
          counter: '${kermesse.activities.length} en agenda',
          accentColor: AppColors.orangeAction,
          child: _CheckList(items: kermesse.activities),
        ),
      if (kermesse.closingMessage != null &&
          kermesse.closingMessage!.isNotEmpty)
        _ClosingMessageCard(message: kermesse.closingMessage!),
    ];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _DetailHeroBanner(kermesse: kermesse, height: 280),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 12,
                    child: _HeroBackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: -36,
                    child: _KermesseHeroStats(kermesse: kermesse),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              ...sections
                  .expand((s) => [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: s,
                        ),
                        const SizedBox(height: 16),
                      ])
                  .toList()
                  .animate(interval: 60.ms)
                  .fade(duration: 380.ms)
                  .slideY(
                      begin: 0.04,
                      duration: 380.ms,
                      curve: Curves.easeOutQuad),
            ],
          ),
        ),
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
}

class _DetailHeroBanner extends StatelessWidget {
  const _DetailHeroBanner({required this.kermesse, required this.height});

  final KermesseSummary kermesse;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (kermesse.hasCover)
            Image.network(
              kermesse.coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _KermessePlaceholder(id: kermesse.id),
            )
          else
            _KermessePlaceholder(id: kermesse.id),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xE6000000)],
                stops: [0.30, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'KERMESSE SOLIDARIA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kermesse.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.2,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackButton extends StatelessWidget {
  const _HeroBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _KermesseHeroStats extends StatelessWidget {
  const _KermesseHeroStats({required this.kermesse});

  final KermesseSummary kermesse;

  static const Map<String, ({int num, String abbrev})> _months = {
    'enero': (num: 1, abbrev: 'ENE'),
    'febrero': (num: 2, abbrev: 'FEB'),
    'marzo': (num: 3, abbrev: 'MAR'),
    'abril': (num: 4, abbrev: 'ABR'),
    'mayo': (num: 5, abbrev: 'MAY'),
    'junio': (num: 6, abbrev: 'JUN'),
    'julio': (num: 7, abbrev: 'JUL'),
    'agosto': (num: 8, abbrev: 'AGO'),
    'septiembre': (num: 9, abbrev: 'SEP'),
    'setiembre': (num: 9, abbrev: 'SEP'),
    'octubre': (num: 10, abbrev: 'OCT'),
    'noviembre': (num: 11, abbrev: 'NOV'),
    'diciembre': (num: 12, abbrev: 'DIC'),
  };

  static const List<String> _monthAbbrevs = [
    '', 'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];

  ({int? day, String? monthAbbrev, DateTime? date}) _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return (day: null, monthAbbrev: null, date: null);
    }
    final lower = raw.toLowerCase();

    for (final entry in _months.entries) {
      final regex =
          RegExp(r'(\d{1,2})\s+(?:de\s+)?' + entry.key, caseSensitive: false);
      final match = regex.firstMatch(lower);
      if (match != null) {
        final day = int.tryParse(match.group(1)!);
        if (day == null || day < 1 || day > 31) continue;
        final monthNum = entry.value.num;
        final now = DateTime.now();
        var year = now.year;
        var attempt = DateTime(year, monthNum, day);
        if (attempt.isBefore(DateTime(now.year, now.month, now.day))) {
          year++;
          attempt = DateTime(year, monthNum, day);
        }
        return (day: day, monthAbbrev: entry.value.abbrev, date: attempt);
      }
    }

    final numeric = RegExp(r'(\d{1,2})[\/\-](\d{1,2})(?:[\/\-](\d{2,4}))?')
        .firstMatch(raw);
    if (numeric != null) {
      final day = int.tryParse(numeric.group(1)!);
      final monthNum = int.tryParse(numeric.group(2)!);
      if (day != null &&
          monthNum != null &&
          day >= 1 &&
          day <= 31 &&
          monthNum >= 1 &&
          monthNum <= 12) {
        int year;
        final yearStr = numeric.group(3);
        if (yearStr != null) {
          year = int.parse(yearStr);
          if (year < 100) year += 2000;
        } else {
          final now = DateTime.now();
          year = now.year;
          if (DateTime(year, monthNum, day)
              .isBefore(DateTime(now.year, now.month, now.day))) {
            year++;
          }
        }
        return (
          day: day,
          monthAbbrev: _monthAbbrevs[monthNum],
          date: DateTime(year, monthNum, day),
        );
      }
    }

    return (day: null, monthAbbrev: null, date: null);
  }

  ({String label, Color color}) _countdown(DateTime? date) {
    if (date == null) {
      return (label: 'PRÓXIMO EVENTO', color: AppColors.orangeAction);
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final diff = eventDay.difference(today).inDays;
    if (diff < 0) {
      return (
        label: 'FINALIZADA',
        color: AppColors.darkText.withValues(alpha: 0.5),
      );
    }
    if (diff == 0) return (label: 'HOY', color: AppColors.greenHope);
    if (diff == 1) return (label: 'MAÑANA', color: AppColors.orangeAction);
    if (diff <= 7) {
      return (label: 'EN $diff DÍAS', color: AppColors.orangeAction);
    }
    return (label: 'EN $diff DÍAS', color: AppColors.bluePrimary);
  }

  /// Extrae día de semana + horario del raw eventDateText.
  /// Si hasDateBlock=true, NO devuelve el texto completo (para evitar duplicar
  /// el día/mes que ya están en el date block visual a la izquierda).
  String? _extractWeekdayTime(String? raw, {required bool hasDateBlock}) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.toLowerCase();

    const weekdayMap = {
      'lunes': 'Lunes',
      'martes': 'Martes',
      'miércoles': 'Miércoles',
      'miercoles': 'Miércoles',
      'jueves': 'Jueves',
      'viernes': 'Viernes',
      'sábado': 'Sábado',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };
    String? weekday;
    for (final entry in weekdayMap.entries) {
      if (lower.contains(entry.key)) {
        weekday = entry.value;
        break;
      }
    }

    final timeMatch = RegExp(
      r'(\d{1,2}:\d{2}(?:\s*(?:am|pm|hs|h))?(?:\s*-\s*\d{1,2}:\d{2}(?:\s*(?:am|pm|hs|h))?)?)',
      caseSensitive: false,
    ).firstMatch(raw);
    final time = timeMatch?.group(1)?.trim();

    if (hasDateBlock) {
      if (weekday != null && time != null) return '$weekday · $time';
      if (weekday != null) return weekday;
      if (time != null) return time;
      return null;
    }

    if (weekday != null && time != null) return '$weekday · $time';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseDate(kermesse.eventDateText);
    final countdown = _countdown(parsed.date);
    final hasDateBlock = parsed.day != null && parsed.monthAbbrev != null;
    final dateDetail = _extractWeekdayTime(
      kermesse.eventDateText,
      hasDateBlock: hasDateBlock,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasDateBlock)
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.orangeAction.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      parsed.day.toString(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                        height: 1.0,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      parsed.monthAbbrev!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orangeAction,
                        letterSpacing: 1.2,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.orangeAction.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: AppColors.orangeAction,
                  size: 28,
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: countdown.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      countdown.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: countdown.color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (dateDetail != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      dateDetail,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                  if (kermesse.locationName != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      kermesse.locationName!,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkText.withValues(alpha: 0.6),
                        height: 1.3,
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
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.counter,
    this.accentColor,
  });

  final String eyebrow;
  final String title;
  final String? counter;
  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.bluePrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              eyebrow.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: accent,
                              ),
                            ),
                          ),
                          if (counter != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                counter!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                          letterSpacing: -0.4,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: AppColors.darkText.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 20),
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

class _PricedList extends StatelessWidget {
  const _PricedList({required this.items});

  final List<String> items;

  ({String name, String? price}) _parse(String raw) {
    final lastColon = raw.lastIndexOf(':');
    if (lastColon == -1 || lastColon == raw.length - 1) {
      return (name: raw.trim(), price: null);
    }
    final afterColon = raw.substring(lastColon + 1).trim();
    final match = RegExp(r'^Bs\.?\s*([0-9][0-9.,]*)\s*$',
            caseSensitive: false)
        .firstMatch(afterColon);
    if (match == null) {
      return (name: raw.trim(), price: null);
    }
    final amount = match.group(1)!;
    final name = raw.substring(0, lastColon).trim();
    return (name: name, price: 'Bs $amount');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((raw) {
        final parsed = _parse(raw);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
                  parsed.name,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.darkText.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (parsed.price != null) ...[
                const SizedBox(width: 12),
                Text(
                  parsed.price!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.orangeAction,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EssentialInfoBlock extends StatelessWidget {
  const _EssentialInfoBlock({
    this.locationName,
    this.eventDateText,
    this.goalDescription,
    this.address,
  });

  final String? locationName;
  final String? eventDateText;
  final String? goalDescription;
  final String? address;

  String? get _mapQuery {
    final candidate = locationName ?? address;
    final trimmed = candidate?.trim();
    return (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  Future<void> _openMap() async {
    final query = _mapQuery;
    if (query == null) return;
    await kermesseMapLauncher.open(query: query, label: query);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = locationName != null && locationName!.trim().isNotEmpty;
    final hasDate = eventDateText != null && eventDateText!.trim().isNotEmpty;
    final hasGoal =
        goalDescription != null && goalDescription!.trim().isNotEmpty;
    final canOpenMap = _mapQuery != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLocation)
          _EssentialInfoRow(
            icon: Icons.location_on_rounded,
            label: 'Lugar',
            value: locationName!,
            onTap: canOpenMap ? _openMap : null,
          ),
        if (hasDate) ...[
          if (hasLocation) const SizedBox(height: 14),
          _EssentialInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Fecha y horario',
            value: eventDateText!,
          ),
        ],
        if (hasGoal) ...[
          if (hasLocation || hasDate) const SizedBox(height: 14),
          _EssentialInfoRow(
            icon: Icons.flag_rounded,
            label: 'Objetivo',
            value: goalDescription!,
          ),
        ],
      ],
    );
  }
}

class _EssentialInfoRow extends StatelessWidget {
  const _EssentialInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.orangeAction.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: AppColors.orangeAction),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orangeAction,
                      letterSpacing: 0.6,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 12,
                      color: AppColors.orangeAction.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                softWrap: true,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: content,
        ),
      ),
    );
  }
}

class _MusicList extends StatelessWidget {
  const _MusicList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      size: 13,
                      color: AppColors.bluePrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.darkText.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
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

class _ClosingMessageCard extends StatelessWidget {
  const _ClosingMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.orangeAction.withValues(alpha: 0.10),
            AppColors.orangeAction.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: AppColors.orangeAction.withValues(alpha: 0.30),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.orangeAction,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.orangeAction.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MENSAJE DEL ORGANIZADOR',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orangeAction.withValues(alpha: 0.9),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText.withValues(alpha: 0.88),
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

class _LocationBlock extends StatefulWidget {
  const _LocationBlock({
    this.initialMapPoint,
    this.locationName,
    this.address,
    required this.onOpenMap,
  });

  final LatLng? initialMapPoint;
  final String? locationName;
  final String? address;
  final Future<void> Function(LatLng? resolvedPoint) onOpenMap;

  @override
  State<_LocationBlock> createState() => _LocationBlockState();
}

class _LocationBlockState extends State<_LocationBlock> {
  LatLng? _resolved;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _resolved = widget.initialMapPoint;
    if (_resolved == null) {
      final query = (widget.locationName ?? widget.address ?? '').trim();
      if (query.isNotEmpty) {
        _isLoading = true;
        kermesseLocationGeocoder.geocode(query).then((result) {
          if (!mounted) return;
          setState(() {
            _resolved = result;
            _isLoading = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasName =
        widget.locationName != null && widget.locationName!.trim().isNotEmpty;
    final hasAddress =
        widget.address != null && widget.address!.trim().isNotEmpty;
    final point = _resolved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (point != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: _KermesseMap(point: point),
            ),
          )
        else if (_isLoading)
          const _MapSkeleton()
        else if (hasName || hasAddress)
          const _MapUnavailableHint(),
        if (point != null || _isLoading || hasName || hasAddress)
          const SizedBox(height: 14),
        if (hasName)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.place_rounded,
                  size: 18,
                  color: AppColors.orangeAction,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.locationName!,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        if (hasAddress) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              widget.address!,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.darkText.withValues(alpha: 0.62),
              ),
            ),
          ),
        ],
        if (hasName || hasAddress || point != null) ...[
          const SizedBox(height: 16),
          _MapPrimaryButton(
            label: 'Cómo llegar',
            icon: Icons.directions_rounded,
            onTap: () => widget.onOpenMap(_resolved),
          ),
        ],
        if (!hasName && !hasAddress && point == null && !_isLoading)
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
    );
  }
}

class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 170,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bluePrimary.withValues(alpha: 0.08),
              AppColors.bluePrimary.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.bluePrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Buscando ubicación...',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapUnavailableHint extends StatelessWidget {
  const _MapUnavailableHint();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          border: Border.all(
            color: AppColors.darkText.withValues(alpha: 0.06),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 28,
                color: AppColors.darkText.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 6),
              Text(
                'Vista previa no disponible',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPrimaryButton extends StatefulWidget {
  const _MapPrimaryButton({
    required this.onTap,
    this.label = 'Cómo llegar',
    this.icon = Icons.directions_rounded,
  });

  final Future<void> Function() onTap;
  final String label;
  final IconData icon;

  @override
  State<_MapPrimaryButton> createState() => _MapPrimaryButtonState();
}

class _MapPrimaryButtonState extends State<_MapPrimaryButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.actionGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.orangeAction.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onTap();
              },
              icon: Icon(widget.icon, size: 18),
              label: Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrganizerQuote extends StatelessWidget {
  const _OrganizerQuote({required this.narrative});

  final String narrative;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '❝',
          style: TextStyle(
            fontSize: 38,
            height: 1.0,
            fontWeight: FontWeight.w800,
            color: AppColors.orangeAction.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Text(
            narrative,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: AppColors.darkText.withValues(alpha: 0.82),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            '— Equipo organizador',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.orangeAction.withValues(alpha: 0.85),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}
