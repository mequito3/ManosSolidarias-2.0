import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';

/// Strip de patrocinadores ("Con el respaldo de").
/// Discreto, profesional. Logos con colores de marca pero subordinados al diseño.
/// Genera ingresos via RSE corporativa, modelo defendible para tesis.
class SponsorStrip extends StatelessWidget {
  const SponsorStrip({super.key, this.onSponsorTap});

  /// Callback opcional cuando se toca un sponsor.
  final ValueChanged<SponsorEntry>? onSponsorTap;

  // En producción esto vendría de Supabase (tabla `sponsors`).
  // Por ahora datos demo defendibles para tesis: empresas ficticias bolivianas.
  static final List<SponsorEntry> _demoSponsors = [
    SponsorEntry(
      name: 'Banco Andino',
      tagline: 'Banca solidaria',
      color: Color(0xFFC8102E),
    ),
    SponsorEntry(
      name: 'ConectaBolivia',
      tagline: 'Telecom',
      color: Color(0xFF0066CC),
    ),
    SponsorEntry(
      name: 'Industria Valle',
      tagline: 'Manufactura local',
      color: Color(0xFFE67E22),
    ),
    SponsorEntry(
      name: 'Cooperativa Sucre',
      tagline: 'Ahorro y crédito',
      color: Color(0xFF27AE60),
    ),
    SponsorEntry(
      name: 'Fundación Cima',
      tagline: 'Apoyo social',
      color: Color(0xFF6C5CE7),
    ),
    SponsorEntry(
      name: 'EcoSolidaria',
      tagline: 'Sustentabilidad',
      color: Color(0xFF008B8B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Row(
              children: [
                Text(
                  'CON EL RESPALDO DE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText.withValues(alpha: 0.45),
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.dividerColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              physics: const BouncingScrollPhysics(),
              itemCount: _demoSponsors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final sponsor = _demoSponsors[index];
                return _SponsorChip(
                  sponsor: sponsor,
                  onTap: onSponsorTap == null
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onSponsorTap!(sponsor);
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsorChip extends StatelessWidget {
  const _SponsorChip({required this.sponsor, this.onTap});

  final SponsorEntry sponsor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sponsor.color.withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Logo" simulado: círculo de color con inicial
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: sponsor.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    sponsor.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sponsor.name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    sponsor.tagline,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.darkText.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entrada de un patrocinador para el strip.
class SponsorEntry {
  const SponsorEntry({
    required this.name,
    required this.tagline,
    required this.color,
  });

  final String name;
  final String tagline;
  final Color color;

  /// Iniciales generadas a partir del nombre (max 2 caracteres).
  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts[0];
      return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
