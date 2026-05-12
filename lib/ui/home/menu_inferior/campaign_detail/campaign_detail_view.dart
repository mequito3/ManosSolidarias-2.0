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
          Stack(
            clipBehavior: Clip.none,
            children: [
              _CoverHeader(summary: summary),
              Positioned(
                left: 0,
                right: 0,
                bottom: -34,
                child: _CreatorProfile(
                  name: detail.creatorName ?? 'Organizador',
                  avatarUrl: detail.creatorAvatarUrl,
                ),
              ),
            ],
          ),
          ...[
            const SizedBox(height: 46),
          // Título de la campaña — visible y nunca tapado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              summary.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
                height: 1.25,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
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
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.bluePrimary,
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
              icon: Icons.lightbulb_rounded,
              iconColor: AppColors.orangeAction,
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
          ].animate(interval: 50.ms).fade(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutQuad),
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
        Hero(
          tag: 'campaign_cover_${summary.id}',
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              height: 260,
              width: double.infinity,
              child: hasImage
              ? Image.network(
                  summary.coverUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppColors.bluePrimary.withValues(alpha: 0.06),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.bluePrimary,
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.bluePrimary.withValues(alpha: 0.18),
                        AppColors.blueSecondary.withValues(alpha: 0.28),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      color: AppColors.blueSecondary,
                      size: 72,
                    ),
                  ),
                ),
            ),
          ),
        ),
        // Gradiente decorativo inferior (sin título — queda abajo del creador)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),
        // Badge de categoría
        Positioned(
          right: AppColors.space12,
          top: AppColors.space12,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              boxShadow: [
                BoxShadow(
                  color: AppColors.bluePrimary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.category_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  summary.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.3,
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

  Color _barColor(double pct) {
    if (pct >= 80) return AppColors.greenSuccess;
    if (pct >= 40) return AppColors.bluePrimary;
    return AppColors.orangeAction;
  }

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
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
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
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.8),
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
        // Status & organizer row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: summary.isCompleted
                    ? AppColors.greenHope.withValues(alpha: 0.12)
                    : AppColors.bluePrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppColors.radiusRound),
                border: Border.all(
                  color: summary.isCompleted
                      ? AppColors.greenHope.withValues(alpha: 0.4)
                      : AppColors.bluePrimary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    summary.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.campaign_rounded,
                    size: 12,
                    color: summary.isCompleted
                        ? AppColors.greenHope
                        : AppColors.bluePrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    summary.isCompleted ? 'Completada' : 'Activa',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: summary.isCompleted
                          ? AppColors.greenHope
                          : AppColors.bluePrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (!summary.isCompleted && summary.endDate != null) ...[const SizedBox(width: 8), _DaysChip(endDate: summary.endDate!)],
            if (summary.organizerName != null && summary.organizerName!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'por ${summary.organizerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppColors.space16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso de la meta',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '${summary.completionPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _barColor(summary.completionPercentage),
                    ),
                  ).animate().fade().scale(curve: Curves.easeOutBack, duration: 600.ms),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppColors.radiusRound),
                  boxShadow: [
                    BoxShadow(
                      color: _barColor(summary.completionPercentage).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppColors.radiusRound),
                  child: LinearProgressIndicator(
                    value: summary.normalizedProgress,
                    minHeight: 12,
                    color: _barColor(summary.completionPercentage),
                    backgroundColor: _barColor(summary.completionPercentage).withValues(alpha: 0.15),
                  ).animate().custom(
                    duration: 1200.ms,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: summary.normalizedProgress * value,
                        minHeight: 12,
                        color: _barColor(summary.completionPercentage),
                        backgroundColor: _barColor(summary.completionPercentage).withValues(alpha: 0.15),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!summary.isCompleted && summary.raisedAmount < summary.goalAmount)
                Text(
                  'Faltan ${_formatCurrency(summary.goalAmount - summary.raisedAmount)} para alcanzar la meta',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _barColor(summary.completionPercentage),
                  ),
                ),
              const SizedBox(height: AppColors.space16),
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
                          label: 'Aporte prom.',
                          value: summary.donorCount > 0
                              ? _formatCurrency(
                                  summary.raisedAmount / summary.donorCount)
                              : '—',
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
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scaleXY(begin: 1.0, end: 1.02, duration: 2.seconds, curve: Curves.easeInOut)
                 .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.2)),
              ],
            ],
          ),
        ),
      ],
    );
  }

}

class _DaysChip extends StatelessWidget {
  const _DaysChip({required this.endDate});
  final DateTime endDate;

  @override
  Widget build(BuildContext context) {
    final days = endDate.difference(DateTime.now()).inDays;
    final Color color;
    final String label;
    if (days < 0) {
      color = AppColors.grayNeutral;
      label = 'Finalizado';
    } else if (days == 0) {
      color = AppColors.error;
      label = '\u23f0 Último día';
    } else if (days <= 7) {
      color = AppColors.orangeAction;
      label = '\u23f3 $days días';
    } else {
      color = AppColors.bluePrimary;
      label = '\ud83d\udcc5 $days días';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? AppColors.bluePrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space24,
        vertical: AppColors.space8,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppColors.space24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.bluePrimary.withValues(alpha: 0.05),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: c, size: 17),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                  ),
                ),
              ],
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
        color: isPrimary 
            ? AppColors.greenHope.withValues(alpha: 0.05)
            : AppColors.bluePrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.bluePrimary.withValues(alpha: 0.25),
                width: 2.5,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
              child: hasAvatar
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.bluePrimary,
                      size: 26,
                    ),
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

