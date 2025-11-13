part of 'campaign_detail_page.dart';

class _CampaignDetailView extends StatelessWidget {
  const _CampaignDetailView({
    required this.detail,
    required this.comments,
    required this.canSupport,
    this.onSupportTap,
    required this.onEvidenceTap,
    required this.onOpenLink,
    required this.canComment,
    required this.commentController,
    required this.onSubmitComment,
    required this.isSubmittingComment,
    this.highlightCommentId,
    this.highlightDonationId,
  });

  final CampaignDetail detail;
  final List<CampaignComment> comments;
  final bool canSupport;
  final VoidCallback? onSupportTap;
  final Future<void> Function(CampaignEvidence evidence) onEvidenceTap;
  final Future<bool> Function(String url) onOpenLink;
  final bool canComment;
  final TextEditingController commentController;
  final Future<void> Function(String message) onSubmitComment;
  final bool isSubmittingComment;
  final String? highlightCommentId;
  final String? highlightDonationId;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    final hasStory = detail.story?.trim().isNotEmpty == true;
    final hasLocation = detail.location?.trim().isNotEmpty == true;
    final hasOrganizerBio = detail.organizerBio?.trim().isNotEmpty == true;
    final hasOrganizerAvatar = detail.organizerAvatarUrl?.trim().isNotEmpty == true;
    final hasOrganizerSection = hasOrganizerBio || hasOrganizerAvatar;
    final hasVideo = detail.videoUrl?.trim().isNotEmpty == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoverHeader(summary: summary),
          const SizedBox(height: 12),
          _CreatorProfile(
            name: detail.creatorName ?? 'Organizador',
            avatarUrl: detail.creatorAvatarUrl,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _SummaryStats(
              detail: detail,
              canSupport: canSupport,
              onSupportTap: onSupportTap,
              highlightDonation: highlightDonationId != null,
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Historia',
            child: detail.longDescription?.trim().isNotEmpty == true
                ? _StoryBody(
                    content: detail.longDescription!.trim(),
                    onOpenLink: onOpenLink,
                  )
                : Text(
                    'El organizador todavía no ha compartido una historia detallada. Puedes apoyarla para que reciba más visibilidad.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          color: AppColors.darkText.withValues(alpha: 0.85),
                        ),
                  ),
          ),
          if (hasStory)
            _SectionCard(
              title: '¿Por qué importa?',
              child: _StoryBody(
                content: detail.story!.trim(),
                onOpenLink: onOpenLink,
              ),
            ),
          if (hasOrganizerSection || hasLocation)
            _OrganizerSection(
              detail: detail,
              hasOrganizerBio: hasOrganizerBio,
              hasOrganizerAvatar: hasOrganizerAvatar,
              hasLocation: hasLocation,
              onOpenLink: onOpenLink,
            ),
          if (hasVideo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _VideoSection(videoUrl: detail.videoUrl!, onOpenLink: onOpenLink),
            ),
          if (detail.rewards.isNotEmpty)
            _RewardsSection(rewards: detail.rewards),
          if (detail.updates.isNotEmpty)
            _UpdatesSection(updates: detail.updates),
          if (detail.evidences.isNotEmpty)
            _EvidenceSection(
              evidences: detail.evidences,
              onEvidenceTap: onEvidenceTap,
            ),
          _CommentsSection(
            comments: comments,
            canComment: canComment,
            commentController: commentController,
            onSubmitComment: onSubmitComment,
            isSubmittingComment: isSubmittingComment,
            highlightCommentId: highlightCommentId,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CoverHeader extends StatelessWidget {
  const _CoverHeader({required this.summary});

  final CampaignSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasImage = summary.coverUrl.isNotEmpty;
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: hasImage
              ? Image.network(
                  summary.coverUrl,
                  fit: BoxFit.cover,
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.bluePrimary.withValues(alpha: 0.1),
                        AppColors.blueSecondary.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_rounded,
                      color: AppColors.blueSecondary,
                      size: 80,
                    ),
                  ),
                ),
        ),
        // Gradiente oscuro inferior para legibilidad
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        // Badge de categoría (más grande)
        Positioned(
          right: AppColors.space16,
          top: AppColors.space16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.space20,
              vertical: AppColors.space12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              boxShadow: AppColors.shadowMd,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.category_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: AppColors.space8),
                Text(
                  summary.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryStats extends StatelessWidget {
  const _SummaryStats({
    required this.detail,
    required this.canSupport,
    this.onSupportTap,
    this.highlightDonation = false,
  });

  final CampaignDetail detail;
  final bool canSupport;
  final VoidCallback? onSupportTap;
  final bool highlightDonation;

  CampaignSummary get summary => detail.summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🎯 Banner de notificación de donación
        if (highlightDonation) ...[
          HighlightWrapper(
            shouldHighlight: true,
            highlightColor: const Color(0xFF4CAF50),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.volunteer_activism_rounded,
                    color: const Color(0xFF4CAF50),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Donación recibida!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E7D32),
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tu generosidad está haciendo la diferencia',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF2E7D32).withOpacity(0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          summary.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
        ),
        if (summary.organizerName != null && summary.organizerName!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Organizado por ${summary.organizerName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.65),
                ),
          ),
        ],
        const SizedBox(height: AppColors.space20),
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            boxShadow: AppColors.shadowLg,
            border: Border.all(
              color: AppColors.bluePrimary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(AppColors.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de progreso con label embebido
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppColors.radiusRound),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bluePrimary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppColors.radiusRound),
                      child: LinearProgressIndicator(
                        value: summary.normalizedProgress,
                        minHeight: 16,
                        color: AppColors.bluePrimary,
                        backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '${summary.completionPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: summary.normalizedProgress > 0.3 
                              ? Colors.white 
                              : AppColors.bluePrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          shadows: summary.normalizedProgress > 0.3
                              ? [
                                  const Shadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppColors.space20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = AppColors.space12;
                  int columns;
                  if (constraints.maxWidth >= 520) {
                    columns = 4;
                  } else if (constraints.maxWidth >= 380) {
                    columns = 3;
                  } else {
                    columns = 2;
                  }
                  final itemWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _StatBlock(
                          icon: Icons.savings_outlined,
                          label: 'Recaudado',
                          value: _formatCurrency(summary.raisedAmount),
                          isPrimary: true,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _StatBlock(
                          icon: Icons.flag_outlined,
                          label: 'Meta',
                          value: _formatCurrency(summary.goalAmount),
                          isPrimary: true,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _StatBlock(
                          icon: Icons.groups_rounded,
                          label: 'Donadores',
                          value: '${summary.donorCount}',
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _StatBlock(
                          icon: Icons.trending_up_rounded,
                          label: 'Progreso',
                          value: '${summary.completionPercentage.toStringAsFixed(0)}%',
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (canSupport && onSupportTap != null) ...[
                const SizedBox(height: AppColors.space24),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.successGradient,
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenHope.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onSupportTap,
                      icon: const Icon(Icons.volunteer_activism_rounded, size: 22),
                      label: const Text(
                        'Apoyar ahora',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppColors.space16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusMd),
                        ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space24,
        vertical: AppColors.space8,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppColors.space24),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          boxShadow: AppColors.shadowMd,
          border: Border.all(
            color: AppColors.dividerColor,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: AppColors.space16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.icon,
    this.isPrimary = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final iconSize = isPrimary ? 22.0 : 18.0;
    final iconColor = isPrimary ? AppColors.greenHope : AppColors.bluePrimary;
    final bgColor = isPrimary 
        ? AppColors.greenHope.withValues(alpha: 0.12)
        : AppColors.bluePrimary.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space16,
        vertical: AppColors.space12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isPrimary 
              ? AppColors.greenHope.withValues(alpha: 0.3)
              : AppColors.dividerColor.withValues(alpha: 0.65),
          width: isPrimary ? 1.5 : 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                  letterSpacing: -0.2,
                  fontSize: isPrimary ? 17 : null,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _CreatorProfile extends StatelessWidget {
  const _CreatorProfile({
    required this.name,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl?.trim().isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
            child: hasAvatar
                ? null
                : const Icon(
                    Icons.person_rounded,
                    color: AppColors.bluePrimary,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Organizador',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.6),
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

