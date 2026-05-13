import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/campaign.dart';
import '../../../theme/app_colors.dart';

/// Hero protagonista del Home: una sola campaña destacada con foto grande,
/// gradient overlay, badge de urgencia, progreso y CTA.
///
/// Se diferencia visualmente de las cards normales porque ocupa todo el ancho
/// con altura significativa y tiene jerarquia tipografica fuerte.
class FeaturedCampaignHero extends StatelessWidget {
  const FeaturedCampaignHero({
    super.key,
    required this.campaign,
    required this.onTap,
    required this.onSupport,
    required this.onToggleFavorite,
  });

  final CampaignSummary campaign;
  final VoidCallback onTap;
  final VoidCallback onSupport;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final pct = campaign.completionPercentage;
    final pctColor = pct >= 80
        ? AppColors.greenSuccess
        : (pct >= 40 ? AppColors.bluePrimary : AppColors.orangeAction);
    final daysLeft = _daysUntilEnd();
    final isAnonymous = campaign.isAnonymous;
    final organizer = campaign.publicOrganizerName ?? 'Equipo organizador';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.bluePrimary.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── HERO IMAGE con gradient + texto superpuesto ────────────
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Hero(
                  tag: 'featured_hero_${campaign.id}',
                  child: SizedBox(
                    height: 230,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildBackground(),
                        // Gradient inferior fuerte para legibilidad
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0x00000000),
                                Color(0xCC000000),
                              ],
                              stops: [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                        // Badge "Campaña destacada" arriba-izquierda
                        Positioned(
                          top: 14,
                          left: 14,
                          child: _DestacadaBadge(),
                        ),
                        // Favorito arriba-derecha
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _HeroFavoriteButton(
                            isFavorite: campaign.isFavorite,
                            onPressed: onToggleFavorite,
                          ),
                        ),
                        // Texto + chips abajo
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (campaign.category.isNotEmpty)
                                _CategoryPill(label: campaign.category),
                              const SizedBox(height: 10),
                              Text(
                                campaign.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.18,
                                  letterSpacing: -0.4,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    isAnonymous
                                        ? Icons.lock_rounded
                                        : Icons.verified_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      isAnonymous
                                          ? 'Beneficiario anónimo · verificado'
                                          : 'Por $organizer',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.92),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── INFO bloque inferior ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Línea de números
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatBs(campaign.raisedAmount),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: pctColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'recaudados de ${_formatBs(campaign.goalAmount)}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.darkText
                                      .withValues(alpha: 0.55),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: pctColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: pctColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: pctColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress bar grande
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0.0,
                          end: campaign.normalizedProgress,
                        ),
                        duration: const Duration(milliseconds: 1100),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            color: pctColor,
                            backgroundColor:
                                pctColor.withValues(alpha: 0.12),
                            minHeight: 10,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Stats inline (Wrap evita overflow en celulares angostos)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatChip(
                          icon: Icons.people_alt_rounded,
                          label: '${campaign.donorCount} donantes',
                          color: AppColors.bluePrimary,
                        ),
                        if (daysLeft != null)
                          _StatChip(
                            icon: Icons.schedule_rounded,
                            label: _formatDaysLeft(daysLeft),
                            color: daysLeft <= 7
                                ? AppColors.orangeAction
                                : AppColors.darkText.withValues(alpha: 0.65),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CTA fuerte
                    _HeroSupportButton(onPressed: onSupport),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 500.ms).slideY(
          begin: -0.04,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildBackground() {
    if (campaign.coverUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bluePrimary.withValues(alpha: 0.35),
              AppColors.blueSecondary.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.volunteer_activism_rounded,
              color: Colors.white, size: 72),
        ),
      );
    }
    return Image.network(
      campaign.coverUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.bluePrimary.withValues(alpha: 0.1),
        child: const Icon(Icons.broken_image_rounded,
            color: AppColors.error, size: 48),
      ),
    );
  }

  int? _daysUntilEnd() {
    if (campaign.endDate == null) return null;
    final diff = campaign.endDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? null : diff;
  }

  String _formatDaysLeft(int days) {
    if (days == 0) return 'Cierra hoy';
    if (days == 1) return 'Cierra mañana';
    return 'Cierra en $days días';
  }

  String _formatBs(double v) {
    if (v >= 1000000) return 'Bs ${(v / 1000000).toStringAsFixed(1)}M';
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Bs ${buf.toString()}';
  }
}

// ─── Widgets privados auxiliares ─────────────────────────────────────────

class _DestacadaBadge extends StatelessWidget {
  const _DestacadaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orangeAction,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: AppColors.orangeAction.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 13),
          SizedBox(width: 4),
          Text(
            'Destacada',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _HeroFavoriteButton extends StatelessWidget {
  const _HeroFavoriteButton({
    required this.isFavorite,
    required this.onPressed,
  });

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isFavorite ? AppColors.orangeAction : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: isFavorite ? Colors.white : AppColors.orangeAction,
          size: 20,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSupportButton extends StatefulWidget {
  const _HeroSupportButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_HeroSupportButton> createState() => _HeroSupportButtonState();
}

class _HeroSupportButtonState extends State<_HeroSupportButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.actionGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orangeAction.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onPressed();
              },
              icon: const Icon(Icons.volunteer_activism_rounded, size: 20),
              label: const Text(
                'Apoyar esta causa',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
