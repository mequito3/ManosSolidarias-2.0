import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Listas de detalle de kermés compartidas entre el detalle público
/// (usuario normal) y la hoja de revisión del admin, para que se vean igual.

/// Lista de actividades con viñeta de check (naranja).
class CheckList extends StatelessWidget {
  const CheckList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.orangeAction.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.orangeAction,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.darkText.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Lista de menú: nombre a la izquierda + precio destacado a la derecha.
/// Soporta dos formatos de entrada:
///   - Detalle público: "Nombre: Bs 35"
///   - Solicitud/admin: "Nombre — 35 Bs" / "Nombre — Bs 35"
class PricedList extends StatelessWidget {
  const PricedList({super.key, required this.items});

  final List<String> items;

  ({String name, String? price}) _parse(String raw) {
    final text = raw.trim();

    // Formato del detalle público: "Nombre: Bs 35"
    final lastColon = text.lastIndexOf(':');
    if (lastColon != -1 && lastColon != text.length - 1) {
      final afterColon = text.substring(lastColon + 1).trim();
      final match =
          RegExp(r'^Bs\.?\s*([0-9][0-9.,]*)\s*$', caseSensitive: false)
              .firstMatch(afterColon);
      if (match != null) {
        return (
          name: text.substring(0, lastColon).trim(),
          price: 'Bs ${match.group(1)!}',
        );
      }
    }

    // Formato del admin/solicitud: "Nombre — 35 Bs" / "Nombre — Bs 35"
    final dashMatch = RegExp(r'^(.*?)\s*[—–]\s*(.+)$').firstMatch(text);
    if (dashMatch != null) {
      final priceRaw = dashMatch.group(2)!.trim();
      final amount = RegExp(r'([0-9][0-9.,]*)').firstMatch(priceRaw);
      if (amount != null) {
        final paren = RegExp(r'\(([^)]*)\)').firstMatch(priceRaw);
        final price = paren != null
            ? 'Bs ${amount.group(1)!} (${paren.group(1)})'
            : 'Bs ${amount.group(1)!}';
        return (name: dashMatch.group(1)!.trim(), price: price);
      }
    }

    return (name: text, price: null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((raw) {
        final parsed = _parse(raw);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.orangeAction.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: AppColors.orangeAction,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  parsed.name,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.darkText.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (parsed.price != null) ...[
                const SizedBox(width: 12),
                Text(
                  parsed.price!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.orangeAction,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Lista de shows/música con viñeta de nota musical (azul).
class MusicList extends StatelessWidget {
  const MusicList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      size: 13,
                      color: AppColors.bluePrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.darkText.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
