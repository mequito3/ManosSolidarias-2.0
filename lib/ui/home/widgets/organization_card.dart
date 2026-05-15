import 'package:flutter/material.dart';

import '../../../models/organization.dart';
import '../../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrganizationHighlightCard — Featured card: bold gradient header + clean body
// ─────────────────────────────────────────────────────────────────────────────

class OrganizationHighlightCard extends StatefulWidget {
  const OrganizationHighlightCard({
    super.key,
    required this.organization,
    this.onTap,
  });

  final OrganizationSummary organization;
  final VoidCallback? onTap;

  @override
  State<OrganizationHighlightCard> createState() =>
      _OrganizationHighlightCardState();
}

class _OrganizationHighlightCardState
    extends State<OrganizationHighlightCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasDescription = widget.organization.description != null &&
        widget.organization.description!.isNotEmpty;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 272,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banda gradient sutil 4px (acento de marca, no fondo)
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.bluePrimary,
                        AppColors.blueSecondary,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo + verified badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.bluePrimary
                                      .withValues(alpha: 0.10),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.bluePrimary
                                        .withValues(alpha: 0.10),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: _OrgLogoSquare(
                                  url: widget.organization.logoUrl,
                                  size: 64,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (widget.organization.isVerified)
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.bluePrimary
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.bluePrimary,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Type pill
                        if (widget.organization.type != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bluePrimary
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.domain_rounded,
                                  size: 11,
                                  color: AppColors.bluePrimary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.organization.type!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.bluePrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Name
                        Text(
                          widget.organization.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (hasDescription) ...[
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              widget.organization.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.darkText
                                    .withValues(alpha: 0.62),
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        // Footer link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Ver detalles',
                              style: TextStyle(
                                color: AppColors.bluePrimary
                                    .withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.bluePrimary
                                  .withValues(alpha: 0.85),
                            ),
                          ],
                        ),
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

/// Logo cuadrado para usar dentro del card (con fallback). El borde y shadow
/// los maneja el container exterior — este widget solo renderiza la imagen
/// o el fallback con relleno azul tinted.
class _OrgLogoSquare extends StatelessWidget {
  const _OrgLogoSquare({required this.url, this.size = 64});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      color: AppColors.bluePrimary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.business_rounded,
          color: AppColors.bluePrimary.withValues(alpha: 0.55),
          size: size * 0.42,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OrganizationRecentCard — New org card: gradient top strip + clean layout
// ─────────────────────────────────────────────────────────────────────────────

class OrganizationRecentCard extends StatefulWidget {
  const OrganizationRecentCard({
    super.key,
    required this.organization,
    this.onTap,
  });

  final OrganizationSummary organization;
  final VoidCallback? onTap;

  @override
  State<OrganizationRecentCard> createState() => _OrganizationRecentCardState();
}

class _OrganizationRecentCardState extends State<OrganizationRecentCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Gradient hero header ─────────────────────
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.greenSuccess, AppColors.greenHope],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: _OrgLogoBadge(
                          url: widget.organization.logoUrl,
                          size: 52,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.93),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fiber_new_rounded,
                                  color: AppColors.greenSuccess, size: 12),
                              SizedBox(width: 3),
                              Text(
                                'Nuevo',
                                style: TextStyle(
                                  color: AppColors.greenSuccess,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Organization name
                      Text(
                        widget.organization.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Type
                      if (widget.organization.type != null)
                        Text(
                          widget.organization.type!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.darkText.withValues(alpha: 0.52),
                            fontSize: 11,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Footer CTA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ver organización',
                            style: TextStyle(
                              color: AppColors.greenSuccess
                                  .withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color:
                                AppColors.greenSuccess.withValues(alpha: 0.7),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OrganizationCompactTile — List tile: colored accent bar + logo + text
// ─────────────────────────────────────────────────────────────────────────────

class OrganizationCompactTile extends StatefulWidget {
  const OrganizationCompactTile({
    super.key,
    required this.organization,
    this.onTap,
    this.trailing,
    this.index = 0,
  });

  final OrganizationSummary organization;
  final VoidCallback? onTap;
  final Widget? trailing;
  final int index;

  @override
  State<OrganizationCompactTile> createState() =>
      _OrganizationCompactTileState();
}

class _OrganizationCompactTileState extends State<OrganizationCompactTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
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
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Logo 60×60
                _OrgLogoBadge(url: widget.organization.logoUrl, size: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.organization.type != null) ...[
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.bluePrimary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  widget.organization.type!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.bluePrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (widget.organization.isVerified)
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.bluePrimary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.organization.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.darkText,
                          height: 1.3,
                        ),
                      ),
                      if (widget.organization.hasAddress ||
                          widget.organization.hasWebsite) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 11,
                                color: AppColors.darkText
                                    .withValues(alpha: 0.45)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                widget.organization.hasAddress
                                    ? 'Dirección disponible'
                                    : 'Sitio web disponible',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkText
                                      .withValues(alpha: 0.55),
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
                const SizedBox(width: 8),
                widget.trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.darkText.withValues(alpha: 0.3),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Square logo with rounded corners — shows real logo or branded fallback.
class _OrgLogoBadge extends StatelessWidget {
  const _OrgLogoBadge({required this.url, this.size = 60});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size / 5;
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(radius),
        ),
      );
    }
    return _fallback(radius);
  }

  Widget _fallback(double radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.business_rounded,
          color: AppColors.bluePrimary,
          size: size * 0.42,
        ),
      ),
    );
  }
}

