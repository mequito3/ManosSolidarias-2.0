class NotificationEntry {
  const NotificationEntry({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.payload,
    required this.isRead,
  });

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    return NotificationEntry(
      id: json['id'] as String,
      type: _readString(json['tipo']) ?? 'general',
      message: _readString(json['mensaje']) ?? 'Tienes una nueva notificación.',
      createdAt: _parseDate(json['created_at']),
      payload: _parsePayload(json['payload']),
      isRead: _readBool(json['leido']) ?? false,
    );
  }

  final String id;
  final String type;
  final String message;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final bool isRead;

  bool get isUnread => !isRead;

  String get typeLabel {
    const labels = {
      'donacion_aprobada': 'Donación aprobada',
      'donacion_confirmada': 'Donación confirmada',
      'donacion_rechazada': 'Donación rechazada',
      'nuevo_comentario': 'Nuevo comentario',
      'nuevo_favorito': 'Nuevo favorito',
      'seguimiento_campania': 'Campaña que sigues',
      'seguimiento_meta_completa': 'Meta alcanzada',
      'seguimiento_finalizando': 'Campaña por finalizar',
      'hito_25': '25% recaudado',
      'hito_50': 'Mitad de la meta',
      'hito_75': '75% recaudado',
      'meta_alcanzada': 'Meta alcanzada',
      'ranking_top_1': 'Top 1 del ranking',
      'ranking_top_2': 'Top 2 del ranking',
      'ranking_top_3': 'Top 3 del ranking',
      'solicitud_aprobada': 'Solicitud aprobada',
      'solicitud_rechazada': 'Solicitud rechazada',
      'organizacion_aprobada': 'Organización aprobada',
      'organizacion_rechazada': 'Organización rechazada',
      'campania_publicada': 'Campaña publicada',
      'campania_finalizando': 'Campaña por finalizar',
    };
    final mapped = labels[type.toLowerCase()];
    if (mapped != null) {
      return mapped;
    }
    final normalized = type.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) {
      return 'Notificación';
    }
    if (normalized.length == 1) {
      return normalized.toUpperCase();
    }
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  NotificationEntry copyWith({bool? isRead}) {
    return NotificationEntry(
      id: id,
      type: type,
      message: message,
      createdAt: createdAt,
      payload: payload,
      isRead: isRead ?? this.isRead,
    );
  }
}

bool? _readBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized == 'true' || normalized == 't' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == 'f' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return null;
}

String? _readString(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
  return null;
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now().toUtc();
  }
  return DateTime.now().toUtc();
}

Map<String, dynamic> _parsePayload(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value.map((key, dynamic val) => MapEntry(key.toString(), val)));
  }
  return const {};
}
