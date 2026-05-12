part of 'campaign_detail_page.dart';

class _StoryBody extends StatelessWidget {
  const _StoryBody({
    required this.content,
    this.onOpenLink,
  });

  final String content;
  final Future<bool> Function(String url)? onOpenLink;

  @override
  Widget build(BuildContext context) {
    final blocks = _StoryParser.parse(content);
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          if (index > 0) const SizedBox(height: AppColors.space16),
          _StoryBlockRenderer(
            block: blocks[index],
            onOpenLink: onOpenLink,
          ),
        ],
      ],
    );
  }
}

/// Dispatches each [_StoryBlock] to the appropriate widget.
/// Per flutter-expert skill: no _build*() methods — each block type
/// is a separate StatelessWidget.
class _StoryBlockRenderer extends StatelessWidget {
  const _StoryBlockRenderer({
    required this.block,
    this.onOpenLink,
  });

  final _StoryBlock block;
  final Future<bool> Function(String url)? onOpenLink;

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case _StoryBlockType.heading:
        final heading = block.heading ?? '';
        if (heading.isEmpty) return const SizedBox.shrink();
        return _StoryHeading(text: heading);
      case _StoryBlockType.paragraph:
        final segments = block.segments ?? const [];
        if (segments.isEmpty) return const SizedBox.shrink();
        return _StoryInlineText(segments: segments, onOpenLink: onOpenLink);
      case _StoryBlockType.bulletList:
        final items = block.bulletItems ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return _StoryBulletList(items: items, onOpenLink: onOpenLink);
      case _StoryBlockType.link:
        final url = block.url;
        if (url == null || url.isEmpty) return const SizedBox.shrink();
        return _LinkTile(
          label: _shortenUrl(url),
          onTap: onOpenLink == null ? null : () => unawaited(onOpenLink!.call(url)),
        );
      case _StoryBlockType.imageGallery:
        final urls = block.imageUrls ?? const [];
        if (urls.isEmpty) return const SizedBox.shrink();
        return _StoryImageCarousel(imageUrls: urls);
    }
  }
}

// ─── Story Block Widgets ──────────────────────────────────────────────────────

class _StoryHeading extends StatelessWidget {
  const _StoryHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: const BoxDecoration(
              color: AppColors.bluePrimary,
              borderRadius: BorderRadius.all(Radius.circular(99)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryBulletList extends StatelessWidget {
  const _StoryBulletList({
    required this.items,
    this.onOpenLink,
  });

  final List<_BulletEntry> items;
  final Future<bool> Function(String url)? onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) ...[const SizedBox(height: 4), Divider(height: 1, color: AppColors.dividerColor.withValues(alpha: 0.4)), const SizedBox(height: 8)],
            _StoryBulletItem(entry: items[index], onOpenLink: onOpenLink),
          ],
        ],
      ),
    );
  }
}

class _StoryBulletItem extends StatelessWidget {
  const _StoryBulletItem({
    required this.entry,
    this.onOpenLink,
  });

  final _BulletEntry entry;
  final Future<bool> Function(String url)? onOpenLink;

  @override
  Widget build(BuildContext context) {
    final hasText = entry.segments.isNotEmpty;
    final hasImages = entry.imageUrls.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasText)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BulletDot(),
              const SizedBox(width: 12),
              Expanded(
                child: _StoryInlineText(
                  segments: entry.segments,
                  onOpenLink: onOpenLink,
                ),
              ),
            ],
          ),
        if (hasImages) ...[
          if (hasText) const SizedBox(height: AppColors.space12),
          _StoryImageCarousel(imageUrls: entry.imageUrls),
        ],
      ],
    );
  }
}

class _BulletDot extends StatelessWidget {
  const _BulletDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bluePrimary,
      ),
    );
  }
}

/// Renders a list of [_InlineSegment]s as a rich text widget.
/// Bold labels ("Nombre:", "Edad:") are auto-highlighted in blue.
class _StoryInlineText extends StatelessWidget {
  const _StoryInlineText({
    required this.segments,
    this.onOpenLink,
  });

  final List<_InlineSegment> segments;
  final Future<bool> Function(String url)? onOpenLink;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.65,
      fontSize: 14.5,
      color: AppColors.darkText.withValues(alpha: 0.85),
    );

    final labelStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.bluePrimary,
    );

    final spans = <InlineSpan>[];
    for (final segment in segments) {
      switch (segment.kind) {
        case _InlineSegmentKind.text:
          final text = segment.value;
          final labelPattern = RegExp(r'(^|\s)([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[a-záéíóúñ]+)*):(\s|$)');
          var lastIndex = 0;
          for (final match in labelPattern.allMatches(text)) {
            if (match.start > lastIndex) {
              spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
            }
            final prefix = match.group(1) ?? '';
            final label = match.group(2) ?? '';
            final suffix = match.group(3) ?? '';
            if (prefix.isNotEmpty) spans.add(TextSpan(text: prefix));
            spans.add(TextSpan(text: '$label:', style: labelStyle));
            if (suffix.isNotEmpty) spans.add(TextSpan(text: suffix));
            lastIndex = match.end;
          }
          if (lastIndex < text.length) {
            spans.add(TextSpan(text: text.substring(lastIndex)));
          }
          break;
        case _InlineSegmentKind.link:
          TapGestureRecognizer? recognizer;
          if (onOpenLink != null) {
            recognizer = TapGestureRecognizer()
              ..onTap = () => unawaited(onOpenLink!.call(segment.value));
          }
          spans.add(
            TextSpan(
              text: segment.value,
              style: (baseStyle ?? const TextStyle()).copyWith(
                color: AppColors.bluePrimary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
              recognizer: recognizer,
            ),
          );
          break;
      }
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}

enum _StoryBlockType { heading, paragraph, bulletList, link, imageGallery }

class _StoryBlock {
  const _StoryBlock._({
    required this.type,
    this.heading,
    this.segments,
    this.bulletItems,
    this.url,
    this.imageUrls,
  });

  final _StoryBlockType type;
  final String? heading;
  final List<_InlineSegment>? segments;
  final List<_BulletEntry>? bulletItems;
  final String? url;
  final List<String>? imageUrls;

  factory _StoryBlock.heading(String value) => _StoryBlock._(
        type: _StoryBlockType.heading,
        heading: value,
      );

  factory _StoryBlock.paragraph(List<_InlineSegment> segments) => _StoryBlock._(
        type: _StoryBlockType.paragraph,
        segments: List<_InlineSegment>.from(segments),
      );

  factory _StoryBlock.bulletList(List<_BulletEntry> items) => _StoryBlock._(
        type: _StoryBlockType.bulletList,
        bulletItems: List<_BulletEntry>.from(items),
      );

  factory _StoryBlock.link(String url) => _StoryBlock._(
        type: _StoryBlockType.link,
        url: url,
      );

  factory _StoryBlock.imageGallery(List<String> urls) => _StoryBlock._(
        type: _StoryBlockType.imageGallery,
        imageUrls: List<String>.from(urls),
      );
}

class _BulletEntry {
  const _BulletEntry(this.segments, this.imageUrls);

  final List<_InlineSegment> segments;
  final List<String> imageUrls;
}

enum _InlineSegmentKind { text, link }

class _InlineSegment {
  const _InlineSegment._(this.kind, this.value);

  factory _InlineSegment.text(String value) => _InlineSegment._(_InlineSegmentKind.text, value);
  factory _InlineSegment.link(String value) => _InlineSegment._(_InlineSegmentKind.link, value);

  final _InlineSegmentKind kind;
  final String value;
}

class _StoryParser {
  static final RegExp _urlRegExp = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
  static final RegExp _markdownImageRegExp = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');
  static final RegExp _listMarkerPattern = RegExp(r'^(?:[\-\*•·\u2022\u2023\u2043\u2219\u2027\u25AA\u25AB\u25CF\u25CB\u25C9\u25E6\u26AB\u26AC]+|\d+[\.\)\-:])\s*');
  static final RegExp _bulletGlyphPattern = RegExp(r'[•·\u2022\u2023\u2043\u2219\u2027\u00B7\u25AA\u25AB\u25CF\u25CB\u25C9\u25E6\u26AB\u26AC\u29BF]');
  static final RegExp _placeholderPattern = RegExp(r'^imagen\s+\d+\s+de\s+\d+\.?$', caseSensitive: false);

  static List<_StoryBlock> parse(String rawContent) {
    if (rawContent.trim().isEmpty) {
      return const [];
    }

    final normalized = rawContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final lines = normalized.split('\n');

    final blocks = <_StoryBlock>[];
    final bulletBuffer = <_BulletEntry>[];

    void flushBullets() {
      if (bulletBuffer.isEmpty) {
        return;
      }
      blocks.add(_StoryBlock.bulletList(List<_BulletEntry>.from(bulletBuffer)));
      bulletBuffer.clear();
    }

    void appendImages(List<String> urls) {
      final sanitized = urls.map((url) => url.trim()).where((url) => url.isNotEmpty).toList();
      if (sanitized.isEmpty) {
        return;
      }
      if (blocks.isNotEmpty && blocks.last.type == _StoryBlockType.imageGallery) {
        blocks.last.imageUrls!.addAll(sanitized);
      } else {
        blocks.add(_StoryBlock.imageGallery(sanitized));
      }
    }

    for (final originalLine in lines) {
      final line = originalLine.trim();

      if (line.isEmpty) {
        flushBullets();
        continue;
      }

      if (_isMarkdownImage(line)) {
        final url = _extractMarkdownImageUrl(line);
        if (url != null) {
          flushBullets();
          appendImages([url]);
          continue;
        }
      }

      if (_isStandaloneUrl(line) && _looksLikeImageUrl(line)) {
        flushBullets();
        appendImages([line]);
        continue;
      }

      if (_isListLine(line)) {
        final stripped = _stripListMarker(line);
        final cleaned = _removeBulletGlyphs(stripped).trim();
        if (cleaned.isEmpty) {
          continue;
        }
        if (_isPlaceholder(cleaned)) {
          continue;
        }

        final imageSink = <String>[];
        final segments = _parseInlineSegments(cleaned, imageSink);

        if (segments.isEmpty && imageSink.isNotEmpty) {
          flushBullets();
          appendImages(imageSink);
          continue;
        }

        if (segments.isEmpty) {
          continue;
        }

        bulletBuffer.add(_BulletEntry(segments, imageSink));
        continue;
      }

      flushBullets();

      if (_looksLikeSectionHeader(line)) {
        final heading = line.replaceAll(':', '').trim();
        if (heading.isNotEmpty) {
          blocks.add(_StoryBlock.heading(heading));
        }
        continue;
      }

      if (_isStandaloneUrl(line)) {
        if (_looksLikeImageUrl(line)) {
          appendImages([line]);
        } else {
          blocks.add(_StoryBlock.link(line));
        }
        continue;
      }

      final inlineImageMatches = _markdownImageRegExp
          .allMatches(line)
          .map((match) => match.group(1))
          .whereType<String>()
          .toList();

      var working = line;
      if (inlineImageMatches.isNotEmpty) {
        working = working.replaceAll(_markdownImageRegExp, ' ');
      }

      final cleanedWorking = _removeBulletGlyphs(working);
      if (cleanedWorking.trim().isEmpty) {
        if (inlineImageMatches.isNotEmpty) {
          appendImages(inlineImageMatches);
        }
        continue;
      }
      if (_isPlaceholder(cleanedWorking.trim())) {
        continue;
      }

      final imageSink = <String>[];
      final segments = _parseInlineSegments(cleanedWorking, imageSink);

      if (segments.isNotEmpty) {
        blocks.add(_StoryBlock.paragraph(segments));
      } else {
        final fallbackText = _cleanInlineText(cleanedWorking);
        if (fallbackText.isNotEmpty) {
          blocks.add(_StoryBlock.paragraph([_InlineSegment.text(fallbackText)]));
        }
      }

      final imagesToAppend = <String>[...inlineImageMatches, ...imageSink];
      if (imagesToAppend.isNotEmpty) {
        appendImages(imagesToAppend);
      }
    }

    flushBullets();
    return blocks;
  }

  static bool _isListLine(String line) => _listMarkerPattern.hasMatch(line.trimLeft());

  static bool _looksLikeSectionHeader(String line) {
    final normalized = line.trim();
    if (_isListLine(normalized)) {
      return false;
    }
    return normalized.endsWith(':');
  }

  static bool _isStandaloneUrl(String line) {
    final lower = line.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  static bool _isMarkdownImage(String line) => _markdownImageRegExp.hasMatch(line);

  static String? _extractMarkdownImageUrl(String line) {
    final match = _markdownImageRegExp.firstMatch(line);
    return match?.group(1);
  }

  static String _stripListMarker(String line) => line.trimLeft().replaceFirst(_listMarkerPattern, '').trimLeft();

  static String _removeBulletGlyphs(String value) => value.replaceAll(_bulletGlyphPattern, '');

  static bool _isPlaceholder(String value) => _placeholderPattern.hasMatch(value.toLowerCase());

  static List<_InlineSegment> _parseInlineSegments(String text, List<String> imageSink) {
    final segments = <_InlineSegment>[];
    var cursor = 0;

    for (final match in _urlRegExp.allMatches(text)) {
      if (match.start > cursor) {
        _appendTextSegment(segments, text.substring(cursor, match.start));
      }

      final url = match.group(0) ?? '';
      if (_looksLikeImageUrl(url)) {
        imageSink.add(url);
      } else if (url.isNotEmpty) {
        segments.add(_InlineSegment.link(_cleanInlineText(url)));
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      _appendTextSegment(segments, text.substring(cursor));
    }

    return segments;
  }

  static void _appendTextSegment(List<_InlineSegment> segments, String raw) {
    if (raw.isEmpty) {
      return;
    }

    final hadLeadingSpace = raw.startsWith(' ');
    final hadTrailingSpace = raw.endsWith(' ');
    var cleaned = _cleanInlineText(raw);

    if (cleaned.isEmpty) {
      if (hadLeadingSpace || hadTrailingSpace) {
        segments.add(_InlineSegment.text(' '));
      }
      return;
    }

    if (hadLeadingSpace) {
      cleaned = ' $cleaned';
    }
    if (hadTrailingSpace) {
      cleaned = '$cleaned ';
    }

    segments.add(_InlineSegment.text(cleaned));
  }

  static String _cleanInlineText(String raw) {
    final withoutBullets = _removeBulletGlyphs(raw);
    final collapsed = withoutBullets.replaceAll(RegExp(r'\s{2,}'), ' ');
    return collapsed.trim();
  }
}

String _shortenUrl(String raw) {
  final cleaned = raw.replaceFirst(RegExp(r'^https?://'), '');
  if (cleaned.length <= 42) {
    return cleaned;
  }
  return '${cleaned.substring(0, 42)}…';
}

class _StoryImageCarousel extends StatelessWidget {
  const _StoryImageCarousel({required this.imageUrls});

  final List<String> imageUrls;

  Future<void> _openViewer(BuildContext context, int index) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      useSafeArea: false,
      builder: (dialogContext) => _StoryImageViewerDialog(
        imageUrls: imageUrls,
        initialIndex: index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final total = imageUrls.length;

    // Si solo hay una imagen, mostrarla ancha
    if (total == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _StoryImageTile(
            url: imageUrls[0],
            index: 0,
            total: 1,
            onTap: () => unawaited(_openViewer(context, 0)),
            theme: theme,
          ),
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: total,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = imageUrls[index];
          return SizedBox(
            width: 240,
            child: _StoryImageTile(
              url: url,
              index: index,
              total: total,
              onTap: () => unawaited(_openViewer(context, index)),
              theme: theme,
            ),
          );
        },
      ),
    );
  }
}

class _StoryImageTile extends StatelessWidget {
  const _StoryImageTile({
    required this.url,
    required this.index,
    required this.total,
    required this.onTap,
    required this.theme,
  });

  final String url;
  final int index;
  final int total;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'story_img_$url',
              child: Image.network(
                url,
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
                color: AppColors.grayNeutral.withValues(alpha: 0.1),
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.grayNeutral, size: 32),
                ),
              ),
            ),
            ),
            // Gradiente inferior muy suave para visibilidad de los controles
            Positioned(
              left: 0, right: 0, bottom: 0, height: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Badge contador top-left
            if (total > 1)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${index + 1}/$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            // Zoom hint bottom-right
            Positioned(
              bottom: 8, right: 8,
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
      ),
    );
  }
}

class _StoryImageViewerDialog extends StatefulWidget {
  const _StoryImageViewerDialog({required this.imageUrls, required this.initialIndex});

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_StoryImageViewerDialog> createState() => _StoryImageViewerDialogState();
}

class _StoryImageViewerDialogState extends State<_StoryImageViewerDialog> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo de cristal
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
          // Páginas de imágenes
          PageView.builder(
            controller: _controller,
            itemCount: urls.length,
            onPageChanged: (value) => setState(() => _currentIndex = value),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Hero(
                  tag: 'story_img_${urls[index]}',
                  child: Image.network(
                    urls[index],
                    fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white70,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white38, size: 52),
                  ),
                ),
              ),
            );
            },
          ),
          // Barra superior (sin gradiente negro masivo para mantener el cristal limpio)
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const Spacer(),
                    if (urls.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${urls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Indicadores de página (dots)
          if (urls.length > 1)
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.bluePrimary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.bluePrimary.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.link_rounded,
                  color: AppColors.bluePrimary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.bluePrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.bluePrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new_rounded,
                color: AppColors.bluePrimary, size: 15),
          ],
        ),
      ),
    );
  }
}
