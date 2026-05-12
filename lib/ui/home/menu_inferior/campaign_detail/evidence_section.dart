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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.greenSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.greenSuccess.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 12, color: AppColors.greenSuccess),
                          const SizedBox(width: 5),
                          Text(
                            '${evidences.length} archivo${evidences.length == 1 ? '' : 's'} validado${evidences.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenSuccess,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Toca para ver en detalle',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.darkText.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: evidences.length,
                  itemBuilder: (context, index) {
                    final evidence = evidences[index];
                    return _EvidenceTile(
                      evidence: evidence,
                      index: index + 1,
                      total: evidences.length,
                      onTap: onEvidenceTap,
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({
    required this.evidence,
    required this.index,
    required this.total,
    required this.onTap,
  });

  final CampaignEvidence evidence;
  final int index;
  final int total;
  final Future<void> Function(CampaignEvidence evidence) onTap;

  @override
  Widget build(BuildContext context) {
    final previewUrl = _resolveEvidencePreviewUrl(evidence);
    final bool isImage = previewUrl != null &&
        (_isImageEvidenceType(evidence.type) || _looksLikeImageUrl(previewUrl));
    final description = _normalizeEvidenceDescription(evidence.description);
    final heroTag = isImage ? 'campaign-evidence-${evidence.id}' : null;

    Widget content = isImage
        ? _EvidenceImageCard(
            imageUrl: previewUrl!,
            caption: description ?? 'Evidencia $index de $total',
            index: index,
          )
        : _EvidenceFileCard(
            caption: description ?? 'Archivo adjunto',
            type: evidence.type,
          );

    return GestureDetector(
      onTap: () => unawaited(onTap(evidence)),
      child: heroTag != null ? Hero(tag: heroTag, child: content) : content,
    );
  }
}

class _EvidenceImageCard extends StatelessWidget {
  const _EvidenceImageCard({
    required this.imageUrl,
    required this.caption,
    required this.index,
  });

  final String imageUrl;
  final String caption;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: AppColors.bluePrimary.withValues(alpha: 0.06),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.bluePrimary,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.grayNeutral.withValues(alpha: 0.15),
              child: const Center(
                child: Icon(Icons.broken_image_rounded,
                    size: 36, color: AppColors.grayNeutral),
              ),
            ),
          ),
          // Gradient overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          // Caption
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                height: 1.3,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
          // Index badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          // Tap indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.zoom_in_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceFileCard extends StatelessWidget {
  const _EvidenceFileCard({
    required this.caption,
    required this.type,
  });

  final String caption;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _evidenceIconForType(type),
              color: AppColors.bluePrimary,
              size: 26,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.bluePrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText.withValues(alpha: 0.8),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
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

String? _normalizeEvidenceDescription(String? raw) {
  if (raw == null) {
    return null;
  }

  final sanitizedInput = raw
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'[\t\r]+'), ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  if (sanitizedInput.isEmpty) {
    return null;
  }

  final placeholderPattern = RegExp(r'^imagen\s+\d+\s+de\s+\d+', caseSensitive: false);
  final parts = sanitizedInput.split(RegExp(r'[\n\u2028\u2029]+'));

  for (final part in parts) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) {
      continue;
    }

    final withoutPrefix = _stripListPrefix(trimmed);
    if (withoutPrefix.isEmpty) {
      continue;
    }

    final withoutBullets = _removeBulletGlyphs(withoutPrefix).trim();
    if (withoutBullets.isEmpty) {
      continue;
    }

    if (placeholderPattern.hasMatch(withoutBullets)) {
      continue;
    }

    return withoutBullets;
  }

  return null;
}

String _stripListPrefix(String value) {
  var result = value.trimLeft();

  final numericPrefix = RegExp(r'^(?:\d+[\.)\-:]+)\s*');
  final asciiPunctuationPrefix = RegExp(r'^[\-\*•·\u2022\u2023\u2043\u2219\u2027\u25AA\u25AB\u25CF\u25E6\u26AB\u26AC]+\s*');

  result = result.replaceFirst(numericPrefix, '');
  result = result.replaceFirst(asciiPunctuationPrefix, '');

  return result.trimLeft();
}

String _removeBulletGlyphs(String value) {
  final buffer = StringBuffer();
  for (final codePoint in value.runes) {
    if (_bulletCodePoints.contains(codePoint)) {
      continue;
    }
    buffer.writeCharCode(codePoint);
  }
  return buffer.toString();
}

const Set<int> _bulletCodePoints = {
  0x2022, // •
  0x2023, // ‣
  0x2043, // ⁃
  0x204C, // ? keep optional
  0x204D,
  0x2219, // ∙
  0x2027, // ‧
  0x00B7, // ·
  0x25AA, // ▪
  0x25AB, // ▫
  0x25CF, // ●
  0x25CB, // ○
  0x25C9, // ◉
  0x25E6, // ◦
  0x29BF, // ⦿
  0x2981, // ⦂
  0x26AC, // ⚬
  0x26AB, // ⚫
  0x2736, // ✶
  0x2737, // ✷
  0x2738, // ✸
  0x2794, // ➔
  0x27A4, // ➤
  0x27AA, // ➪
  0x27AB, // ➫
  0x27B2, // ➲
  0x27BD, // ➽
};

class _EvidenceViewerPage extends StatelessWidget {
  const _EvidenceViewerPage({
    required this.evidence,
    required this.previewUrl,
    required this.hasImagePreview,
    required this.heroTag,
    required this.description,
    required this.onOpenLink,
  });

  final CampaignEvidence evidence;
  final String? previewUrl;
  final bool hasImagePreview;
  final String? heroTag;
  final String? description;
  final Future<bool> Function(String url) onOpenLink;

  @override
  Widget build(BuildContext context) {
    final caption = (description?.trim().isEmpty ?? true) ? null : description;
    final hasExternalLink = evidence.url.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
          // ── Imagen / archivo a pantalla completa ──────────────────────
          Center(child: _buildContent(context)),

          // ── Barra superior: fondo degradado ──────────────────────────
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
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _DarkActionButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      if (hasExternalLink)
                        _DarkActionButton(
                          icon: Icons.open_in_new_rounded,
                          label: 'Abrir',
                          onTap: () {
                            Navigator.of(context).pop();
                            unawaited(onOpenLink(evidence.url));
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Barra inferior: caption ───────────────────────────────────
          if (caption != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (hasImagePreview && previewUrl != null) {
      Widget img = InteractiveViewer(
        minScale: 0.8,
        maxScale: 5.0,
        panEnabled: true,
        child: Image.network(
          previewUrl!,
          fit: BoxFit.contain,
          width: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final value = progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                : null;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: value,
                      color: Colors.white70,
                      strokeWidth: 2.5,
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ],
              ),
            );
          },
          errorBuilder: (_, __, ___) => Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.broken_image_outlined,
                  size: 56, color: Colors.white38),
              SizedBox(height: 12),
              Text('No se pudo cargar la imagen',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
      );

      if (heroTag != null) {
        img = Hero(tag: heroTag!, child: img);
      }
      return img;
    }

    // ── Vista de archivo (no imagen) ──────────────────────────────────
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _evidenceIconForType(evidence.type),
                  size: 34,
                  color: AppColors.bluePrimary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  evidence.type.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.bluePrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (description?.trim().isEmpty ?? true)
                    ? 'Archivo adjunto'
                    : description!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (evidence.url.trim().isNotEmpty) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      unawaited(onOpenLink(evidence.url));
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Abrir archivo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _DarkActionButton extends StatelessWidget {
  const _DarkActionButton({
    required this.icon,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: label != null
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
