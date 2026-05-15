import 'package:flutter/material.dart';

import '../../../models/organization.dart';
import '../../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrganizationHighlightCard — Card horizontal full-width: logo a la izquierda
// + tipo + verified + nombre arriba, descripcion debajo, footer "Ver detalles".
// Disenada para listado vertical (no carrusel).
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
    final org = widget.organization;
    final hasDescription =
        org.description != null && org.description!.isNotEmpty;
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
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top: logo + info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo 72x72 con borde sutil
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
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
                              borderRadius: BorderRadius.circular(15),
                              child: _OrgLogoSquare(
                                url: org.logoUrl,
                                size: 72,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Info column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Type pill + verified inline
                                Row(
                                  children: [
                                    if (org.type != null)
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.bluePrimary
                                                .withValues(alpha: 0.10),
                                            borderRadius:
                                                BorderRadius.circular(6),
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
                                                  org.type!,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.bluePrimary,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (org.type != null && org.isVerified)
                                      const SizedBox(width: 6),
                                    if (org.isVerified)
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: AppColors.bluePrimary,
                                        size: 16,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Nombre
                                Text(
                                  org.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.darkText,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    height: 1.25,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Descripcion (full-width)
                      if (hasDescription) ...[
                        const SizedBox(height: 12),
                        Text(
                          org.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.darkText.withValues(alpha: 0.62),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Footer link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Ver detalles',
                            style: TextStyle(
                              color:
                                  AppColors.bluePrimary.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color:
                                AppColors.bluePrimary.withValues(alpha: 0.85),
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

/// Logo cuadrado para usar dentro de un container con borde/shadow exterior.
/// Renderiza la imagen o un fallback con relleno azul tinted.
class _OrgLogoSquare extends StatelessWidget {
  const _OrgLogoSquare({required this.url, this.size = 72});

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
