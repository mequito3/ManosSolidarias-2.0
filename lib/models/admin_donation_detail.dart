import 'package:meta/meta.dart';

@immutable
class AdminDonationDetail {
  const AdminDonationDetail({
    required this.id,
    required this.campaignId,
    required this.amount,
    required this.status,
    required this.method,
    required this.isAnonymous,
    required this.createdAt,
    this.userId,
    this.donorName,
    this.donorEmail,
    this.donorPhone,
    this.reference,
    this.operationNumber,
    this.bankEntity,
    this.message,
    this.receiptUrl,
    this.rewardId,
    this.rewardTitle,
    this.campaignTitle,
    this.campaignStatus,
    this.validatorId,
    this.validatedAt,
    this.ipAddress,
  });

  final String id;
  final String campaignId;
  final double amount;
  final String status;
  final String method;
  final bool isAnonymous;
  final DateTime createdAt;
  final String? userId;
  final String? donorName;
  final String? donorEmail;
  final String? donorPhone;
  final String? reference;
  final String? operationNumber;
  final String? bankEntity;
  final String? message;
  final String? receiptUrl;
  final String? rewardId;
  final String? rewardTitle;
  final String? campaignTitle;
  final String? campaignStatus;
  final String? validatorId;
  final DateTime? validatedAt;
  final String? ipAddress;

  factory AdminDonationDetail.fromJson(
    Map<String, dynamic> json, {
    String? campaignTitle,
    String? campaignStatus,
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    String? rewardTitle,
  }) {
    return AdminDonationDetail(
      id: (json['id'] as String?) ?? '',
      campaignId: (json['campania_id'] as String?) ?? '',
      amount: _parseAmount(json['monto']),
      status: (json['estado'] as String?) ?? 'pendiente',
      method: (json['metodo'] as String?) ?? 'qr',
      isAnonymous: (json['anonimo'] as bool?) ?? false,
      createdAt: _parseDate(json['created_at']),
      userId: json['user_id'] as String?,
      donorName: donorName,
      donorEmail: donorEmail,
      donorPhone: donorPhone,
      reference: json['referencia'] as String?,
      operationNumber: json['numero_operacion'] as String?,
      bankEntity: json['entidad_bancaria'] as String?,
      message: json['mensaje'] as String?,
      receiptUrl: json['comprobante_url'] as String?,
      rewardId: json['recompensa_id'] as String?,
      rewardTitle: rewardTitle,
      campaignTitle: campaignTitle,
      campaignStatus: campaignStatus,
      validatorId: json['admin_validador'] as String?,
      validatedAt: _parseNullableDate(json['fecha_validacion']),
      ipAddress: json['ip_registro'] as String?,
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
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
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
