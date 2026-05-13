import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../../models/campaign.dart';
import '../../../theme/app_colors.dart';

// ─── Helpers compartidos por las 3 variantes de card ──────────────
String _thousandSep(int value) {
  final isNegative = value < 0;
  final str = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return isNegative ? '-${buf.toString()}' : buf.toString();
}

String _formatBs(double value) {
  if (value >= 1000000) return 'Bs ${(value / 1000000).toStringAsFixed(1)}M';
  return 'Bs ${_thousandSep(value.round())}';
}

Widget _imageShimmer({double? width, double? height}) {
  return Shimmer.fromColors(
    baseColor: AppColors.bluePrimary.withValues(alpha: 0.06),
    highlightColor: AppColors.bluePrimary.withValues(alpha: 0.14),
    child: Container(
      width: width,
      height: height,
      color: Colors.white,
    ),
  );
}

// ────────────────────────────────────────────────────────────
//  Card principal
// ────────────────────────────────────────────────────────────
class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
    this.onSupport,
    this.onToggleFavorite,
    this.showSupportButton = true,
    this.heroTagPrefix,
  });

  final CampaignSummary campaign;
  final VoidCallback? onTap;
  final VoidCallback? onSupport;
  final VoidCallback? onToggleFavorite;
  final bool showSupportButton;
  final String? heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    final shouldShowSupportButton = showSupportButton && !campaign.isCompleted;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              _CampaignHeroImage(
                campaignId: campaign.id,
                heroTagPrefix: heroTagPrefix,
                imageUrl: campaign.coverUrl,
                title: campaign.title,
                organizerName: campaign.publicOrganizerName?.isNotEmpty == true
                    ? campaign.publicOrganizerName
                    : null,
                isAnonymous: campaign.isAnonymous,
                category:
                    campaign.category.isNotEmpty ? campaign.category : 'Campaña',
                isCompleted: campaign.isCompleted,
                isVerified: campaign.isVerified,
                isFavorite: campaign.isFavorite,
                onToggleFavorite: onToggleFavorite,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
                child: Text(
                  campaign.shortDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.darkText.withValues(alpha: 0.68),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: campaign.normalizedProgress,
                          color: _progressColor(campaign.completionPercentage),
                          backgroundColor:
                              _progressColor(campaign.completionPercentage)
                                  .withValues(alpha: 0.12),
                          minHeight: 7,
                        ).animate().custom(
                          duration: 800.ms,
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: (campaign.normalizedProgress * value),
                              color: _progressColor(campaign.completionPercentage),
                              backgroundColor:
                                  _progressColor(campaign.completionPercentage)
                                      .withValues(alpha: 0.12),
                              minHeight: 7,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${campaign.completionPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: _progressColor(campaign.completionPercentage),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _StatColumn(
                        label: 'Recaudado',
                        value: _formatCurrency(campaign.raisedAmount),
                        color: AppColors.bluePrimary,
                        align: CrossAxisAlignment.start,
                      ),
                      const _StatDivider(),
                      _StatColumn(
                        label: 'Meta',
                        value: _formatCurrency(campaign.goalAmount),
                        color: AppColors.darkText,
                        align: CrossAxisAlignment.center,
                      ),
                      const _StatDivider(),
                      _StatColumn(
                        label: 'Donadores',
                        value: '${campaign.donorCount}',
                        color: AppColors.orangeAction,
                        align: CrossAxisAlignment.end,
                        icon: Icons.people_alt_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              if (shouldShowSupportButton) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _SupportButton(onPressed: onSupport),
                ),
              ] else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  Color _progressColor(double pct) {
    if (pct >= 80) return AppColors.greenSuccess;
    if (pct >= 40) return AppColors.bluePrimary;
    return AppColors.orangeAction;
  }

  String _formatCurrency(double value) => _formatBs(value);
}

// ────────────────────────────────────────────────────────────
//  Hero image con título superpuesto
// ────────────────────────────────────────────────────────────
class _CampaignHeroImage extends StatelessWidget {
  const _CampaignHeroImage({
    required this.campaignId,
    this.heroTagPrefix,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.isCompleted,
    required this.isVerified,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.organizerName,
    this.isAnonymous = false,
  });

  final String campaignId;
  final String? heroTagPrefix;
  final String imageUrl;
  final String title;
  final String category;
  final String? organizerName;
  final bool isCompleted;
  final bool isVerified;
  final bool isFavorite;
  final bool isAnonymous;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Hero(
        tag: heroTagPrefix != null ? '${heroTagPrefix}_campaign_$campaignId' : 'campaign_cover_$campaignId',
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            height: 200,
            width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),
            // Gradiente inferior
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            // Título + organizer
            Positioned(
              left: 14,
              right: 54,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.25,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                  if (organizerName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isAnonymous
                              ? Icons.lock_rounded
                              : Icons.person_rounded,
                          size: 11,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Por $organizerName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Categoría (top-left)
            Positioned(
              top: 12,
              left: 12,
              child: _CategoryChip(label: isCompleted ? 'Meta alcanzada' : category,
                  color: isCompleted ? AppColors.greenSuccess : null),
            ),
            // Verified (top-right solo si no hay favorito encima)
            if (isVerified)
              Positioned(
                top: 12,
                right: 52,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: AppColors.bluePrimary, size: 15),
                ),
              ),
            // Favorito (top-right)
            Positioned(
              top: 10,
              right: 10,
              child: _FavoriteButton(
                  isFavorite: isFavorite, onPressed: onToggleFavorite),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bluePrimary.withValues(alpha: 0.22),
              AppColors.blueSecondary.withValues(alpha: 0.32),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.volunteer_activism_rounded,
              color: AppColors.blueSecondary, size: 60),
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _imageShimmer();
      },
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.error.withValues(alpha: 0.1),
            AppColors.error.withValues(alpha: 0.05),
          ]),
        ),
        child: const Center(
            child: Icon(Icons.broken_image_rounded,
                size: 52, color: AppColors.error)),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Widgets compartidos
// ────────────────────────────────────────────────────────────
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onPressed});
  final bool isFavorite;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onPressed!();
            },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isFavorite ? AppColors.orangeAction : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFavorite ? Colors.white : AppColors.orangeAction,
          size: 18,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.bluePrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color != null ? c.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.14), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            color != null ? Icons.check_circle_rounded : Icons.sell_rounded,
            size: 11,
            color: color != null ? Colors.white : c,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color != null ? Colors.white : c,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.align,
    this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment align;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ma = align == CrossAxisAlignment.end
        ? MainAxisAlignment.end
        : align == CrossAxisAlignment.center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start;
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.darkText.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: ma,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.dividerColor,
    );
  }
}

class _SupportButton extends StatefulWidget {
  const _SupportButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  State<_SupportButton> createState() => _SupportButtonState();
}

class _SupportButtonState extends State<_SupportButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    return Listener(
      onPointerDown: isEnabled ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.actionGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: AppColors.orangeAction.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: isEnabled
                  ? () {
                      HapticFeedback.mediumImpact();
                      widget.onPressed!();
                    }
                  : null,
              icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
              label: const Text('Apoyar esta causa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Tile "Cerca de la meta"
// ────────────────────────────────────────────────────────────
class CampaignProgressTile extends StatelessWidget {
  const CampaignProgressTile({
    super.key,
    required this.campaign,
    this.onTap,
    this.onSupport,
    this.onToggleFavorite,
  });

  final CampaignSummary campaign;
  final VoidCallback? onTap;
  final VoidCallback? onSupport;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final pct = campaign.completionPercentage;
    final barColor = pct >= 80 ? AppColors.greenSuccess : AppColors.bluePrimary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: campaign.coverUrl.isEmpty
                      ? Container(
                          color: AppColors.bluePrimary.withValues(alpha: 0.1),
                          child: const Center(
                              child: Icon(Icons.volunteer_activism_rounded,
                                  color: AppColors.bluePrimary, size: 28)),
                        )
                      : Image.network(
                          campaign.coverUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return _imageShimmer(width: 72, height: 72);
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.error.withValues(alpha: 0.08),
                            child: const Icon(Icons.broken_image_rounded,
                                color: AppColors.error, size: 24),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.darkText),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: campaign.normalizedProgress,
                              color: barColor,
                              backgroundColor:
                                  barColor.withValues(alpha: 0.12),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${pct.toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: barColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.savings_rounded,
                            size: 12,
                            color: AppColors.darkText.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(_fmt(campaign.raisedAmount),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText.withValues(alpha: 0.7))),
                        ),
                        const Spacer(),
                        Icon(Icons.people_alt_rounded,
                            size: 12,
                            color: AppColors.darkText.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text('${campaign.donorCount}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText.withValues(alpha: 0.7))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onToggleFavorite,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: campaign.isFavorite
                        ? AppColors.orangeAction.withValues(alpha: 0.12)
                        : AppColors.grayNeutral.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    campaign.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: campaign.isFavorite
                        ? AppColors.orangeAction
                        : AppColors.darkText.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) => _formatBs(v);
}

// ────────────────────────────────────────────────────────────
//  Tile "Recién lanzadas"
// ────────────────────────────────────────────────────────────
class CampaignHeadlineTile extends StatelessWidget {
  const CampaignHeadlineTile({
    super.key,
    required this.campaign,
    this.onTap,
    this.onToggleFavorite,
  });

  final CampaignSummary campaign;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.dividerColor.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: campaign.coverUrl.isEmpty
                      ? Container(
                          color: AppColors.greenSuccess.withValues(alpha: 0.1),
                          child: const Center(
                              child: Icon(Icons.eco_rounded,
                                  color: AppColors.greenSuccess, size: 24)),
                        )
                      : Image.network(
                          campaign.coverUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return _imageShimmer(width: 60, height: 60);
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.error.withValues(alpha: 0.08),
                            child: const Icon(Icons.broken_image_rounded,
                                color: AppColors.error, size: 20),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.greenSuccess.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text('✨ Nueva',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.greenSuccess)),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            campaign.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.darkText.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.darkText,
                          height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onToggleFavorite,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: campaign.isFavorite
                        ? AppColors.orangeAction.withValues(alpha: 0.12)
                        : AppColors.grayNeutral.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    campaign.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: campaign.isFavorite
                        ? AppColors.orangeAction
                        : AppColors.darkText.withValues(alpha: 0.3),
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