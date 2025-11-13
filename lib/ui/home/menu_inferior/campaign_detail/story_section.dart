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

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          if (index > 0) const SizedBox(height: AppColors.space16),
          _StoryBlockRenderer(
            block: blocks[index],
            theme: theme,
            onOpenLink: onOpenLink,
          ),
        ],
      ],
    );
  }
}

class _StoryBlockRenderer extends StatelessWidget {
  const _StoryBlockRenderer({
    required this.block,
    required this.theme,
    this.onOpenLink,
  });

  final _StoryBlock block;
  final ThemeData theme;
  final Future<bool> Function(String url)? onOpenLink;

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case _StoryBlockType.heading:
        return _buildHeading();
      case _StoryBlockType.paragraph:
        return _buildParagraph(context);
      case _StoryBlockType.bulletList:
        return _buildBulletList(context);
      case _StoryBlockType.link:
        return _buildLink(context);
      case _StoryBlockType.imageGallery:
        return _buildImageGallery();
    }
  }

  Widget _buildHeading() {
    final heading = block.heading ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space16,
        vertical: AppColors.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.bluePrimary),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Text(
              heading,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.bluePrimary,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(BuildContext context) {
    final segments = block.segments ?? const [];
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildInlineRichText(context, segments);
  }

  Widget _buildBulletList(BuildContext context) {
    final items = block.bulletItems ?? const [];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const SizedBox(height: AppColors.space12),
            _buildBulletItem(context, items[index]),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletItem(BuildContext context, _BulletEntry entry) {
    final hasText = entry.segments.isNotEmpty;
    final hasImages = entry.imageUrls.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasText)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.bluePrimary,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: AppColors.space12),
              Expanded(child: _buildInlineRichText(context, entry.segments)),
            ],
          ),
        if (hasImages) ...[
          if (hasText) const SizedBox(height: AppColors.space12),
          _StoryImageCarousel(imageUrls: entry.imageUrls),
        ],
      ],
    );
  }

  Widget _buildLink(BuildContext context) {
    final url = block.url;
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }
    return _LinkTile(
      label: _shortenUrl(url),
      onTap: onOpenLink == null ? null : () => unawaited(onOpenLink!.call(url)),
    );
  }

  Widget _buildImageGallery() {
    final urls = block.imageUrls ?? const [];
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }
    return _StoryImageCarousel(imageUrls: urls);
  }

  Widget _buildInlineRichText(BuildContext context, List<_InlineSegment> segments) {
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.5,
      color: AppColors.darkText.withValues(alpha: 0.9),
    );

    final labelStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.bold,
      color: AppColors.bluePrimary,
    );

    final spans = <InlineSpan>[];
    for (final segment in segments) {
      switch (segment.kind) {
        case _InlineSegmentKind.text:
          // Detectar etiquetas importantes como "Nombre:", "Edad:", etc.
          final text = segment.value;
          final labelPattern = RegExp(r'(^|\s)([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[a-záéíóúñ]+)*):(\s|$)');
          
          var lastIndex = 0;
          for (final match in labelPattern.allMatches(text)) {
            // Agregar texto antes del label
            if (match.start > lastIndex) {
              spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
            }
            
            // Agregar el label resaltado
            final prefix = match.group(1) ?? '';
            final label = match.group(2) ?? '';
            final suffix = match.group(3) ?? '';
            
            if (prefix.isNotEmpty) {
              spans.add(TextSpan(text: prefix));
            }
            spans.add(TextSpan(text: '$label:', style: labelStyle));
            if (suffix.isNotEmpty) {
              spans.add(TextSpan(text: suffix));
            }
            
            lastIndex = match.end;
          }
          
          // Agregar texto restante
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
      barrierColor: Colors.black.withOpacity(0.25),
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

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppColors.space4),
        itemCount: total,
        separatorBuilder: (_, __) => const SizedBox(width: AppColors.space16),
        itemBuilder: (context, index) {
          final url = imageUrls[index];
          return SizedBox(
            width: 260,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: Material(
        color: AppColors.lightBackground,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.grayNeutral,
                          size: 36,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Imagen ${index + 1} de $total',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Icon(Icons.open_in_full, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          color: AppColors.cardBackground,
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.05),
                Colors.black.withOpacity(0.15),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: urls.length,
                  onPageChanged: (value) => setState(() => _currentIndex = value),
                  itemBuilder: (context, index) {
                    final url = urls[index];
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                                  : null,
                              color: AppColors.bluePrimary,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.grayNeutral,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.darkText, size: 24),
                    tooltip: 'Cerrar',
                  ),
                ),
              ),
              if (urls.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(AppColors.radiusRound),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${urls.length}',
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
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

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.space16,
              vertical: AppColors.space12,
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: AppColors.bluePrimary, size: 20),
                const SizedBox(width: AppColors.space12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.bluePrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Icon(Icons.open_in_new_rounded, color: AppColors.bluePrimary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
