part of 'campaign_detail_page.dart';

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({
    required this.evidences,
    required this.onEvidenceTap,
  });

  final List<CampaignEvidence> evidences;
  final Future<void> Function(CampaignEvidence evidence) onEvidenceTap;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Evidencias fotográficas',
      icon: Icons.photo_library_rounded,
      iconColor: AppColors.greenSuccess,
      child: evidences.isEmpty
          ? const _EvidenceEmptyView()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${evidences.length} ${evidences.length == 1 ? "foto validada por el equipo" : "fotos validadas por el equipo"}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                _EvidenceCarousel(
                  evidences: evidences,
                  onEvidenceTap: onEvidenceTap,
                ),
              ],
            ),
    );
  }
}

class _EvidenceImageCard extends StatelessWidget {
  const _EvidenceImageCard({
    required this.imageUrl,
    this.borderRadius = 18,
  });

  final String imageUrl;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.bluePrimary.withValues(alpha: 0.06),
            child: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.bluePrimary,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.darkText.withValues(alpha: 0.08),
          child: const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 32, color: AppColors.darkText),
          ),
        ),
      ),
    );
  }
}

/// Carrusel horizontal premium para evidencias.
/// PageView con peek effect (se ve parte de la siguiente foto).
/// Indicador de dots debajo + contador "1 / N" arriba.
/// Tap en una foto → abre el visor swipeable a pantalla completa.
class _EvidenceCarousel extends StatefulWidget {
  const _EvidenceCarousel({
    required this.evidences,
    required this.onEvidenceTap,
  });

  final List<CampaignEvidence> evidences;
  final Future<void> Function(CampaignEvidence evidence) onEvidenceTap;

  @override
  State<_EvidenceCarousel> createState() => _EvidenceCarouselState();
}

class _EvidenceCarouselState extends State<_EvidenceCarousel> {
  static const double _viewportFraction = 0.88;
  static const double _height = 240;

  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.evidences.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _height,
          child: PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            padEnds: false,
            itemCount: total,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final evidence = widget.evidences[index];
              final url = _resolveEvidencePreviewUrl(evidence);
              final isLast = index == total - 1;

              return Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 10),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => unawaited(widget.onEvidenceTap(evidence)),
                  child: url == null
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppColors.darkText.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                size: 32, color: AppColors.darkText),
                          ),
                        )
                      : Hero(
                          tag: 'campaign-evidence-${evidence.id}',
                          child: _EvidenceImageCard(
                            imageUrl: url,
                            borderRadius: 18,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
        if (total > 1) ...[
          const SizedBox(height: 14),
          _CarouselDots(
            total: total,
            currentIndex: _currentIndex,
          ),
        ],
      ],
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.total, required this.currentIndex});

  final int total;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.greenSuccess
                : AppColors.darkText.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _EvidenceEmptyView extends StatelessWidget {
  const _EvidenceEmptyView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.grayNeutral.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grayNeutral.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.grayNeutral.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_library_outlined,
                color: AppColors.grayNeutral, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            'Sin evidencias aún',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.darkText.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'El equipo organizador todavía no ha publicado archivos de seguimiento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.darkText.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

String? _resolveEvidencePreviewUrl(CampaignEvidence evidence) {
  final thumb = evidence.thumbnailUrl?.trim();
  if (thumb != null && thumb.isNotEmpty) {
    return thumb;
  }
  final url = evidence.url.trim();
  return url.isEmpty ? null : url;
}


class _EvidenceViewerPage extends StatefulWidget {
  const _EvidenceViewerPage({
    required this.evidences,
    required this.initialIndex,
  });

  final List<CampaignEvidence> evidences;
  final int initialIndex;

  @override
  State<_EvidenceViewerPage> createState() => _EvidenceViewerPageState();
}

class _EvidenceViewerPageState extends State<_EvidenceViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.evidences.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ),
          // PageView con swipe horizontal entre evidencias
          PageView.builder(
            controller: _pageController,
            itemCount: total,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final evidence = widget.evidences[index];
              return _EvidencePageContent(evidence: evidence);
            },
          ),

          // Barra superior: cerrar + contador
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _DarkActionButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      if (total > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / $total',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _EvidencePageContent extends StatelessWidget {
  const _EvidencePageContent({required this.evidence});

  final CampaignEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final previewUrl = _resolveEvidencePreviewUrl(evidence);
    final isImage = previewUrl != null &&
        (_isImageEvidenceType(evidence.type) || _looksLikeImageUrl(previewUrl));

    if (isImage) {
      return InteractiveViewer(
        minScale: 1.0,
        maxScale: 5.0,
        panEnabled: true,
        child: Center(
          child: Image.network(
            previewUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final value = progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null;
              return Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: value,
                    color: Colors.white70,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined,
                      size: 56, color: Colors.white38),
                  SizedBox(height: 12),
                  Text(
                    'No se pudo cargar la imagen',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Archivo no-imagen · vista compacta sin botón externo
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _evidenceIconForType(evidence.type),
                size: 30,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              evidence.type.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Archivo adjunto privado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkActionButton extends StatelessWidget {
  const _DarkActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
