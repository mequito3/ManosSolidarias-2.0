import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'location_geocoder.dart';

/// Centraliza cómo se abre la ubicación de una kermesse en mapas externos.
///
/// Lógica priorizada:
/// 1. Si recibimos coords explícitas, abrimos `geo:` (intent nativo) con el
///    label visible en el pin.
/// 2. Sin coords, intentamos resolver el query de texto usando el cache del
///    [LocationGeocoder] — así una row "Lugar" tocada en Info Esencial abre
///    el mismo punto que la sección Ubicación ya geocodificó.
/// 3. Si nada resuelve a coords, fallback a Google Maps web con búsqueda
///    por texto (Google es más tolerante a nombres parciales que OSM).
///
/// El haptic se dispara siempre al inicio para feedback inmediato.
class KermesseMapLauncher {
  KermesseMapLauncher({LocationGeocoder? geocoder})
      : _geocoder = geocoder ?? kermesseLocationGeocoder;

  final LocationGeocoder _geocoder;

  Future<void> open({
    LatLng? point,
    String? query,
    String? label,
  }) async {
    HapticFeedback.selectionClick();

    final cleanQuery = query?.trim();
    var effectivePoint = point;

    if (effectivePoint == null &&
        cleanQuery != null &&
        cleanQuery.isNotEmpty) {
      effectivePoint = await _geocoder.geocode(cleanQuery);
    }

    final fallbackLabel = (label?.trim().isNotEmpty ?? false)
        ? label!.trim()
        : (cleanQuery ?? 'Kermesse solidaria');

    if (effectivePoint != null) {
      final geoUri = Uri.parse(
        'geo:${effectivePoint.latitude},${effectivePoint.longitude}'
        '?q=${effectivePoint.latitude},${effectivePoint.longitude}'
        '(${Uri.encodeComponent(fallbackLabel)})',
      );
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
        return;
      }
      final webUri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query':
            '${effectivePoint.latitude},${effectivePoint.longitude} ($fallbackLabel)',
      });
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (cleanQuery == null || cleanQuery.isEmpty) return;
    final webUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': cleanQuery,
    });
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

final KermesseMapLauncher kermesseMapLauncher = KermesseMapLauncher();
