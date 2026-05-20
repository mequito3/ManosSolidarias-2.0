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
    required this.userProfile,
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
  final UserProfile userProfile;
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
            const SizedBox(height: 44),
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
            userProfile: userProfile,
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
              ? AppNetworkImage(
                  url: summary.coverUrl,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: AppColors.bluePrimary.withValues(alpha: 0.06),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.bluePrimary,
                      ),
                    ),
                  ),
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
                ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.30),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 14,
          top: MediaQuery.of(context).padding.top + 64,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              summary.category.toUpperCase(),
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                letterSpacing: 0.8,
              ),
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
    final progressColor = _barColor(summary.completionPercentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (highlightDonation) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greenSuccess.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.greenSuccess.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.greenSuccess.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.greenSuccess,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Donación recibida. Gracias por aportar.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Status row · sin íconos, solo texto sobrio
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: summary.isCompleted
                    ? AppColors.greenSuccess.withValues(alpha: 0.10)
                    : AppColors.bluePrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                summary.isCompleted ? 'Completada' : 'Activa',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: summary.isCompleted
                      ? AppColors.greenSuccess
                      : AppColors.bluePrimary,
                ),
              ),
            ),
            if (!summary.isCompleted && summary.endDate != null) ...[
              const SizedBox(width: 8),
              _DaysChip(endDate: summary.endDate!),
            ],
          ],
        ),
        const SizedBox(height: 18),

        // Card de progreso · estilo GoFundMe emocional
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monto recaudado · número HUGE
              Text(
                _formatCurrency(summary.raisedAmount),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                  letterSpacing: -1.2,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                summary.donorCount == 0
                    ? 'recaudados hasta ahora'
                    : 'recaudados gracias a ${summary.donorCount} ${summary.donorCount == 1 ? "persona" : "personas"}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkText.withValues(alpha: 0.55),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 24),

              // Progress bar con hitos
              _MilestoneProgressBar(
                progress: summary.normalizedProgress,
                color: progressColor,
              ),

              const SizedBox(height: 18),

              // Meta + faltante
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'META',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppColors.darkText.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(summary.goalAmount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!summary.isCompleted &&
                      summary.raisedAmount < summary.goalAmount)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'FALTAN',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppColors.darkText.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(
                              summary.goalAmount - summary.raisedAmount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: progressColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
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
      color = AppColors.darkText.withValues(alpha: 0.5);
      label = 'Finalizada';
    } else if (days == 0) {
      color = AppColors.error;
      label = 'Último día';
    } else if (days == 1) {
      color = AppColors.orangeAction;
      label = 'Termina mañana';
    } else if (days <= 7) {
      color = AppColors.orangeAction;
      label = '$days días restantes';
    } else {
      color = AppColors.darkText.withValues(alpha: 0.55);
      label = '$days días restantes';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
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
  // `icon` se mantiene por compatibilidad con las invocaciones existentes
  // pero ya no se renderiza — la jerarquía es solo tipográfica + barra de acento.
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.bluePrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space24,
        vertical: AppColors.space8,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppColors.space24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: barra vertical de acento + título grande sin ícono
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                        letterSpacing: -0.4,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.space20),
            child,
          ],
        ),
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

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl?.trim().isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.10),
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
            child: hasAvatar
                ? null
                : Text(
                    _initial,
                    style: const TextStyle(
                      color: AppColors.bluePrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
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
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    letterSpacing: -0.1,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Organizador',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText.withValues(alpha: 0.5),
                    letterSpacing: 0.3,
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

/// Barra de progreso con hitos visibles (25/50/75/100%).
/// Cada hito alcanzado se muestra como diamante relleno; los no alcanzados
/// como diamante vacío. Inspirado en GoFundMe / Patreon.
class _MilestoneProgressBar extends StatelessWidget {
  const _MilestoneProgressBar({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  static const _milestones = [0.25, 0.50, 0.75, 1.0];

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final bgColor = AppColors.darkText.withValues(alpha: 0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra base + barra de progreso + diamantes superpuestos.
        // Uso `Align(alignment: Alignment(2m - 1, 0))` para que en m=1.0 el
        // diamante quede con su lado derecho pegado al borde, sin desbordar.
        SizedBox(
          height: 18,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // Track base
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: clamped,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              // Hitos — Align maneja los bordes automáticamente
              for (final m in _milestones)
                Align(
                  alignment: Alignment(2 * m - 1, 0),
                  child: _MilestoneDiamond(
                    reached: clamped >= m,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Labels de hitos — mismo patrón Align para no cortar el "100%"
        SizedBox(
          height: 14,
          child: Stack(
            children: [
              for (final m in _milestones)
                Align(
                  alignment: Alignment(2 * m - 1, 0),
                  child: Text(
                    '${(m * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          clamped >= m ? FontWeight.w800 : FontWeight.w600,
                      color: clamped >= m
                          ? color
                          : AppColors.darkText.withValues(alpha: 0.4),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MilestoneDiamond extends StatelessWidget {
  const _MilestoneDiamond({required this.reached, required this.color});

  final bool reached;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398, // 45 grados
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: reached ? color : Colors.white,
          border: Border.all(
            color: reached ? color : AppColors.darkText.withValues(alpha: 0.25),
            width: reached ? 0 : 2,
          ),
          borderRadius: BorderRadius.circular(2),
          boxShadow: reached
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

