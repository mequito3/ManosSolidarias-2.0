import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Resuelve nombres de lugares ("Plaza Principal de San Pedro, Sacaba") a
/// coordenadas usando la API pública de Nominatim (OpenStreetMap).
///
/// Reglas de uso de Nominatim:
/// - Máximo 1 request/segundo desde la misma IP.
/// - User-Agent identificable obligatorio.
/// - Sin API key, sin costo.
///
/// Cachea resultados en memoria por la duración del proceso para evitar
/// pegar la API repetidas veces sobre el mismo query.
class LocationGeocoder {
  LocationGeocoder({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, LatLng?> _cache = {};
  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const _userAgent =
      'ManosSolidarias/1.0 (https://manos-solidarias.bo; contacto@manos.bo)';
  static const _minIntervalMs = 1100;

  /// Busca coordenadas para [query]. Devuelve null si no encuentra match o
  /// si la red falla. Resultados cacheados en memoria.
  ///
  /// Si el query completo no resuelve (ej. "Casa de Cultura, Cliza"),
  /// reintenta con la última parte tras la primera coma + ", Bolivia" como
  /// fallback de ciudad/región. Funciona bien con el formato típico de
  /// kermesses bolivianas.
  Future<LatLng?> geocode(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return null;

    if (_cache.containsKey(normalized)) {
      return _cache[normalized];
    }

    final candidates = _buildCandidates(normalized);
    for (final candidate in candidates) {
      final result = await _queryNominatim(candidate);
      if (result != null) {
        _cache[normalized] = result;
        return result;
      }
    }

    _cache[normalized] = null;
    return null;
  }

  /// Genera variantes del query para mejorar el hit rate de Nominatim:
  /// 1. El query completo tal cual lo escribió el organizador.
  /// 2. La parte después de la primera coma (suele ser la ciudad) + ", Bolivia".
  /// 3. La última palabra significativa + ", Bolivia" (último recurso).
  List<String> _buildCandidates(String raw) {
    final candidates = <String>[raw];

    // Cortar paréntesis: "Plaza Principal (cerramos 2 cuadras)" → "Plaza Principal"
    final withoutParens = raw.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    if (withoutParens != raw && withoutParens.isNotEmpty) {
      candidates.add(withoutParens);
    }

    final parts = withoutParens
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      // Ciudad probable después de la primera coma.
      final cityCandidate = parts.sublist(1).join(', ');
      candidates.add('$cityCandidate, Bolivia');
      // Solo la última parte (suele ser la ciudad/provincia más amplia).
      candidates.add('${parts.last}, Bolivia');
    }

    // Deduplicar manteniendo orden.
    final seen = <String>{};
    return candidates.where((c) => seen.add(c.toLowerCase())).toList();
  }

  Future<LatLng?> _queryNominatim(String query) async {
    await _respectRateLimit();

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'json',
          'limit': '1',
          'addressdetails': '0',
        },
      );

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
          'Accept-Language': 'es',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint(
            'LocationGeocoder: HTTP ${response.statusCode} para "$query"');
        return null;
      }

      final body = json.decode(response.body);
      if (body is! List || body.isEmpty) return null;

      final first = body.first;
      if (first is! Map) return null;

      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;

      return LatLng(lat, lon);
    } catch (error, stack) {
      debugPrint('LocationGeocoder._queryNominatim error: $error');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  Future<void> _respectRateLimit() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequestAt).inMilliseconds;
    if (elapsed < _minIntervalMs) {
      await Future.delayed(Duration(milliseconds: _minIntervalMs - elapsed));
    }
    _lastRequestAt = DateTime.now();
  }
}

/// Singleton convenience instance reusada en toda la app durante la sesión
/// para maximizar el hit rate del cache.
final LocationGeocoder kermesseLocationGeocoder = LocationGeocoder();
