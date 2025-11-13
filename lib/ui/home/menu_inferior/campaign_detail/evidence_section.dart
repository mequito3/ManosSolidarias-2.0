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
      child: evidences.isEmpty
          ? const _EvidenceEmptyView()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Material validado por el equipo organizador.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: AppColors.space16),
                _EvidenceCarousel(
                  evidences: evidences,
                  onEvidenceTap: onEvidenceTap,
                ),
              ],
            ),
    );
  }
}

class _EvidenceCarousel extends StatelessWidget {
  const _EvidenceCarousel({
    required this.evidences,
    required this.onEvidenceTap,
  });


  final List<CampaignEvidence> evidences;
  final Future<void> Function(CampaignEvidence evidence) onEvidenceTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppColors.space4),
        scrollDirection: Axis.horizontal,
        physics: evidences.length == 1
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        itemCount: evidences.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppColors.space12),
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
    final String? imageUrl;
    if (previewUrl != null &&
        (_isImageEvidenceType(evidence.type) || _looksLikeImageUrl(previewUrl))) {
      imageUrl = previewUrl;
    } else {
      imageUrl = null;
    }
    final description = _normalizeEvidenceDescription(evidence.description);
    final heroTag = imageUrl != null ? 'campaign-evidence-${evidence.id}' : null;

    Widget content;
    if (imageUrl != null) {
      content = _EvidenceImageCard(
        imageUrl: imageUrl,
        caption: description ?? 'Evidencia $index de $total',
      );
    } else {
      content = _EvidenceFileCard(
        caption: description ?? 'Archivo adjunto',
      );
    }

    return SizedBox(
      width: 180,
      child: GestureDetector(
        onTap: () => unawaited(onTap(evidence)),
        child: heroTag != null ? Hero(tag: heroTag, child: content) : content,
      ),
    );
  }
}

class _EvidenceImageCard extends StatelessWidget {
  const _EvidenceImageCard({
    required this.imageUrl,
    required this.caption,
  });

  final String imageUrl;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.grayNeutral.withOpacity(0.15),
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, size: 32, color: Colors.white70),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppColors.space12,
            right: AppColors.space12,
            bottom: AppColors.space12,
            child: Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
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
  });

  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.bluePrimary.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(AppColors.space16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: AppColors.bluePrimary, size: 28),
          const SizedBox(height: AppColors.space12),
          Text(
            caption,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.bluePrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppColors.space12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.bluePrimary.withOpacity(0.7)),
              const SizedBox(width: AppColors.space8),
              Text(
                'Ver archivo',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.bluePrimary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.space20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        color: AppColors.grayNeutral.withOpacity(0.1),
        border: Border.all(color: AppColors.grayNeutral.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.inbox_outlined, color: AppColors.grayNeutral),
              SizedBox(width: AppColors.space8),
              Text(
                'Sin evidencias aún',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space12),
          Text(
            'Todavía no se han publicado archivos de seguimiento para esta campaña.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withOpacity(0.7),
                  height: 1.4,
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
    final theme = Theme.of(context);
    final caption = description?.trim().isEmpty == true ? null : description;
    final hasExternalLink = evidence.url.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFE9F1F8)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.white.withOpacity(0.35)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppColors.space16,
                AppColors.space16,
                AppColors.space16,
                AppColors.space24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _ViewerActionButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Cerrar visor',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      if (hasExternalLink)
                        _ViewerActionButton(
                          icon: Icons.open_in_new_rounded,
                          tooltip: 'Abrir original',
                          onTap: () {
                            Navigator.of(context).pop();
                            unawaited(onOpenLink(evidence.url));
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppColors.space16),
                  Expanded(
                    child: Center(
                      child: _buildPreview(context),
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: AppColors.space16),
                    _CaptionCard(text: caption),
                  ],
                  if (hasExternalLink) ...[
                    const SizedBox(height: AppColors.space12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          unawaited(onOpenLink(evidence.url));
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Abrir original'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.bluePrimary,
                          side: BorderSide(color: AppColors.bluePrimary.withOpacity(0.35)),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppColors.space16,
                            vertical: AppColors.space12,
                          ),
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildPreview(BuildContext context) {
    final cardRadius = BorderRadius.circular(AppColors.radiusXl);
    final innerRadius = BorderRadius.circular(AppColors.radiusLg);

    Widget media;
    if (hasImagePreview && previewUrl != null) {
      media = ClipRRect(
        borderRadius: innerRadius,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            color: Colors.black,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              panEnabled: true,
              child: Image.network(
                previewUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: AppColors.grayDark,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    } else {
      media = _buildFilePreview(context, innerRadius);
    }

    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        boxShadow: AppColors.shadowXl,
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF3F7FC)],
            ),
          ),
          padding: const EdgeInsets.all(AppColors.space12),
          child: media,
        ),
      ),
    );

    if (heroTag != null && hasImagePreview) {
      card = Hero(tag: heroTag!, child: card);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: card,
    );
  }

  Widget _buildFilePreview(BuildContext context, BorderRadius borderRadius) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.grayLight),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space32,
        vertical: AppColors.space32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _evidenceIconForType(evidence.type),
            size: 48,
            color: AppColors.bluePrimary,
          ),
          const SizedBox(height: AppColors.space16),
          Text(
            evidence.type.toUpperCase(),
            style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(height: AppColors.space12),
          Text(
            evidence.url,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mediumText,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _CaptionCard extends StatelessWidget {
  const _CaptionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.grayLight),
        boxShadow: AppColors.shadowMd,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.mediumText,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ViewerActionButton extends StatelessWidget {
  const _ViewerActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        shape: const CircleBorder(),
        elevation: 8,
        color: Colors.white,
        shadowColor: AppColors.grayDark.withOpacity(0.18),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color: AppColors.bluePrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
