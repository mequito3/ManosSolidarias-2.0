class AdminOrganizationDetail {
  const AdminOrganizationDetail({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.ownerId,
    this.type,
    this.description,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.logoUrl,
    this.adminNotes,
    this.ownerName,
    this.ownerPhone,
    this.ownerCity,
    this.ownerDocumentType,
    this.ownerDocumentNumber,
    this.galleryUrls = const [],
    this.socialLinks = const [],
    this.documents = const [],
  });

  factory AdminOrganizationDetail.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? ownerProfile,
    Iterable<Map<String, dynamic>> documents = const [],
  }) {
    final parsed = _OrganizationDescriptionParser.parse(json['descripcion']);
    final owner = ownerProfile ?? const <String, dynamic>{};
    
    // Extraer URLs de galería del campo galeria (JSONB array)
    List<String> galleryUrls = [];
    if (json['galeria'] != null) {
      try {
        final galeriaData = json['galeria'];
        if (galeriaData is List) {
          galleryUrls = galeriaData
              .map((e) => e.toString())
              .where((url) => url.isNotEmpty)
              .toList();
        }
      } catch (e) {
        // Si hay error parseando galeria, usar las del parser
        galleryUrls = parsed.galleryUrls;
      }
    }
    
    // Si no hay galería en el campo, usar las extraídas de la descripción
    if (galleryUrls.isEmpty) {
      galleryUrls = parsed.galleryUrls;
    }

    return AdminOrganizationDetail(
      id: json['id']?.toString() ?? '',
      name: _normalizeText(json['nombre']) ?? 'Organización sin nombre',
      type: _normalizeText(json['tipo']),
      description: parsed.description,
      phone: _normalizeText(json['telefono']),
      email: _normalizeText(json['email']),
      website: _normalizeUrl(json['sitio_web']),
      address: _normalizeMultiline(json['direccion']),
      logoUrl: _normalizeUrl(json['logo_url']),
      status: _normalizeText(json['estado']) ?? 'pendiente',
      adminNotes: _normalizeMultiline(json['notas_admin']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      ownerId: owner['user_id']?.toString() ?? json['owner_id']?.toString() ?? '',
      ownerName: _normalizeText(owner['display_name']),
      ownerPhone: _normalizeText(owner['telefono']),
      ownerCity: _normalizeText(owner['ciudad']),
      ownerDocumentType: _normalizeText(owner['documento_tipo']),
      ownerDocumentNumber: _normalizeText(owner['documento_numero']),
      galleryUrls: galleryUrls,
      socialLinks: parsed.socialLinks,
      documents: documents.map(AdminOrganizationDocument.fromJson).toList(),
    );
  }

  final String id;
  final String name;
  final String? type;
  final String? description;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String? logoUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String ownerId;
  final String? adminNotes;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerCity;
  final String? ownerDocumentType;
  final String? ownerDocumentNumber;
  final List<String> galleryUrls;
  final List<String> socialLinks;
  final List<AdminOrganizationDocument> documents;

  bool get hasGallery => galleryUrls.isNotEmpty;
  bool get hasSocialLinks => socialLinks.isNotEmpty;
  bool get hasContactInfo =>
      (phone != null && phone!.isNotEmpty) || (email != null && email!.isNotEmpty) || (website != null && website!.isNotEmpty);
  bool get hasAddress => address != null && address!.isNotEmpty;
}

class AdminOrganizationDocument {
  const AdminOrganizationDocument({
    required this.id,
    required this.type,
    required this.url,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.adminNotes,
  });

  factory AdminOrganizationDocument.fromJson(Map<String, dynamic> json) {
    return AdminOrganizationDocument(
      id: json['id']?.toString() ?? '',
      type: _normalizeText(json['tipo']) ?? 'Documento',
      url: _normalizeUrl(json['archivo_url']) ?? '',
      status: _normalizeText(json['estado']) ?? 'pendiente',
      adminNotes: _normalizeMultiline(json['notas_admin']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  final String id;
  final String type;
  final String url;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminNotes;
}

class _OrganizationDescriptionParseResult {
  const _OrganizationDescriptionParseResult({
    this.description,
    this.galleryUrls = const [],
    this.socialLinks = const [],
  });

  final String? description;
  final List<String> galleryUrls;
  final List<String> socialLinks;
}

class _OrganizationDescriptionParser {
  static _OrganizationDescriptionParseResult parse(dynamic raw) {
    final normalized = _normalizeMultiline(raw);
    if (normalized == null || normalized.isEmpty) {
      return const _OrganizationDescriptionParseResult();
    }

    const marker = 'Material de referencia para validación:';
    if (!normalized.contains(marker)) {
      return _OrganizationDescriptionParseResult(description: normalized);
    }

    final parts = normalized.split(marker);
    final basePart = parts.first.replaceAll(RegExp(r'-{3,}\s*'), '').trim();
    final metadata = parts.length > 1 ? parts.sublist(1).join(marker).trim() : '';

    final gallery = <String>[];
    final social = <String>[];
    String? currentSection;

    for (final rawLine in metadata.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line == '---') {
        continue;
      }
      if (line.startsWith('- ')) {
        final header = line.substring(2).toLowerCase();
        if (header.contains('galería')) {
          currentSection = 'gallery';
        } else if (header.contains('rede')) {
          currentSection = 'social';
        } else {
          currentSection = null;
        }
        continue;
      }

      var value = line;
      if (value.startsWith('-')) {
        value = value.replaceFirst(RegExp(r'^-+\s*'), '');
      }
      if (value.startsWith('•')) {
        value = value.substring(1).trim();
      }
      if (value.isEmpty) {
        continue;
      }

      final sanitizedUrl = _normalizeUrl(value) ?? value;
      if (currentSection == 'gallery') {
        if (!gallery.contains(sanitizedUrl)) {
          gallery.add(sanitizedUrl);
        }
      } else if (currentSection == 'social') {
        final normalizedLink = _normalizeText(value) ?? value;
        if (!social.contains(normalizedLink)) {
          social.add(normalizedLink);
        }
      }
    }

    return _OrganizationDescriptionParseResult(
      description: basePart.isEmpty ? null : basePart,
      galleryUrls: gallery,
      socialLinks: social,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String? _normalizeText(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _normalizeMultiline(dynamic value) {
  final text = _normalizeText(value);
  if (text == null) {
    return null;
  }
  final sanitizedBuffer = <String>[];
  for (final rawLine in text.split(RegExp(r'\s*\n+\s*'))) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }
    sanitizedBuffer.add(line);
  }
  final sanitized = sanitizedBuffer.join('\n');
  return sanitized.isEmpty ? null : sanitized;
}

String? _normalizeUrl(dynamic value) {
  final text = _normalizeText(value);
  if (text == null) {
    return null;
  }
  if (!text.startsWith('http://') && !text.startsWith('https://')) {
    return 'https://$text';
  }
  return text;
}
