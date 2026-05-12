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
      icon: Icons.chat_bubble_rounded,
      iconColor: AppColors.blueSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentsHeader(total: visibleComments.length),
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

class _CommentsHeader extends StatelessWidget {
  const _CommentsHeader({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.blueSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColors.blueSecondary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 12, color: AppColors.blueSecondary),
              const SizedBox(width: 5),
              Text(
                '$total ${total == 1 ? 'comentario' : 'comentarios'}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            total == 0
                ? 'Sé la primera persona en comentar'
                : 'Únete a la conversación',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkText.withValues(alpha: 0.45),
            ),
          ),
        ),
      ],
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
    Future<void> handleSubmit() async {
      final trimmed = controller.text.trim();
      if (trimmed.length < 3 || isSubmitting) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Escribe al menos 3 caracteres para publicar.')),
        );
        return;
      }
      await onSubmit(trimmed);
      controller.clear();
      FocusScope.of(context).unfocus();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.bluePrimary.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar placeholder
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.bluePrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isSubmitting,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 400,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 14,
                    height: 1.45,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu mensaje de apoyo...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkText.withValues(alpha: 0.35),
                    ),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
              height: 1,
              color: AppColors.dividerColor.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 13,
                  color: AppColors.darkText.withValues(alpha: 0.35)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Sé respetuoso y no compartas datos personales.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.darkText.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Botón publicar
              GestureDetector(
                onTap: isSubmitting ? null : handleSubmit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSubmitting
                        ? null
                        : AppColors.actionGradient,
                    color: isSubmitting
                        ? AppColors.grayNeutral.withValues(alpha: 0.2)
                        : null,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: isSubmitting
                        ? null
                        : [
                            BoxShadow(
                              color:
                                  AppColors.orangeAction.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSubmitting)
                        const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.send_rounded,
                            size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        isSubmitting ? 'Enviando...' : 'Publicar',
                        style: TextStyle(
                          color: isSubmitting
                              ? AppColors.grayNeutral
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.bluePrimary.withValues(alpha: 0.15), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_rounded,
                color: AppColors.bluePrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inicia sesión para comentar',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Los usuarios registrados pueden unirse a la conversación.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.darkText.withValues(alpha: 0.55),
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
    for (final comment in widget.comments) {
      _commentKeys[comment.id] = GlobalKey();
    }
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
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }
  }

  List<CampaignComment> get comments => widget.comments;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.grayNeutral.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.grayNeutral.withValues(alpha: 0.18),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.blueSecondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined,
                  color: AppColors.blueSecondary, size: 24),
            ),
            const SizedBox(height: 12),
            const Text(
              'Todavía no hay comentarios',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Sé la primera persona en dejar un mensaje de apoyo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: AppColors.darkText.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _CommentTile(
          key: _commentKeys[comment.id],
          comment: comment,
          shouldHighlight: widget.highlightCommentId == comment.id,
          isFirst: index == 0,
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    super.key,
    required this.comment,
    this.shouldHighlight = false,
    this.isFirst = false,
  });

  final CampaignComment comment;
  final bool shouldHighlight;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final author = comment.authorName.trim().isNotEmpty
        ? comment.authorName.trim()
        : 'Usuario solidario';
    final message = comment.message.trim().isNotEmpty
        ? comment.message.trim()
        : 'Comentario no disponible.';
    final avatarUrl = comment.authorAvatarUrl?.trim();
    final initials =
        author.isNotEmpty ? author.characters.first.toUpperCase() : '?';

    Widget tile = Container(
      decoration: BoxDecoration(
        color: shouldHighlight
            ? AppColors.blueSecondary.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: shouldHighlight
              ? AppColors.blueSecondary.withValues(alpha: 0.3)
              : AppColors.dividerColor.withValues(alpha: 0.5),
          width: shouldHighlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.blueSecondary.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor:
                  AppColors.blueSecondary.withValues(alpha: 0.1),
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.blueSecondary,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
          ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _relativeTimeLabel(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.darkText.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.darkText.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return HighlightWrapper(
      shouldHighlight: shouldHighlight,
      child: tile,
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
