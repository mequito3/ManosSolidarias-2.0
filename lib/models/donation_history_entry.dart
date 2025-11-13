import 'package:flutter/foundation.dart';

enum DonationStatus {
  pending,
  approved,
  rejected,
}

extension DonationStatusX on DonationStatus {
  String get label {
    switch (this) {
      case DonationStatus.pending:
        return 'Pendiente';
      case DonationStatus.approved:
        return 'Aprobada';
      case DonationStatus.rejected:
        return 'Rechazada';
    }
  }

  static DonationStatus fromDatabase(String? value) {
    switch (value?.toLowerCase()) {
      case 'aprobada':
        return DonationStatus.approved;
      case 'rechazada':
        return DonationStatus.rejected;
      case 'pendiente':
      default:
        return DonationStatus.pending;
    }
  }
}

class DonationHistoryEntry {
  const DonationHistoryEntry({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.campaignCoverUrl,
    this.validatedAt,
    this.method,
    this.reference,
    this.message,
    this.receiptUrl,
    this.rewardTitle,
    this.isAnonymous = false,
  });

  factory DonationHistoryEntry.fromJson(Map<String, dynamic> json) {
    final campaign = json['campanias'] as Map<String, dynamic>?;
    final reward = json['recompensas'] as Map<String, dynamic>?;

    return DonationHistoryEntry(
      id: json['id'] as String,
      campaignId: json['campania_id'] as String,
      campaignTitle: _readString(campaign?['titulo']) ?? 'Campaña solidaria',
      campaignCoverUrl: _readString(campaign?['portada_url']),
      amount: (json['monto'] as num?)?.toDouble() ?? 0,
      status: DonationStatusX.fromDatabase(json['estado'] as String?),
  createdAt: _parseRequiredDate(json['created_at']),
  validatedAt: _parseOptionalDate(json['fecha_validacion']),
      method: _readString(json['metodo']),
      reference: _readString(json['referencia']),
      message: _readString(json['mensaje']),
      receiptUrl: _readString(json['comprobante_url']),
      rewardTitle: _readString(reward?['titulo']),
      isAnonymous: json['anonimo'] as bool? ?? false,
    );
  }

  final String id;
  final String campaignId;
  final String campaignTitle;
  final String? campaignCoverUrl;
  final double amount;
  final DonationStatus status;
  final DateTime createdAt;
  final DateTime? validatedAt;
  final String? method;
  final String? reference;
  final String? message;
  final String? receiptUrl;
  final String? rewardTitle;
  final bool isAnonymous;

  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  DonationHistoryEntry copyWith({DonationStatus? status, DateTime? validatedAt}) {
    return DonationHistoryEntry(
      id: id,
      campaignId: campaignId,
      campaignTitle: campaignTitle,
      campaignCoverUrl: campaignCoverUrl,
      amount: amount,
      status: status ?? this.status,
      createdAt: createdAt,
      validatedAt: validatedAt ?? this.validatedAt,
      method: method,
      reference: reference,
      message: message,
      receiptUrl: receiptUrl,
      rewardTitle: rewardTitle,
      isAnonymous: isAnonymous,
    );
  }
}

String? _readString(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

DateTime _parseRequiredDate(dynamic value) {
  final parsed = _parseOptionalDate(value);
  if (parsed != null) {
    return parsed;
  }
  debugPrint('DonationHistoryEntry: fecha requerida inválida -> $value');
  return DateTime.now().toUtc();
}

DateTime? _parseOptionalDate(dynamic value) {
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
