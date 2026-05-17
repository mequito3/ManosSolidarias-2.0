import 'solicitud.dart';

enum AdminItemType {
  campaignRequest,
  donationReview,
  organizationReview,
}

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.pendingRequests,
    required this.pendingDonations,
    required this.pendingOrganizations,
    required this.activeCampaigns,
    required this.totalApprovedAmount,
    required this.approvalRate,
    required this.avgResponseTimeHours,
    required this.totalDonors,
    required this.repeatDonorsPercentage,
    required this.campaignsCompletedThisMonth,
    required this.donationsThisMonth,
    required this.donationsLastMonth,
    required this.donationGrowthRate,
    required this.avgDonationAmount,
    required this.topCampaignCategory,
  });

  final int pendingRequests;
  final int pendingDonations;
  final int pendingOrganizations;
  final int activeCampaigns;
  final double totalApprovedAmount;
  
  // Métricas avanzadas
  final double approvalRate; // Tasa de aprobación de solicitudes
  final double avgResponseTimeHours; // Tiempo promedio de respuesta en horas
  final int totalDonors; // Total de donantes únicos
  final double repeatDonorsPercentage; // Porcentaje de donantes recurrentes
  final int campaignsCompletedThisMonth; // Campañas completadas este mes
  final int donationsThisMonth; // Donaciones este mes
  final int donationsLastMonth; // Donaciones mes anterior
  final double donationGrowthRate; // Tasa de crecimiento de donaciones
  final double avgDonationAmount; // Monto promedio de donación
  final String topCampaignCategory; // Categoría más popular
}

class AdminEvidenceItem {
  const AdminEvidenceItem({
    required this.id,
    required this.url,
    this.urlOriginal,
  });

  final String id;
  final String url;
  /// URL de la evidencia SIN tachar. Solo presente cuando la solicitud es
  /// anónima y el usuario aplicó tachado. El admin puede verla y re-tacharla.
  final String? urlOriginal;
}

class AdminPendingItem {
  const AdminPendingItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.createdAt,
    this.solicitudTipo,
    this.categoriaId,
    this.beneficiaryName,
    this.beneficiaryRelation,
    this.evidenceUrls,
    this.evidenceItems,
    this.coverUrl,
    this.coverOriginalUrl,
    this.kermesseLatitude,
    this.kermesseLongitude,
    this.kermesseAddress,
    this.kermesseDate,
    this.kermesseBeneficiaries,
    this.kermessePurpose,
    this.kermesseMenu,
    this.kermesseShows,
    this.esAnonimo = false,
  });

  final String id;
  final String title;
  final String? subtitle;
  final AdminItemType type;
  final DateTime createdAt;
  final SolicitudTipo? solicitudTipo;
  final String? categoriaId;
  final String? beneficiaryName;
  final String? beneficiaryRelation;
  final List<String>? evidenceUrls;
  /// Lista enriquecida de evidencias con id y url_original (solo nuevas
  /// evidencias que viven en tabla `evidencias`). Para legacy basadas en
  /// regex sobre descripción, se llena `evidenceUrls` y este queda null.
  final List<AdminEvidenceItem>? evidenceItems;
  final String? coverUrl;
  /// URL de la portada SIN tachar. Solo presente cuando la solicitud es
  /// anónima y el usuario aplicó tachado. El admin la puede ver para
  /// validar identidad sin que se publique en el feed.
  final String? coverOriginalUrl;
  final double? kermesseLatitude;
  final double? kermesseLongitude;
  final String? kermesseAddress;
  final String? kermesseDate;
  final String? kermesseBeneficiaries;
  final String? kermessePurpose;
  final String? kermesseMenu;
  final String? kermesseShows;
  final bool esAnonimo;
}

class AdminActiveCampaign {
  const AdminActiveCampaign({
    required this.id,
    required this.title,
    required this.status,
    required this.goalAmount,
    required this.raisedAmount,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final double goalAmount;
  final double raisedAmount;
  final DateTime updatedAt;

  double get completionRatio {
    if (goalAmount <= 0) {
      return 0;
    }
    final ratio = raisedAmount / goalAmount;
    if (ratio.isNaN || !ratio.isFinite) {
      return 0;
    }
    return ratio.clamp(0, 1);
  }

  double get completionPercentage => completionRatio * 100;

  factory AdminActiveCampaign.fromJson(Map<String, dynamic> json) {
    final rawTitle = (json['titulo'] as String?) ?? (json['title'] as String?) ?? '';
    return AdminActiveCampaign(
      id: json['id'] as String? ?? '',
      title: rawTitle.trim().isEmpty ? 'Campaña sin título' : rawTitle.trim(),
      status: (json['estado'] as String?) ?? 'activa',
      goalAmount: _parseNumeric(json['monto_objetivo']),
      raisedAmount: _parseNumeric(json['monto_actual']),
      updatedAt: _parseDate(json['updated_at'] ?? json['fecha_actualizacion']),
    );
  }

  static double _parseNumeric(dynamic value) {
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
}
