class OrganizationSummary {
  OrganizationSummary({
    required this.id,
    required this.name,
    this.type,
    this.description,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.logoUrl,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory OrganizationSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationSummary(
      id: json['id']?.toString() ?? '',
      name: json['nombre'] as String? ?? json['name'] as String? ?? 'Organización sin nombre',
      type: _normalizeText(json['tipo'] ?? json['type']),
      description: _normalizeMultiline(json['descripcion'] ?? json['description']),
      phone: _normalizeText(json['telefono'] ?? json['phone']),
      email: _normalizeText(json['email']),
      website: _normalizeUrl(json['sitio_web'] ?? json['website']),
      address: _normalizeMultiline(json['direccion'] ?? json['address']),
      logoUrl: _normalizeUrl(json['logo_url'] ?? json['logo']),
      status: _normalizeText(json['estado'] ?? json['status']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
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
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;

  bool get hasDirectContact => phone != null && phone!.isNotEmpty || email != null && email!.isNotEmpty;

  bool get hasWebsite => website != null && website!.isNotEmpty;

  bool get hasAddress => address != null && address!.isNotEmpty;

  bool get isVerified => status?.toLowerCase() == 'aprobada';

  bool get isRecent => createdAt != null && DateTime.now().difference(createdAt!).inDays <= 30;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'tipo': type,
      'descripcion': description,
      'telefono': phone,
      'email': email,
      'sitio_web': website,
      'direccion': address,
      'logo_url': logoUrl,
      'estado': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static String? _normalizeText(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _normalizeMultiline(dynamic value) {
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

  static String? _normalizeUrl(dynamic value) {
    final text = _normalizeText(value);
    if (text == null) {
      return null;
    }
    if (!text.startsWith('http://') && !text.startsWith('https://')) {
      return 'https://$text';
    }
    return text;
  }

  static DateTime? _parseDate(dynamic value) {
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
}

class OrganizationDraft {
  const OrganizationDraft({
    required this.name,
    this.type,
    this.description,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.logoUrl,
    this.galleryImageUrls = const [],
    this.socialLinks = const [],
  });

  final String name;
  final String? type;
  final String? description;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String? logoUrl;
  final List<String> galleryImageUrls;
  final List<String> socialLinks;

  Map<String, dynamic> toInsertPayload({required String ownerId}) {
    final normalizedType = OrganizationSummary._normalizeText(type);
    final normalizedDescription = OrganizationSummary._normalizeMultiline(description);
    final normalizedPhone = OrganizationSummary._normalizeText(phone);
    final normalizedEmail = OrganizationSummary._normalizeText(email);
    final normalizedWebsite = OrganizationSummary._normalizeUrl(website);
    final normalizedAddress = OrganizationSummary._normalizeMultiline(address);
    final normalizedLogo = OrganizationSummary._normalizeUrl(logoUrl);
    final normalizedGallery = _normalizeGallery(galleryImageUrls);
    final normalizedSocialLinks = _normalizeSocialLinks(socialLinks);
    final enrichedDescription = _composeDescription(
      normalizedDescription,
      normalizedGallery,
      normalizedSocialLinks,
    );

    return {
      'owner_id': ownerId,
      'nombre': name.trim(),
      'tipo': normalizedType,
      'descripcion': enrichedDescription,
      'telefono': normalizedPhone,
      'email': normalizedEmail,
      'sitio_web': normalizedWebsite,
      'direccion': normalizedAddress,
      'logo_url': normalizedLogo,
      'estado': 'pendiente',
    }..removeWhere((_, value) => value == null || (value is String && value.isEmpty));
  }

  List<String> _normalizeGallery(List<String> urls) {
    final normalized = <String>{};
    for (final raw in urls) {
      final normalizedUrl = OrganizationSummary._normalizeUrl(raw)?.trim();
      if (normalizedUrl == null || normalizedUrl.isEmpty) {
        continue;
      }
      normalized.add(normalizedUrl);
    }
    return normalized.toList();
  }

  List<String> _normalizeSocialLinks(List<String> links) {
    final normalized = <String>{};
    for (final raw in links) {
      final text = OrganizationSummary._normalizeText(raw);
      if (text == null || text.isEmpty) {
        continue;
      }
      normalized.add(text);
    }
    return normalized.toList();
  }

  String? _composeDescription(
    String? baseDescription,
    List<String> galleryUrls,
    List<String> socialLinks,
  ) {
    final buffer = StringBuffer();

    if (baseDescription != null && baseDescription.isNotEmpty) {
      buffer.writeln(baseDescription);
    }

    if (galleryUrls.isEmpty && socialLinks.isEmpty) {
      return buffer.isEmpty ? null : buffer.toString().trim();
    }

    if (buffer.isNotEmpty) {
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln('Material de referencia para validación:');

    if (galleryUrls.isNotEmpty) {
      buffer.writeln('- Galería del espacio:');
      for (final url in galleryUrls) {
        buffer.writeln('  - $url');
      }
    }

    if (socialLinks.isNotEmpty) {
      buffer.writeln('- Redes sociales oficiales:');
      for (final link in socialLinks) {
        buffer.writeln('  - $link');
      }
    }

    return buffer.toString().trim();
  }
}
