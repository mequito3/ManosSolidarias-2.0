part of 'campaign_detail_page.dart';

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.comments,
    required this.canComment,
    required this.commentController,
    required this.onSubmitComment,
    required this.isSubmittingComment,
    required this.userProfile,
    this.highlightCommentId,
  });

  final List<CampaignComment> comments;
  final bool canComment;
  final TextEditingController commentController;
  final Future<void> Function(String message) onSubmitComment;
  final bool isSubmittingComment;
  final UserProfile userProfile;
  final String? highlightCommentId;

  @override
  Widget build(BuildContext context) {
    final visibleComments = comments.where((c) => c.isVisible).toList();

    return _SectionCard(
      title: 'Comentarios',
      icon: Icons.forum_rounded,
      iconColor: AppColors.blueSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentsHeader(total: visibleComments.length),
          const SizedBox(height: 14),
          canComment
              ? _CommentComposer(
                  controller: commentController,
                  onSubmit: onSubmitComment,
                  isSubmitting: isSubmittingComment,
                  userProfile: userProfile,
                )
              : const _CommentLoginPrompt(),
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
    return Text(
      total == 0
          ? 'Sé la primera persona en comentar'
          : '$total ${total == 1 ? 'persona ha comentado' : 'personas han comentado'}',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText.withValues(alpha: 0.6),
        height: 1.4,
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.onSubmit,
    required this.isSubmitting,
    required this.userProfile,
  });

  final TextEditingController controller;
  final Future<void> Function(String message) onSubmit;
  final bool isSubmitting;
  final UserProfile userProfile;

  String get _initial {
    final name = userProfile.displayName?.trim() ?? '';
    if (name.isEmpty) return '?';
    return name.characters.first.toUpperCase();
  }

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

    final avatarUrl = userProfile.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.10),
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
          child: hasAvatar
              ? null
              : Text(
                  _initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.bluePrimary,
                    fontSize: 15,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkText.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.darkText.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  enabled: !isSubmitting,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 400,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: '¿Qué le querés decir al organizador?',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkText.withValues(alpha: 0.4),
                    ),
                    counterText: '',
                    helperText: null,
                    errorText: null,
                    errorStyle: const TextStyle(height: 0),
                    helperStyle: const TextStyle(height: 0),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: isSubmitting ? null : handleSubmit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSubmitting
                              ? AppColors.darkText.withValues(alpha: 0.15)
                              : AppColors.orangeAction,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Publicar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentLoginPrompt extends StatelessWidget {
  const _CommentLoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkText.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.darkText.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Iniciá sesión para comentar',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Los usuarios registrados pueden unirse a la conversación.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: AppColors.darkText.withValues(alpha: 0.55),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Todavía no hay comentarios',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sé la primera persona en dejar un mensaje de apoyo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: AppColors.darkText.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: AppColors.darkText.withValues(alpha: 0.06),
      ),
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

    final tile = Container(
      color: shouldHighlight
          ? AppColors.bluePrimary.withValues(alpha: 0.05)
          : null,
      padding: EdgeInsets.only(
        top: isFirst ? 18 : 14,
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.10),
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.bluePrimary,
                      fontSize: 15,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.darkText),
                    children: [
                      TextSpan(
                        text: author,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: -0.1,
                          height: 1.3,
                        ),
                      ),
                      TextSpan(
                        text: '   ${_relativeTimeLabel(comment.createdAt)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkText.withValues(alpha: 0.45),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText.withValues(alpha: 0.85),
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
