part of 'campaign_detail_page.dart';

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.comments,
    required this.canComment,
    required this.commentController,
    required this.onSubmitComment,
    required this.isSubmittingComment,
    this.highlightCommentId,
  });

  final List<CampaignComment> comments;
  final bool canComment;
  final TextEditingController commentController;
  final Future<void> Function(String message) onSubmitComment;
  final bool isSubmittingComment;
  final String? highlightCommentId;

  @override
  Widget build(BuildContext context) {
    final visibleComments = comments.where((c) => c.isVisible).toList();

    return _SectionCard(
      title: 'Comentarios',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentsSectionCompactHeader(total: visibleComments.length),
          const SizedBox(height: 20),
          canComment
              ? _CommentComposer(
                  controller: commentController,
                  onSubmit: onSubmitComment,
                  isSubmitting: isSubmittingComment,
                )
              : const _CommentLoginPrompt(),
          const SizedBox(height: 20),
          _CommentsList(
            comments: visibleComments,
            highlightCommentId: highlightCommentId,
          ),
        ],
      ),
    );
  }
}

class _CommentsSectionCompactHeader extends StatelessWidget {
  const _CommentsSectionCompactHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final label = total == 1 ? 'comentario' : 'comentarios';

    return Text(
      '$total $label',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.darkText.withValues(alpha: 0.7),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final TextEditingController controller;
  final Future<void> Function(String message) onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> handleSubmit() async {
      final trimmed = controller.text.trim();
      if (trimmed.length < 3 || isSubmitting) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe al menos 3 caracteres para publicar.')),
        );
        return;
      }
      await onSubmit(trimmed);
      controller.clear();
      FocusScope.of(context).unfocus();
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            enabled: !isSubmitting,
            minLines: 2,
            maxLines: 4,
            maxLength: 400,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Comparte tu apoyo y palabras de aliento...',
              hintStyle: TextStyle(fontSize: 13),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: scheme.primary, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mantén la conversación respetuosa y evita datos personales.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withOpacity(0.75),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: isSubmitting ? null : () async => handleSubmit(),
                icon: isSubmitting
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                        ),
                      )
                    : const Icon(Icons.send_outlined, size: 14),
                label: const Text(
                  'Publicar',
                  style: TextStyle(fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(100, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentLoginPrompt extends StatelessWidget {
  const _CommentLoginPrompt();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: scheme.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inicia sesión para comentar',
                  style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solo los usuarios autenticados pueden participar en la conversación.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withOpacity(0.8),
                    height: 1.4,
                    fontSize: 12,
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

class _CommentsList extends StatefulWidget {
  const _CommentsList({
    required this.comments,
    this.highlightCommentId,
  });

  final List<CampaignComment> comments;
  final String? highlightCommentId;

  @override
  State<_CommentsList> createState() => _CommentsListState();
}

class _CommentsListState extends State<_CommentsList> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _commentKeys = {};

  @override
  void initState() {
    super.initState();
    // Crear keys para cada comentario
    for (final comment in widget.comments) {
      _commentKeys[comment.id] = GlobalKey();
    }
    // Scroll al comentario resaltado después de que se construya
    if (widget.highlightCommentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlightedComment();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHighlightedComment() {
    final key = _commentKeys[widget.highlightCommentId];
    if (key?.currentContext != null) {
      final context = key!.currentContext!;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.2, // Posicionar cerca del top
      );
    }
  }

  List<CampaignComment> get comments => widget.comments;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (comments.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 24, color: scheme.onSurfaceVariant.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text(
              'Todavía no hay comentarios',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Sé la primera persona en dejar tu mensaje de apoyo.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Scrollbar(
        controller: _scrollController,
        child: ListView.separated(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: comments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final comment = comments[index];
            final shouldHighlight = widget.highlightCommentId == comment.id;
            return _CommentTile(
              key: _commentKeys[comment.id],
              comment: comment,
              shouldHighlight: shouldHighlight,
            );
          },
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    super.key,
    required this.comment,
    this.shouldHighlight = false,
  });

  final CampaignComment comment;
  final bool shouldHighlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final author = comment.authorName.trim().isNotEmpty ? comment.authorName.trim() : 'Usuario solidario';
    final message = comment.message.trim().isNotEmpty ? comment.message.trim() : 'Comentario no disponible.';
    final avatarUrl = comment.authorAvatarUrl?.trim();

    final commentWidget = Container(
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(context, avatarUrl, author),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: scheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _relativeTimeLabel(comment.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.85),
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Envolver en HighlightWrapper si debe resaltarse
    return HighlightWrapper(
      shouldHighlight: shouldHighlight,
      child: commentWidget,
    );
  }

  Widget _buildAvatar(BuildContext context, String? avatarUrl, String author) {
    final scheme = Theme.of(context).colorScheme;
    final initials = author.isNotEmpty ? author.characters.first.toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: scheme.primary.withOpacity(0.12),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.primary,
          fontSize: 14,
        ),
      ),
    );
  }
}

String _relativeTimeLabel(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.isNegative) {
    return 'justo ahora';
  }
  if (difference.inMinutes < 1) {
    return 'justo ahora';
  }
  if (difference.inMinutes < 60) {
    return 'hace ${difference.inMinutes} min';
  }
  if (difference.inHours < 24) {
    return 'hace ${difference.inHours} h';
  }
  if (difference.inDays == 1) {
    return 'ayer';
  }
  if (difference.inDays < 7) {
    return 'hace ${difference.inDays} días';
  }
  if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return 'hace $weeks ${weeks == 1 ? 'sem' : 'semanas'}';
  }
  if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return 'hace $months ${months == 1 ? 'mes' : 'meses'}';
  }
  final years = (difference.inDays / 365).floor();
  return 'hace $years ${years == 1 ? 'año' : 'años'}';
}
