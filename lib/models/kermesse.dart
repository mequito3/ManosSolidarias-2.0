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
    this.musicItems = const [],
    this.galleryImages = const [],
    this.closingMessage,
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
  final List<String> musicItems;
  final List<String> galleryImages;
  final String? closingMessage;

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
      musicItems: meta.musicItems,
      galleryImages: meta.galleryImages,
      closingMessage: meta.closingMessage,
    );
  }

  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// Texto introductorio sin secciones técnicas, ideal para listados.
  /// Corta la descripción antes del primer label estructurado conocido
  /// (Lugar, Fecha, Menú, Actividades, etc.) para que el overview muestre
  /// solo la parte narrativa.
  String get overview {
    if (description.isEmpty) return '';

    var boundary = description.length;

    // Markers de sección de cuerpo largo (header completo). Mantienen el
    // comportamiento anterior cuando el organizador usa el template canónico
    // con saltos de línea explícitos.
    const exactMarkers = [
      '\n\nUbicacion confirmada en mapa',
      '\nUbicación confirmada en mapa',
      '\n\nAgenda, punto de encuentro e impacto',
      '\nAgenda, punto de encuentro e impacto',
      '\n\nMenu y precios sugeridos',
      '\nMenú y precios sugeridos',
      '\n\nShows y actividades confirmadas',
      '\nShows y actividades confirmadas',
      '\n\nEvidencias fotográficas',
      '\nEvidencias fotograficas',
      '\nCoordenadas de referencia',
    ];
    for (final marker in exactMarkers) {
      final idx = description.indexOf(marker);
      if (idx != -1 && idx < boundary) boundary = idx;
    }

    // Detectar labels inline tipo "Lugar:", "Fecha:", "Menú (...":
    // matchean al inicio del string, después de un salto de línea, o tras
    // un punto. El `[^\w\n]*` entre el separador y el label tolera emojis,
    // espacios, guiones y otros prefijos decorativos (ej: "\n📍 Lugar:").
    // El sufijo `:` o `(` evita falsos positivos (ej. "en el lugar de los
    // hechos" no matchea, pero "Lugar:" sí).
    final labelRegex = RegExp(
      r'((?:^|[\n.])[^\w\n]*)('
      r'lugar|fecha|horario|cu[áa]ndo|ubicaci[óo]n|men[úu]|comida|platos|'
      r'actividades?|shows?|programa|m[úu]sica|agenda|objetivo|beneficiarios|'
      r'meta|destino|aliados|patrocinadores'
      r')\s*[:\(]',
      caseSensitive: false,
    );
    for (final match in labelRegex.allMatches(description)) {
      final prefixLen = match.group(1)?.length ?? 0;
      final labelStart = match.start + prefixLen;
      if (labelStart < boundary) {
        boundary = labelStart;
      }
    }

    return description.substring(0, boundary).trim();
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
    this.musicItems = const [],
    this.galleryImages = const [],
    this.closingMessage,
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
  final List<String> musicItems;
  final List<String> galleryImages;
  final String? closingMessage;
}

class _KermesseDescriptionParser {
  _KermesseDescriptionParser(this._raw);

  final String _raw;

  static bool _matchesAny(String lineLower, List<String> prefixes) {
    for (final p in prefixes) {
      if (lineLower.startsWith(p)) return true;
    }
    return false;
  }

  /// Strip emojis decorativos, variation selectors y whitespace del inicio.
  /// Las descripciones reales vienen con prefijos como "📍 Lugar:", "🍽️ Menú:",
  /// "🎵 Música:" que sin este stripping rompen todo el matching por
  /// startsWith. Preserva "- " para no perder el marcador de list-item.
  static final RegExp _leadingDecorativeRegex = RegExp(
    r'^['
    r'\u{1F300}-\u{1FAFF}'
    r'\u{2600}-\u{27BF}'
    r'\u{2300}-\u{23FF}'
    r'\u{2900}-\u{297F}'
    r'\u{1F000}-\u{1F2FF}'
    r'\u{FE00}-\u{FE0F}'
    r'\u{200D}'
    r'\s'
    r']+',
    unicode: true,
  );

  static String _stripLeadingDecorative(String s) {
    return s.replaceFirst(_leadingDecorativeRegex, '');
  }

  static const List<String> _eventDatePrefixes = [
    'fecha y horario de inicio:',
    'fecha y horario:',
    'fecha:',
    'horario:',
    'cuándo:',
    'cuando:',
    'día:',
    'dia:',
  ];

  static const List<String> _locationNamePrefixes = [
    'nombre del lugar:',
    'lugar:',
    'ubicación:',
    'ubicacion:',
  ];

  static const List<String> _beneficiariesPrefixes = [
    '¿quiénes se beneficiarán?:',
    '¿quienes se beneficiaran?:',
    'beneficiarios:',
    'ayuda a:',
  ];

  static const List<String> _goalPrefixes = [
    '¿para qué se usa lo recaudado?:',
    '¿para que se usa lo recaudado?:',
    'objetivo:',
    'meta:',
    'destino de los fondos:',
    'destino:',
    'para qué:',
    'para que:',
  ];

  static const List<String> _partnersPrefixes = [
    'aliados o patrocinadores (opcional):',
    'aliados o patrocinadores:',
    'aliados:',
    'patrocinadores:',
  ];

  static const List<String> _menuHeaderStarts = [
    'menu y precios sugeridos',
    'menú y precios sugeridos',
    'menu:',
    'menú:',
    'menu ',
    'menú ',
    'comida:',
    'comida ',
    'platos:',
    'platos ',
  ];

  static const List<String> _activitiesHeaderStarts = [
    'shows y actividades confirmadas',
    'shows:',
    'show:',
    'actividades:',
    'actividades ',
    'actividad:',
    'actividad ',
    'programa:',
    'programa ',
    'agenda:',
  ];

  static const List<String> _musicHeaderStarts = [
    'música:',
    'música ',
    'musica:',
    'musica ',
    'programa musical:',
    'programa musical ',
    'música en vivo:',
    'música en vivo ',
    'musica en vivo:',
    'musica en vivo ',
  ];

  static String? _valueOf(String content, List<String> prefixes) {
    final lower = content.toLowerCase();
    for (final p in prefixes) {
      if (lower.startsWith(p)) {
        return content.substring(p.length).trim();
      }
    }
    return null;
  }

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
    final musicItems = <String>[];
    final galleryImages = <String>[];

    var inLocationSection = false;
    var inReferenceSection = false;
    var inMenuSection = false;
    var inActivitiesSection = false;
    var inMusicSection = false;
    var inGallerySection = false;

    // Tracking del "mensaje de cierre" del organizador (frases CTA como
    // "¡Te esperamos!" o "Cada plato vendido apoya..."). Acumulamos líneas
    // no consumidas entre secciones estructuradas; cuando aparece una nueva
    // sección, cerramos el bloque y lo guardamos como candidato.
    var firstStructuredFound = false;
    final pendingTrailing = <String>[];
    String? closingMessage;

    void onStructured() {
      if (firstStructuredFound && pendingTrailing.isNotEmpty) {
        final candidate = pendingTrailing.join(' ').trim();
        if (candidate.length >= 8) closingMessage = candidate;
      }
      pendingTrailing.clear();
      firstStructuredFound = true;
    }

    void resetSubSections() {
      inMenuSection = false;
      inActivitiesSection = false;
      inMusicSection = false;
      inGallerySection = false;
    }

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      if (rawLine.isEmpty) {
        inLocationSection = false;
        inReferenceSection = false;
        resetSubSections();
        continue;
      }

      // Stripear emojis/decoración del inicio para que el matching funcione
      // tanto si la descripción usa "Lugar:" como "📍 Lugar:".
      final line = _stripLeadingDecorative(rawLine);
      if (line.isEmpty) continue;

      if (line.startsWith('Ubicacion confirmada en mapa') ||
          line.startsWith('Ubicación confirmada en mapa')) {
        inLocationSection = true;
        inReferenceSection = false;
        onStructured();
        continue;
      }

      if (line.startsWith('Coordenadas de referencia')) {
        inReferenceSection = true;
        inLocationSection = false;
        inGallerySection = false;
        onStructured();
        continue;
      }

      final lineLower = line.toLowerCase();

      if (_matchesAny(lineLower, _menuHeaderStarts)) {
        inMenuSection = true;
        inActivitiesSection = false;
        inMusicSection = false;
        inGallerySection = false;
        onStructured();
        continue;
      }

      if (_matchesAny(lineLower, _musicHeaderStarts)) {
        inMusicSection = true;
        inMenuSection = false;
        inActivitiesSection = false;
        inGallerySection = false;
        onStructured();
        continue;
      }

      if (_matchesAny(lineLower, _activitiesHeaderStarts)) {
        inActivitiesSection = true;
        inMenuSection = false;
        inMusicSection = false;
        inGallerySection = false;
        onStructured();
        continue;
      }

      if (line.startsWith('Evidencias fotográficas') ||
          line.startsWith('Evidencias fotograficas')) {
        inGallerySection = true;
        inMenuSection = false;
        inActivitiesSection = false;
        inMusicSection = false;
        onStructured();
        continue;
      }

      final hasListPrefix = line.startsWith('- ');
      final content = hasListPrefix ? line.substring(2).trim() : line;
      if (content.isEmpty) continue;

      final eventDateValue = _valueOf(content, _eventDatePrefixes);
      if (eventDateValue != null && eventDateValue.isNotEmpty) {
        eventDate ??= eventDateValue;
        onStructured();
        continue;
      }

      final locationNameValue = _valueOf(content, _locationNamePrefixes);
      if (locationNameValue != null && locationNameValue.isNotEmpty) {
        locationName ??= locationNameValue;
        onStructured();
        continue;
      }

      final beneficiariesValue = _valueOf(content, _beneficiariesPrefixes);
      if (beneficiariesValue != null && beneficiariesValue.isNotEmpty) {
        beneficiaries ??= beneficiariesValue;
        onStructured();
        continue;
      }

      final goalValue = _valueOf(content, _goalPrefixes);
      if (goalValue != null && goalValue.isNotEmpty) {
        goal ??= goalValue;
        onStructured();
        continue;
      }

      final partnersValue = _valueOf(content, _partnersPrefixes);
      if (partnersValue != null && partnersValue.isNotEmpty) {
        partners ??= partnersValue;
        onStructured();
        continue;
      }

      if (!hasListPrefix) {
        // Si estamos dentro de un bloque de menú/música/actividades y la
        // línea es texto regular sin "- ", aceptarla como item.
        if (inMenuSection) {
          menuItems.add(content);
          onStructured();
          continue;
        }
        if (inMusicSection) {
          musicItems.add(content);
          onStructured();
          continue;
        }
        if (inActivitiesSection) {
          activities.add(content);
          onStructured();
          continue;
        }
        inGallerySection = false;
        // Texto suelto fuera de toda sección — candidato a mensaje de cierre.
        if (firstStructuredFound) pendingTrailing.add(content);
        continue;
      }

      final value = _valueAfterColon(content);

      if (content.startsWith('Dir') && inLocationSection && value != null) {
        address ??= value;
        onStructured();
        continue;
      }

      if (content.startsWith('Coordenadas:') &&
          inLocationSection &&
          value != null) {
        coordinates ??= value;
        final pair = _parseCoordinatePair(value);
        latValue ??= pair.$1;
        lngValue ??= pair.$2;
        onStructured();
        continue;
      }

      if (content.startsWith('Latitud:') &&
          inReferenceSection &&
          value != null) {
        lat ??= value;
        latValue ??= _toCoordinate(value);
        onStructured();
        continue;
      }

      if (content.startsWith('Longitud:') &&
          inReferenceSection &&
          value != null) {
        lng ??= value;
        lngValue ??= _toCoordinate(value);
        onStructured();
        continue;
      }

      if (inGallerySection) {
        if (content.startsWith('http')) {
          galleryImages.add(content);
          onStructured();
        }
        continue;
      }

      if (inMenuSection) {
        menuItems.add(content);
        onStructured();
        continue;
      }

      if (inMusicSection) {
        musicItems.add(content);
        onStructured();
        continue;
      }

      if (inActivitiesSection) {
        activities.add(content);
        onStructured();
        continue;
      }
    }

    if (coordinates == null && lat != null && lng != null) {
      coordinates = 'Latitud: $lat · Longitud: $lng';
    }

    // Flush final por si hay trailing no cerrado al final del documento
    // (raro: implica que ninguna sección estructurada vino después).
    if (firstStructuredFound && pendingTrailing.isNotEmpty) {
      final candidate = pendingTrailing.join(' ').trim();
      if (candidate.length >= 8) closingMessage = candidate;
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
      musicItems: musicItems,
      galleryImages: galleryImages,
      closingMessage: closingMessage,
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
