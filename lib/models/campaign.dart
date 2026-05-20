import 'package:flutter/foundation.dart';

/// Estado de verificación de evidencias post-meta de una campaña.
enum VerificationStatus {
  /// La campaña aún no alcanzó la meta — no aplica verificación.
  noAplica,

  /// La meta se alcanzó pero el creador aún no subió evidencia.
  pendienteEvidencia,

  /// El creador subió evidencia y el admin está revisando.
  enRevision,

  /// Admin aprobó la evidencia: campaña verificada.
  verificada,

  /// Pasó el plazo de 14 días sin evidencia aprobada.
  sinVerificar,
}

extension VerificationStatusX on VerificationStatus {
  static VerificationStatus fromDb(String? raw) {
    switch (raw) {
      case 'pendiente_evidencia':
        return VerificationStatus.pendienteEvidencia;
      case 'en_revision':
        return VerificationStatus.enRevision;
      case 'verificada':
        return VerificationStatus.verificada;
      case 'sin_verificar':
        return VerificationStatus.sinVerificar;
      case 'no_aplica':
      default:
        return VerificationStatus.noAplica;
    }
  }

  String get dbValue {
    switch (this) {
      case VerificationStatus.pendienteEvidencia:
        return 'pendiente_evidencia';
      case VerificationStatus.enRevision:
        return 'en_revision';
      case VerificationStatus.verificada:
        return 'verificada';
      case VerificationStatus.sinVerificar:
        return 'sin_verificar';
      case VerificationStatus.noAplica:
        return 'no_aplica';
    }
  }

  bool get isVerified => this == VerificationStatus.verificada;
  bool get isPendingEvidence =>
      this == VerificationStatus.pendienteEvidencia ||
      this == VerificationStatus.enRevision;
  bool get isUnverified => this == VerificationStatus.sinVerificar;
}

class CampaignSummary {
  CampaignSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.shortDescription,
    required this.coverUrl,
    required this.goalAmount,
    required this.raisedAmount,
    required this.completionPercentage,
    required this.donorCount,
    required this.category,
    this.startDate,
    this.endDate,
    this.organizerName,
    this.isVerified = false,
    this.isFavorite = false,
    this.creatorId,
    this.status,
    this.requestId,
    this.isAnonymous = false,
    this.verificationStatus = VerificationStatus.noAplica,
    this.metaReachedAt,
    this.evidenceDeadline,
    this.evidenceCount = 0,
    this.rejectionReason,
  });

  factory CampaignSummary.fromPublicView(Map<String, dynamic> json) {
    return CampaignSummary(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['titulo'] as String? ?? 'Campaña sin título',
      shortDescription: json['descripcion_corta'] as String? ?? '',
      coverUrl: json['portada_url'] as String? ?? json['cover_url'] as String? ?? '',
      goalAmount: (json['monto_objetivo'] as num?)?.toDouble() ?? 0,
      raisedAmount: (json['monto_actual'] as num?)?.toDouble() ?? 0,
      completionPercentage: (json['porcentaje'] as num?)?.toDouble() ??
          _calculatePercentage(
            current: (json['monto_actual'] as num?)?.toDouble() ?? 0,
            goal: (json['monto_objetivo'] as num?)?.toDouble() ?? 0,
          ),
      donorCount: (json['donadores'] as num?)?.toInt() ?? json['donor_count'] as int? ?? 0,
      category: json['categoria'] as String?
              ?? (json['categorias'] as Map?)?['nombre'] as String?
              ?? json['category'] as String?
              ?? '',
      startDate: _parseDate(json['fecha_inicio'] ?? json['start_date']),
      endDate: _parseDate(json['fecha_fin'] ?? json['end_date']),
      organizerName: json['organizacion_nombre'] as String? ?? json['organizer_name'] as String?,
      isVerified: (json['campania_verificada'] as bool?) ?? (json['is_verified'] as bool?) ?? false,
      isFavorite: (json['es_favorita'] as bool?) ?? (json['is_favorite'] as bool?) ?? false,
      creatorId: json['creador_id'] as String? ?? json['creator_id'] as String?,
      status: json['estado'] as String? ?? json['status'] as String?,
      requestId: json['solicitud_id'] as String? ?? json['request_id'] as String?,
      isAnonymous: (json['es_anonimo'] as bool?) ?? (json['is_anonymous'] as bool?) ?? false,
      verificationStatus:
          VerificationStatusX.fromDb(json['verification_status'] as String?),
      metaReachedAt: _parseDate(json['meta_alcanzada_at']),
      evidenceDeadline: _parseDate(
        json['evidencias_hasta'] ?? json['evidence_deadline'],
      ),
      evidenceCount: (json['evidence_count'] as num?)?.toInt() ?? 0,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  final String id;
  final String slug;
  final String title;
  final String shortDescription;
  final String coverUrl;
  final double goalAmount;
  final double raisedAmount;
  final double completionPercentage;
  final int donorCount;
  final String category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? organizerName;
  final bool isVerified;
  final bool isFavorite;
  final String? creatorId;
  final String? status;
  final String? requestId;
  final bool isAnonymous;
  final VerificationStatus verificationStatus;
  final DateTime? metaReachedAt;
  final DateTime? evidenceDeadline;
  final int evidenceCount;
  final String? rejectionReason;

  /// Días restantes para que el creador suba evidencia. Null si no aplica.
  int? get daysUntilEvidenceDeadline {
    final deadline = evidenceDeadline;
    if (deadline == null) return null;
    final diff = deadline.difference(DateTime.now());
    return diff.inDays;
  }

  bool get hasEvidenceDeadlineExpired {
    final deadline = evidenceDeadline;
    return deadline != null && DateTime.now().isAfter(deadline);
  }

  /// Nombre del beneficiario/organizador a mostrar en vista publica.
  /// Si la campania es anonima, se reemplaza por "Beneficiario anonimo".
  String? get publicOrganizerName {
    if (isAnonymous) return 'Beneficiario anónimo';
    return organizerName;
  }

  double get normalizedProgress => goalAmount <= 0 ? 0 : (raisedAmount / goalAmount).clamp(0, 1);

  bool get isCompleted {
    if (goalAmount <= 0) {
      return false;
    }
    if (completionPercentage >= 100) {
      return true;
    }
    return raisedAmount >= goalAmount;
  }

  bool get isNearGoal => normalizedProgress >= 0.7;

  bool get isNew => startDate != null && DateTime.now().difference(startDate!).inDays <= 14;

  bool get isPending => status == 'pendiente';
  
  bool get canBeDeleted => isPending && donorCount == 0 && raisedAmount == 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'titulo': title,
      'descripcion_corta': shortDescription,
      'portada_url': coverUrl,
      'monto_objetivo': goalAmount,
      'monto_actual': raisedAmount,
      'porcentaje': completionPercentage,
      'donadores': donorCount,
      'categoria': category,
      'fecha_inicio': startDate?.toIso8601String(),
      'fecha_fin': endDate?.toIso8601String(),
      'organizacion_nombre': organizerName,
      'campania_verificada': isVerified,
      'is_favorite': isFavorite,
    };
  }

  CampaignSummary copyWith({
    bool? isFavorite,
    String? status,
    VerificationStatus? verificationStatus,
    DateTime? metaReachedAt,
    DateTime? evidenceDeadline,
    int? evidenceCount,
    String? rejectionReason,
  }) {
    return CampaignSummary(
      id: id,
      slug: slug,
      title: title,
      shortDescription: shortDescription,
      coverUrl: coverUrl,
      goalAmount: goalAmount,
      raisedAmount: raisedAmount,
      completionPercentage: completionPercentage,
      donorCount: donorCount,
      category: category,
      startDate: startDate,
      endDate: endDate,
      organizerName: organizerName,
      isVerified: isVerified,
      isFavorite: isFavorite ?? this.isFavorite,
      creatorId: creatorId,
      status: status ?? this.status,
      requestId: requestId,
      isAnonymous: isAnonymous,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      metaReachedAt: metaReachedAt ?? this.metaReachedAt,
      evidenceDeadline: evidenceDeadline ?? this.evidenceDeadline,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  static double _calculatePercentage({required double current, required double goal}) {
    if (goal <= 0) {
      return 0;
    }
    final percentage = (current / goal) * 100;
    if (percentage.isNaN || !percentage.isFinite) {
      return 0;
    }
    return percentage.clamp(0, 100);
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

class CampaignDetail {
  CampaignDetail({
    required this.summary,
    this.longDescription,
    this.story,
    this.location,
    this.organizerBio,
    this.organizerAvatarUrl,
    this.videoUrl,
    this.rewards = const [],
    this.updates = const [],
    this.evidences = const [],
    this.paymentInstructions = const CampaignPaymentInstructions.empty(),
    this.organizerContactPhone,
    this.creatorName,
    this.creatorAvatarUrl,
  });

  factory CampaignDetail.fromJson(
    Map<String, dynamic> json, {
    List<Map<String, dynamic>> rewards = const [],
    List<Map<String, dynamic>> updates = const [],
    List<Map<String, dynamic>> evidences = const [],
    Map<String, dynamic>? paymentInstructionRow,
  }) {
    final instructions = paymentInstructionRow != null
        ? CampaignPaymentInstructions.fromMap(paymentInstructionRow)
        : const CampaignPaymentInstructions.empty();

    // Extraer datos del creador desde el JOIN
    final creatorData = json['creator'] as Map<String, dynamic>?;
    final creatorName = creatorData?['display_name'] as String?;
    final creatorAvatarUrl = creatorData?['avatar_url'] as String?;

    return CampaignDetail(
      summary: CampaignSummary.fromPublicView(json),
      longDescription: json['descripcion_larga'] as String? ?? json['descripcion'] as String?,
      story: json['historia'] as String? ?? json['story'] as String?,
      location: json['ubicacion'] as String? ?? json['location'] as String?,
      organizerBio: json['organizacion_resumen'] as String? ?? json['organizer_bio'] as String?,
      organizerAvatarUrl: json['organizacion_logo_url'] as String? ?? json['organizer_avatar_url'] as String?,
      videoUrl: json['video_url'] as String?,
      rewards: rewards.map(CampaignReward.fromJson).toList(),
      updates: updates.map(CampaignUpdate.fromJson).toList(),
      evidences: evidences.map(CampaignEvidence.fromJson).toList(),
      paymentInstructions: instructions,
      organizerContactPhone: paymentInstructionRow?['organizer_phone'] as String?,
      creatorName: creatorName,
      creatorAvatarUrl: creatorAvatarUrl,
    );
  }

  final CampaignSummary summary;
  final String? longDescription;
  final String? story;
  final String? location;
  final String? organizerBio;
  final String? organizerAvatarUrl;
  final String? videoUrl;
  final List<CampaignReward> rewards;
  final List<CampaignUpdate> updates;
  final List<CampaignEvidence> evidences;
  final CampaignPaymentInstructions paymentInstructions;
  final String? organizerContactPhone;
  final String? creatorName;
  final String? creatorAvatarUrl;
}

class CampaignPaymentInstructions {
  const CampaignPaymentInstructions({
    this.qrUrl,
    this.bankHolder,
    this.bankName,
    this.bankAccountType,
    this.bankAccountNumber,
  });

  const CampaignPaymentInstructions.empty()
      : qrUrl = null,
        bankHolder = null,
        bankName = null,
        bankAccountType = null,
        bankAccountNumber = null;

  factory CampaignPaymentInstructions.fromMap(Map<String, dynamic> data) {
    return CampaignPaymentInstructions(
      qrUrl: data['donacion_qr_url'] as String?,
      bankHolder: data['banco_titular'] as String?,
      bankName: data['banco_nombre'] as String?,
      bankAccountType: data['banco_tipo_cuenta'] as String?,
      bankAccountNumber: data['banco_numero_cuenta'] as String?,
    );
  }

  final String? qrUrl;
  final String? bankHolder;
  final String? bankName;
  final String? bankAccountType;
  final String? bankAccountNumber;

  bool get hasQr => qrUrl?.trim().isNotEmpty == true;

  bool get hasBankDetails => [
        bankHolder,
        bankName,
        bankAccountType,
        bankAccountNumber,
      ].any((value) => value?.trim().isNotEmpty == true);

  bool get isEmpty => !hasQr && !hasBankDetails;
}

class CampaignReward {
  CampaignReward({
    required this.id,
    required this.title,
    required this.description,
    required this.minimumDonation,
    this.limit,
    this.claimedCount,
    this.deliverBy,
    bool? isLimited,
  }) : isLimited = isLimited ?? (limit != null);

  factory CampaignReward.fromJson(Map<String, dynamic> json) {
    final limit = (json['cantidad_limite'] as num?)?.toInt() ?? (json['limit'] as num?)?.toInt();
    final claimed = (json['cantidad_reclamada'] as num?)?.toInt() ?? (json['claimed'] as num?)?.toInt();
    final isLimited = (json['es_limitada'] as bool?) ?? (json['is_limited'] as bool?) ?? (limit != null);

    return CampaignReward(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      title: json['titulo'] as String? ?? json['title'] as String? ?? 'Recompensa',
      description: json['descripcion'] as String? ?? json['description'] as String? ?? '',
      minimumDonation: (json['monto_minimo'] as num?)?.toDouble() ?? (json['minimum_donation'] as num?)?.toDouble() ?? 0,
      limit: limit,
      claimedCount: claimed,
      deliverBy: CampaignSummary._parseDate(json['fecha_entrega'] ?? json['deliver_by']),
      isLimited: isLimited,
    );
  }

  final String id;
  final String title;
  final String description;
  final double minimumDonation;
  final int? limit;
  final int? claimedCount;
  final DateTime? deliverBy;
  final bool isLimited;

  int? get availableQuantity {
    if (limit == null) {
      return null;
    }
    final claimed = claimedCount ?? 0;
    final remaining = limit! - claimed;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isSoldOut => isLimited && (availableQuantity ?? 1) <= 0;
}

class CampaignUpdate {
  CampaignUpdate({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
  });

  factory CampaignUpdate.fromJson(Map<String, dynamic> json) {
    return CampaignUpdate(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      title: json['titulo'] as String? ?? json['title'] as String? ?? 'Actualización',
      content: json['contenido'] as String? ?? json['content'] as String? ?? '',
      publishedAt: CampaignSummary._parseDate(json['fecha_publicacion'] ?? json['published_at']) ?? DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String content;
  final DateTime publishedAt;
}

/// Tipos aceptados por el check constraint `evidencias_tipo_check` en la DB.
enum EvidenceType { foto, video, documento, otro }

extension EvidenceTypeX on EvidenceType {
  static EvidenceType fromDb(String? raw) {
    switch (raw) {
      case 'foto':
        return EvidenceType.foto;
      case 'video':
        return EvidenceType.video;
      case 'documento':
      case 'pdf': // tolerar valor histórico
        return EvidenceType.documento;
      case 'otro':
      default:
        return EvidenceType.otro;
    }
  }

  String get dbValue {
    switch (this) {
      case EvidenceType.foto:
        return 'foto';
      case EvidenceType.video:
        return 'video';
      case EvidenceType.documento:
        return 'documento';
      case EvidenceType.otro:
        return 'otro';
    }
  }
}

class CampaignEvidence {
  CampaignEvidence({
    required this.id,
    required this.type,
    required this.url,
    this.description,
    this.thumbnailUrl,
    this.campaignId,
    this.uploadedBy,
    this.storagePath,
    this.filename,
    this.mimeType,
    this.fileSizeBytes,
    this.createdAt,
  });

  factory CampaignEvidence.fromJson(Map<String, dynamic> json) {
    final rawType = json['tipo'] as String? ?? json['type'] as String?;
    return CampaignEvidence(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      type: rawType ?? 'otro',
      url: json['url'] as String? ?? json['archivo_url'] as String? ?? '',
      description: json['descripcion'] as String? ?? json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      campaignId: json['campania_id'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      storagePath: json['storage_path'] as String?,
      filename: json['filename'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      createdAt: CampaignSummary._parseDate(json['created_at']),
    );
  }

  final String id;
  final String type;
  final String url;
  final String? description;
  final String? thumbnailUrl;
  final String? campaignId;
  final String? uploadedBy;
  final String? storagePath;
  final String? filename;
  final String? mimeType;
  final int? fileSizeBytes;
  final DateTime? createdAt;

  EvidenceType get typeEnum => EvidenceTypeX.fromDb(type);

  bool get isImage =>
      typeEnum == EvidenceType.foto ||
      (mimeType?.startsWith('image/') ?? false);
  bool get isVideo =>
      typeEnum == EvidenceType.video ||
      (mimeType?.startsWith('video/') ?? false);
  bool get isPdf =>
      mimeType == 'application/pdf' ||
      (filename?.toLowerCase().endsWith('.pdf') ?? false);
  bool get isDocument =>
      typeEnum == EvidenceType.documento && !isPdf;
}

class CampaignComment {
  CampaignComment({
    required this.id,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.authorAvatarUrl,
    this.isVerifiedDonor = false,
    this.status = 'visible',
  });

  factory CampaignComment.fromJson(Map<String, dynamic> json) {
    final profile = (json['profiles'] ?? json['perfil'] ?? json['perfiles']) as Map<String, dynamic>?;
    final profileName = profile?['display_name'] as String?;
    final profileAvatar = profile?['avatar_url'] as String?;
    final rawName = json['autor_nombre'] as String? ?? json['author_name'] as String? ?? profileName ?? '';
    final normalizedName = rawName.trim().isEmpty ? 'Usuario anónimo' : rawName.trim();
    final rawMessage = json['contenido'] as String? ?? json['mensaje'] as String? ?? json['message'] as String? ?? '';
    final status = (json['estado'] as String?) ?? (json['status'] as String?) ?? 'visible';

    return CampaignComment(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      authorName: normalizedName,
      message: rawMessage.trim(),
      createdAt: CampaignSummary._parseDate(json['creado_en'] ?? json['created_at']) ?? DateTime.now(),
      authorAvatarUrl: json['autor_avatar_url'] as String? ?? json['author_avatar_url'] as String? ?? profileAvatar,
      isVerifiedDonor: (json['donante_verificado'] as bool?) ?? (json['is_verified_donor'] as bool?) ?? false,
      status: status,
    );
  }

  final String id;
  final String authorName;
  final String message;
  final DateTime createdAt;
  final String? authorAvatarUrl;
  final bool isVerifiedDonor;
  final String status;

  bool get isVisible => status == 'visible';
}
