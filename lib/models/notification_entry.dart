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
