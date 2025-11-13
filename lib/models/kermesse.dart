import 'package:flutter/foundation.dart';

class KermesseSummary {
  const KermesseSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.coverUrl,
    this.eventDateText,
    this.locationName,
    this.address,
    this.coordinates,
    this.latitude,
    this.longitude,
    this.beneficiaries,
    this.goalDescription,
    this.partners,
    this.menuItems = const [],
    this.activities = const [],
    this.galleryImages = const [],
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverUrl;
  final String? eventDateText;
  final String? locationName;
  final String? address;
  final String? coordinates;
  final double? latitude;
  final double? longitude;
  final String? beneficiaries;
  final String? goalDescription;
  final String? partners;
  final List<String> menuItems;
  final List<String> activities;
  final List<String> galleryImages;

  ({double latitude, double longitude})? get geoPoint {
    if (latitude != null && longitude != null) {
      return (latitude: latitude!, longitude: longitude!);
    }

    if (coordinates == null || coordinates!.isEmpty) {
      return null;
    }

    final pair = _parseCoordinatePair(coordinates!);
    final lat = pair.$1;
    final lng = pair.$2;
    if (lat == null || lng == null) {
      return null;
    }
    return (latitude: lat, longitude: lng);
  }

  factory KermesseSummary.fromJson(Map<String, dynamic> json) {
    final description = (json['descripcion'] as String? ?? '').trim();
    final parser = _KermesseDescriptionParser(description);
    final meta = parser.parse();

    return KermesseSummary(
      id: json['id'] as String,
      title: (json['titulo'] as String? ?? '').trim().isEmpty
          ? 'Kermesse solidaria'
          : (json['titulo'] as String).trim(),
      description: description,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      coverUrl: _normalizeUrl(json['portada_url'] as String?),
      eventDateText: meta.eventDate,
      locationName: meta.locationName,
      address: meta.address,
      coordinates: meta.coordinates,
    latitude: meta.latitude,
    longitude: meta.longitude,
      beneficiaries: meta.beneficiaries,
      goalDescription: meta.goalDescription,
      partners: meta.partners,
      menuItems: meta.menuItems,
      activities: meta.activities,
      galleryImages: meta.galleryImages,
    );
  }

  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// Texto introductorio sin secciones técnicas, ideal para listados.
  String get overview {
    if (description.isEmpty) {
      return '';
    }

    final markers = [
      '\n\nUbicacion confirmada en mapa',
      '\nUbicación confirmada en mapa',
      '\n\nAgenda, punto de encuentro e impacto',
      '\nAgenda, punto de encuentro e impacto',
      '\n\nMenu y precios sugeridos',
      '\nMenú y precios sugeridos',
      '\n\nShows y actividades confirmadas',
      '\nShows y actividades confirmadas',
    ];

    var boundary = description.length;
    for (final marker in markers) {
      final index = description.indexOf(marker);
      if (index != -1 && index < boundary) {
        boundary = index;
      }
    }

    final result = description.substring(0, boundary).trim();
    return result.isEmpty ? description : result;
  }

  String get shortDescription {
    final text = overview;
    if (text.length <= 220) {
      return text;
    }
    return '${text.substring(0, 217).trim()}…';
  }

  static String? _normalizeUrl(String? url) {
    if (url == null) {
      return null;
    }
    final trimmed = url.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    debugPrint('KermesseSummary: fecha inválida -> $value');
    return DateTime.now().toUtc();
  }
}

class _KermesseMeta {
  const _KermesseMeta({
    this.eventDate,
    this.locationName,
    this.address,
    this.coordinates,
    this.latitude,
    this.longitude,
    this.beneficiaries,
    this.goalDescription,
    this.partners,
    this.menuItems = const [],
    this.activities = const [],
    this.galleryImages = const [],
  });

  final String? eventDate;
  final String? locationName;
  final String? address;
  final String? coordinates;
  final double? latitude;
  final double? longitude;
  final String? beneficiaries;
  final String? goalDescription;
  final String? partners;
  final List<String> menuItems;
  final List<String> activities;
  final List<String> galleryImages;
}

class _KermesseDescriptionParser {
  _KermesseDescriptionParser(this._raw);

  final String _raw;

  static const String _eventDateLabel = 'Fecha y horario de inicio';
  static const String _locationNameLabel = 'Nombre del lugar';
  static const String _beneficiariesLabel = '¿Quiénes se beneficiarán?';
  static const String _goalLabel = '¿Para qué se usa lo recaudado?';
  static const String _partnersLabel = 'Aliados o patrocinadores (opcional)';

  _KermesseMeta parse() {
    if (_raw.trim().isEmpty) {
      return const _KermesseMeta();
    }

    final lines = _raw.split('\n').map((line) => line.trim()).toList();
    String? eventDate;
    String? locationName;
    String? address;
    String? coordinates;
    String? lat;
    String? lng;
  double? latValue;
  double? lngValue;
    String? beneficiaries;
    String? goal;
    String? partners;
    final menuItems = <String>[];
    final activities = <String>[];
  final galleryImages = <String>[];

    var inLocationSection = false;
    var inReferenceSection = false;
    var inMenuSection = false;
    var inActivitiesSection = false;
  var inGallerySection = false;

    for (final line in lines) {
      if (line.isEmpty) {
        inLocationSection = false;
        inReferenceSection = false;
        inMenuSection = false;
        inActivitiesSection = false;
        inGallerySection = false;
        continue;
      }

      if (line.startsWith('Ubicacion confirmada en mapa') ||
          line.startsWith('Ubicación confirmada en mapa')) {
        inLocationSection = true;
        inReferenceSection = false;
        continue;
      }

      if (line.startsWith('Coordenadas de referencia')) {
        inReferenceSection = true;
        inLocationSection = false;
        inGallerySection = false;
        continue;
      }

      if (line.startsWith('Menu y precios sugeridos') ||
          line.startsWith('Menú y precios sugeridos')) {
        inMenuSection = true;
        inActivitiesSection = false;
        inGallerySection = false;
        continue;
      }

      if (line.startsWith('Shows y actividades confirmadas')) {
        inActivitiesSection = true;
        inMenuSection = false;
        inGallerySection = false;
        continue;
      }

      if (line.startsWith('Evidencias fotográficas') ||
          line.startsWith('Evidencias fotograficas')) {
        inGallerySection = true;
        inMenuSection = false;
        inActivitiesSection = false;
        continue;
      }

      if (!line.startsWith('- ')) {
        inMenuSection = false;
        inActivitiesSection = false;
        inGallerySection = false;
        continue;
      }

      final content = line.substring(2).trim();
      if (content.isEmpty) {
        continue;
      }

      final value = _valueAfterColon(content);

      if (content.startsWith('Dir') && inLocationSection && value != null) {
        address ??= value;
        continue;
      }

      if (content.startsWith('Coordenadas:') && inLocationSection && value != null) {
        coordinates ??= value;
        final pair = _parseCoordinatePair(value);
        latValue ??= pair.$1;
        lngValue ??= pair.$2;
        continue;
      }

      if (content.startsWith('Latitud:') && inReferenceSection && value != null) {
        lat ??= value;
        latValue ??= _toCoordinate(value);
        continue;
      }

      if (content.startsWith('Longitud:') && inReferenceSection && value != null) {
        lng ??= value;
        lngValue ??= _toCoordinate(value);
        continue;
      }

      if (inGallerySection) {
        final url = content;
        if (url.startsWith('http')) {
          galleryImages.add(url);
        }
        continue;
      }

      if (inMenuSection) {
        menuItems.add(content);
        continue;
      }

      if (inActivitiesSection) {
        activities.add(content);
        continue;
      }

      if (content.startsWith('$_eventDateLabel:') && value != null) {
        eventDate ??= value;
        continue;
      }

      if (content.startsWith('$_locationNameLabel:') && value != null) {
        locationName ??= value;
        continue;
      }

      if (content.startsWith('$_beneficiariesLabel:') && value != null) {
        beneficiaries ??= value;
        continue;
      }

      if (content.startsWith('$_goalLabel:') && value != null) {
        goal ??= value;
        continue;
      }

      if (content.startsWith('$_partnersLabel:') && value != null) {
        partners ??= value;
        continue;
      }
    }

    if (coordinates == null && lat != null && lng != null) {
      coordinates = 'Latitud: $lat · Longitud: $lng';
    }

    return _KermesseMeta(
      eventDate: eventDate,
      locationName: locationName,
      address: address,
      coordinates: coordinates,
      latitude: latValue,
      longitude: lngValue,
      beneficiaries: beneficiaries,
      goalDescription: goal,
      partners: partners,
      menuItems: menuItems,
      activities: activities,
      galleryImages: galleryImages,
    );
  }

  String? _valueAfterColon(String text) {
    final index = text.indexOf(':');
    if (index == -1 || index == text.length - 1) {
      return null;
    }
    return text.substring(index + 1).trim();
  }
}

double? _toCoordinate(String raw) {
  final normalized = raw.replaceAll(',', '.').trim();
  return double.tryParse(normalized);
}

(double?, double?) _parseCoordinatePair(String raw) {
  final sanitized = raw.replaceAll(RegExp('[^0-9,\.-]'), ' ').replaceAll('·', ' ');
  final matches = RegExp(r'-?\d+(?:[\.,]\d+)?')
      .allMatches(sanitized)
      .map((match) => match.group(0))
      .whereType<String>()
      .toList();

  if (matches.length < 2) {
    return (null, null);
  }

  final lat = _toCoordinate(matches[0]);
  final lng = _toCoordinate(matches[1]);
  return (lat, lng);
}
