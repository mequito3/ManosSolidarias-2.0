import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_dashboard.dart';
import '../models/admin_donation_detail.dart';
import '../models/admin_organization_detail.dart';
import '../models/category.dart';
import '../models/solicitud.dart';

class AdminService {
  AdminService(this._client);

  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<AdminDashboardMetrics> fetchDashboardMetrics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

      final pendingRequestsFuture = _client
          .from('solicitudes')
          .select('id')
          .eq('estado', 'pendiente');

      final pendingDonationsFuture = _client
          .from('donaciones')
          .select('id')
          .eq('estado', 'pendiente');

      final pendingOrganizationsFuture = _client
          .from('organizaciones')
          .select('id')
          .eq('estado', 'pendiente');

      final activeCampaignsFuture = _client
          .from('campanias')
          .select('id')
          .inFilter('estado', ['activa', 'finalizada']);

      final totalApprovedFuture = _fetchApprovedDonationSum();
      
      // Nuevas métricas avanzadas - con manejo de errores
      final allRequestsFuture = _client
          .from('solicitudes')
          .select('id, estado, created_at, updated_at')
          .then((data) => data)
          .catchError((error) {
            print('Error fetching requests: $error');
            return <Map<String, dynamic>>[];
          });
      
      final allDonationsFuture = _client
          .from('donaciones')
          .select('id, user_id, monto, created_at, estado')
          .then((data) => data)
          .catchError((error) {
            print('Error fetching donations: $error');
            return <Map<String, dynamic>>[];
          });
      
      final campaignsCompletedFuture = _client
          .from('campanias')
          .select('id, categoria_id, categorias(nombre)')
          .eq('estado', 'finalizada')
          .then((data) => data)
          .catchError((error) {
            print('Error fetching completed campaigns: $error');
            return <Map<String, dynamic>>[];
          });

      final results = await Future.wait<dynamic>([
        pendingRequestsFuture,
        pendingDonationsFuture,
        pendingOrganizationsFuture,
        activeCampaignsFuture,
        totalApprovedFuture,
        allRequestsFuture,
        allDonationsFuture,
        campaignsCompletedFuture,
      ]);

    final pendingRequests = (results[0] as List<dynamic>).length;
    final pendingDonations = (results[1] as List<dynamic>).length;
    final pendingOrganizations = (results[2] as List<dynamic>).length;
    final activeCampaigns = (results[3] as List<dynamic>).length;
    final totalApprovedAmount = results[4] as double;
    
    // Procesar métricas avanzadas
    final allRequests = (results[5] as List<dynamic>).cast<Map<String, dynamic>>();
    final allDonations = (results[6] as List<dynamic>).cast<Map<String, dynamic>>();
    final campaignsCompleted = (results[7] as List<dynamic>).cast<Map<String, dynamic>>();
    
    // Tasa de aprobación
    final approvedRequests = allRequests.where((r) => r['estado'] == 'aprobada').length;
    final totalProcessed = allRequests.where((r) => r['estado'] != 'pendiente').length;
    final approvalRate = totalProcessed > 0 ? (approvedRequests / totalProcessed * 100) : 0.0;
    
    // Tiempo promedio de respuesta (usando updated_at vs created_at)
    double avgResponseHours = 0;
    int validatedCount = 0;
    for (final req in allRequests) {
      try {
        if (req['updated_at'] != null && req['created_at'] != null && req['estado'] != 'pendiente') {
          final created = DateTime.parse(req['created_at'] as String);
          final updated = DateTime.parse(req['updated_at'] as String);
          final diffHours = updated.difference(created).inHours;
          if (diffHours > 0) {
            avgResponseHours += diffHours;
            validatedCount++;
          }
        }
      } catch (e) {
        // Ignorar errores de parsing de fechas
        continue;
      }
    }
    avgResponseHours = validatedCount > 0 ? avgResponseHours / validatedCount : 24.0;
    
    // Donantes únicos y recurrentes
    final donorIds = <String>{};
    final donorCounts = <String, int>{};
    try {
      for (final donation in allDonations) {
        final userId = donation['user_id'] as String?;
        if (userId != null && userId.isNotEmpty) {
          donorIds.add(userId);
          donorCounts[userId] = (donorCounts[userId] ?? 0) + 1;
        }
      }
    } catch (e) {
      print('Error processing donors: $e');
    }
    final totalDonors = donorIds.length;
    final repeatDonors = donorCounts.values.where((count) => count > 1).length;
    final repeatDonorsPercentage = totalDonors > 0 ? (repeatDonors / totalDonors * 100) : 0.0;
    
    // Donaciones por mes
    int donationsThisMonth = 0;
    int donationsLastMonth = 0;
    try {
      donationsThisMonth = allDonations.where((d) {
        try {
          final createdAt = DateTime.tryParse(d['created_at'] as String? ?? '');
          return createdAt != null && createdAt.isAfter(startOfMonth);
        } catch (e) {
          return false;
        }
      }).length;
      
      donationsLastMonth = allDonations.where((d) {
        try {
          final createdAt = DateTime.tryParse(d['created_at'] as String? ?? '');
          return createdAt != null && 
                 createdAt.isAfter(startOfLastMonth) && 
                 createdAt.isBefore(endOfLastMonth);
        } catch (e) {
          return false;
        }
      }).length;
    } catch (e) {
      print('Error calculating monthly donations: $e');
    }
    
    final donationGrowthRate = donationsLastMonth > 0 
        ? ((donationsThisMonth - donationsLastMonth) / donationsLastMonth * 100) 
        : (donationsThisMonth > 0 ? 100.0 : 0.0);
    
    // Monto promedio de donación
    double avgDonationAmount = 0.0;
    try {
      final approvedDonations = allDonations.where((d) => d['estado'] == 'aprobada').toList();
      double totalDonationAmount = 0;
      for (final donation in approvedDonations) {
        totalDonationAmount += (donation['monto'] as num?)?.toDouble() ?? 0;
      }
      avgDonationAmount = approvedDonations.isNotEmpty 
          ? totalDonationAmount / approvedDonations.length 
          : 0.0;
    } catch (e) {
      print('Error calculating average donation: $e');
    }
    
    // Categoría más popular (no se usa en UI pero se mantiene para el modelo)
    String topCategory = 'N/A';

    return AdminDashboardMetrics(
      pendingRequests: pendingRequests,
      pendingDonations: pendingDonations,
      pendingOrganizations: pendingOrganizations,
      activeCampaigns: activeCampaigns,
      totalApprovedAmount: totalApprovedAmount,
      approvalRate: approvalRate,
      avgResponseTimeHours: avgResponseHours,
      totalDonors: totalDonors,
      repeatDonorsPercentage: repeatDonorsPercentage,
      campaignsCompletedThisMonth: campaignsCompleted.length,
      donationsThisMonth: donationsThisMonth,
      donationsLastMonth: donationsLastMonth,
      donationGrowthRate: donationGrowthRate,
      avgDonationAmount: avgDonationAmount,
      topCampaignCategory: topCategory,
    );
    } catch (e) {
      print('Error in fetchDashboardMetrics: $e');
      // Retornar métricas por defecto en caso de error
      return const AdminDashboardMetrics(
        pendingRequests: 0,
        pendingDonations: 0,
        pendingOrganizations: 0,
        activeCampaigns: 0,
        totalApprovedAmount: 0,
        approvalRate: 0,
        avgResponseTimeHours: 0,
        totalDonors: 0,
        repeatDonorsPercentage: 0,
        campaignsCompletedThisMonth: 0,
        donationsThisMonth: 0,
        donationsLastMonth: 0,
        donationGrowthRate: 0,
        avgDonationAmount: 0,
        topCampaignCategory: 'N/A',
      );
    }
  }

  Future<List<Category>> fetchActiveCategories() async {
    try {
      final response = await _client
          .from('categorias')
          .select('id, nombre, descripcion, icono, color, activa, orden')
          .eq('activa', true)
          .order('orden', ascending: true);

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
      return rows.map((row) => Category.fromJson(row)).toList();
    } on PostgrestException catch (error) {
      throw AdminServiceException(error.message);
    } catch (_) {
      throw const AdminServiceException('No pudimos cargar las categorías.');
    }
  }

  Future<List<AdminPendingItem>> fetchPendingCampaignRequests() async {
    final response = await _client
        .from('solicitudes')
        .select('id, titulo, descripcion, tipo, portada_url, categoria_id, created_at')
        .eq('estado', 'pendiente')
        .order('created_at', ascending: false);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return rows
        .map(
          (row) {
            final desc = row['descripcion'] as String? ?? '';
            final tipo = solicitudTipoFromCode(row['tipo'] as String?);
            final beneficiaryInfo = _extractBeneficiaryInfo(desc);
            final evidenceUrls = _extractEvidenceUrls(desc);
            final locationInfo = _extractLocationInfo(desc);
            final kermesseInfo = tipo == SolicitudTipo.kermesse ? _extractKermesseInfo(desc) : null;
            
            return AdminPendingItem(
              id: row['id'] as String,
              title: row['titulo'] as String,
              subtitle: _cleanDescription(desc),
              type: AdminItemType.campaignRequest,
              createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
              solicitudTipo: tipo,
              categoriaId: row['categoria_id'] as String?,
              beneficiaryName: beneficiaryInfo['name'],
              beneficiaryRelation: beneficiaryInfo['relation'],
              evidenceUrls: evidenceUrls,
              coverUrl: row['portada_url'] as String?,
              kermesseLatitude: locationInfo['latitude'],
              kermesseLongitude: locationInfo['longitude'],
              kermesseAddress: locationInfo['address'],
              kermesseDate: kermesseInfo?['date'],
              kermesseBeneficiaries: kermesseInfo?['beneficiaries'],
              kermessePurpose: kermesseInfo?['purpose'],
              kermesseMenu: kermesseInfo?['menu'],
              kermesseShows: kermesseInfo?['shows'],
            );
          },
        )
        .toList();
  }

  String _cleanDescription(String desc) {
    // Remove structured data sections for campaigns
    var cleaned = desc
        .replaceAll(RegExp(r'Datos del beneficiario:.*?(?=Evidencias fotográficas:|$)', dotAll: true), '')
        .replaceAll(RegExp(r'Evidencias fotográficas:.*', dotAll: true), '')
        .trim();
    
    // Remove kermesse structured data
    cleaned = cleaned
        .replaceAll(RegExp(r'Ubicacion confirmada en mapa:.*?(?=Menu y precios|Shows y actividades|Agenda|Evidencias|$)', dotAll: true), '')
        .replaceAll(RegExp(r'Menu y precios sugeridos:.*?(?=Shows y actividades|Agenda|Evidencias|$)', dotAll: true), '')
        .replaceAll(RegExp(r'Shows y actividades confirmadas:.*?(?=Agenda|Evidencias|$)', dotAll: true), '')
        .replaceAll(RegExp(r'Agenda, punto de encuentro e impacto:.*?(?=Evidencias|$)', dotAll: true), '')
        .replaceAll(RegExp(r'Evidencias fotográficas.*', dotAll: true), '')
        .trim();
    
    return cleaned.isEmpty ? desc : cleaned;
  }

  Map<String, String?> _extractBeneficiaryInfo(String desc) {
    String? name;
    String? relation;
    
    final nameMatch = RegExp(r'- Nombre:\s*(.+)', multiLine: true).firstMatch(desc);
    if (nameMatch != null) {
      name = nameMatch.group(1)?.trim();
    }
    
    final relationMatch = RegExp(r'- Relacion:\s*(.+)', multiLine: true).firstMatch(desc);
    if (relationMatch != null) {
      relation = relationMatch.group(1)?.trim();
    }
    
    return {'name': name, 'relation': relation};
  }

  List<String> _extractEvidenceUrls(String desc) {
    final urls = <String>[];
    final urlPattern = RegExp(r'https://[^\s]+\.(?:jpg|jpeg|png|gif)', caseSensitive: false);
    final matches = urlPattern.allMatches(desc);
    for (final match in matches) {
      final url = match.group(0);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  Map<String, dynamic> _extractLocationInfo(String desc) {
    double? latitude;
    double? longitude;
    String? address;
    
    // Extract coordinates from multiple formats
    // Format 1: "- Coordenadas: -17.435909, -66.152553"
    var coordMatch = RegExp(r'- Coordenadas:\s*([-\d.]+),\s*([-\d.]+)', multiLine: true).firstMatch(desc);
    if (coordMatch != null) {
      latitude = double.tryParse(coordMatch.group(1) ?? '');
      longitude = double.tryParse(coordMatch.group(2) ?? '');
    }
    
    // Format 2: "Lat: -16.123456, Lng: -68.123456"
    if (latitude == null || longitude == null) {
      coordMatch = RegExp(r'Lat:\s*([-\d.]+),\s*Lng:\s*([-\d.]+)', multiLine: true).firstMatch(desc);
      if (coordMatch != null) {
        latitude = double.tryParse(coordMatch.group(1) ?? '');
        longitude = double.tryParse(coordMatch.group(2) ?? '');
      }
    }
    
    // Extract address/location name
    var addressMatch = RegExp(r'- Nombre del lugar:\s*(.+)', multiLine: true).firstMatch(desc);
    if (addressMatch != null) {
      address = addressMatch.group(1)?.trim();
    }
    
    // Fallback to "Dirección"
    if (address == null) {
      addressMatch = RegExp(r'- Dirección:\s*(.+)', multiLine: true).firstMatch(desc);
      if (addressMatch != null) {
        address = addressMatch.group(1)?.trim();
      }
    }
    
    return {'latitude': latitude, 'longitude': longitude, 'address': address};
  }

  Map<String, String?> _extractKermesseInfo(String desc) {
    String? date;
    String? beneficiaries;
    String? purpose;
    String? menu;
    String? shows;
    
    // Extract date and time
    final dateMatch = RegExp(r'- Fecha y horario de inicio:\s*(.+)', multiLine: true).firstMatch(desc);
    if (dateMatch != null) {
      date = dateMatch.group(1)?.trim();
    }
    
    // Extract beneficiaries
    final benefMatch = RegExp(r'- ¿Quiénes se beneficiarán\?:\s*(.+)', multiLine: true).firstMatch(desc);
    if (benefMatch != null) {
      beneficiaries = benefMatch.group(1)?.trim();
    }
    
    // Extract purpose
    final purposeMatch = RegExp(r'- ¿Para qué se usa lo recaudado\?:\s*(.+)', multiLine: true).firstMatch(desc);
    if (purposeMatch != null) {
      purpose = purposeMatch.group(1)?.trim();
    }
    
    // Extract menu - everything after "Menu y precios sugeridos:" until next section
    final menuMatch = RegExp(r'Menu y precios sugeridos:\s*\n((?:-.+\n?)+)', multiLine: true).firstMatch(desc);
    if (menuMatch != null) {
      menu = menuMatch.group(1)?.trim();
    }
    
    // Extract shows - everything after "Shows y actividades confirmadas:" until next section
    final showsMatch = RegExp(r'Shows y actividades confirmadas:\s*\n((?:-.+\n?)+)', multiLine: true).firstMatch(desc);
    if (showsMatch != null) {
      shows = showsMatch.group(1)?.trim();
    }
    
    return {
      'date': date,
      'beneficiaries': beneficiaries,
      'purpose': purpose,
      'menu': menu,
      'shows': shows,
    };
  }

  Future<List<AdminActiveCampaign>> fetchActiveCampaigns({int limit = 6}) async {
    final response = await _client
        .from('campanias')
        .select('id, titulo, estado, monto_objetivo, monto_actual, updated_at')
        .inFilter('estado', ['activa', 'publicada', 'en_progreso'])
        .order('updated_at', ascending: false)
        .limit(limit);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return rows.map(AdminActiveCampaign.fromJson).toList();
  }

  Future<List<AdminPendingItem>> fetchPendingDonations() async {
    final response = await _client
        .from('donaciones')
        .select('id, monto, created_at, campanias!inner(titulo)')
        .eq('estado', 'pendiente')
        .order('created_at', ascending: false);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return rows
        .map(
          (row) {
            final campaignData = row['campanias'] as Map<String, dynamic>?;
            final campaignTitle = campaignData?['titulo'] as String? ?? 'Campaña sin título';
            
            return AdminPendingItem(
              id: row['id'] as String,
              title: 'Donación pendiente - ${_formatCurrency(row['monto'])}',
              subtitle: campaignTitle,
              type: AdminItemType.donationReview,
              createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
            );
          },
        )
        .toList();
  }

  Future<AdminDonationDetail> fetchDonationDetail(String donationId) async {
    try {
      final Map<String, dynamic>? donation = await _client
          .from('donaciones')
          .select(
            'id, campania_id, user_id, recompensa_id, monto, comprobante_url, mensaje, metodo, referencia, anonimo, estado, admin_validador, fecha_validacion, created_at',
          )
          .eq('id', donationId)
          .maybeSingle();

      if (donation == null) {
        throw const AdminServiceException('La donación ya no está disponible.');
      }

      String? campaignTitle;
      String? campaignStatus;
      final campaignId = donation['campania_id'] as String?;
      if (campaignId != null && campaignId.isNotEmpty) {
        final campaign = await _client
            .from('campanias')
            .select('titulo, estado')
            .eq('id', campaignId)
            .maybeSingle();
        campaignTitle = _trimOrNull(campaign?['titulo'] as String?);
        campaignStatus = _trimOrNull(campaign?['estado'] as String?);
      }

      String? donorName;
      String? donorEmail;
      String? donorPhone;
      final donorId = donation['user_id'] as String?;
      if (donorId != null && donorId.isNotEmpty) {
        // Obtener datos del perfil
        final profile = await _client
            .from('profiles')
            .select('display_name, telefono')
            .eq('user_id', donorId)
            .maybeSingle();
        donorName = _trimOrNull(profile?['display_name'] as String?);
        donorPhone = _trimOrNull(profile?['telefono'] as String?);
        
        // Obtener email de auth.users
        try {
          final user = await _client.auth.admin.getUserById(donorId);
          donorEmail = user.user?.email;
        } catch (_) {
          // Si no tenemos permisos admin, intentar desde la sesión actual
          final currentUser = _client.auth.currentUser;
          if (currentUser?.id == donorId) {
            donorEmail = currentUser?.email;
          }
        }
      }

      String? rewardTitle;
      final rewardId = donation['recompensa_id'] as String?;
      if (rewardId != null && rewardId.isNotEmpty) {
        final reward = await _client
            .from('recompensas')
            .select('titulo')
            .eq('id', rewardId)
            .maybeSingle();
        rewardTitle = _trimOrNull(reward?['titulo'] as String?);
      }

      // Crear un mapa con los datos adicionales que no están en la tabla donaciones
      final enrichedDonation = Map<String, dynamic>.from(donation);
      enrichedDonation['numero_operacion'] = null; // Campo futuro
      enrichedDonation['entidad_bancaria'] = null; // Campo futuro
      enrichedDonation['ip_registro'] = null; // Campo futuro
      
      return AdminDonationDetail.fromJson(
        enrichedDonation,
        campaignTitle: campaignTitle,
        campaignStatus: campaignStatus,
        donorName: donorName,
        donorEmail: donorEmail,
        donorPhone: donorPhone,
        rewardTitle: rewardTitle,
      );
    } on PostgrestException catch (error) {
      throw AdminServiceException(error.message);
    } on AdminServiceException {
      rethrow;
    } catch (_) {
      throw const AdminServiceException('No pudimos cargar el detalle de la donación.');
    }
  }

  Future<List<AdminPendingItem>> fetchPendingOrganizations() async {
    final response = await _client
        .from('organizaciones')
        .select('id, nombre, created_at')
        .eq('estado', 'pendiente')
        .order('created_at', ascending: false);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return rows
        .map(
          (row) => AdminPendingItem(
            id: row['id'] as String,
            title: row['nombre'] as String,
            subtitle: 'Solicitud de verificación pendiente',
            type: AdminItemType.organizationReview,
            createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
          ),
        )
        .toList();
  }

  Future<AdminOrganizationDetail> fetchOrganizationDetail(String organizationId) async {
    try {
      final Map<String, dynamic>? organization = await _client
          .from('organizaciones')
          .select(
            'id, nombre, tipo, descripcion, telefono, email, sitio_web, direccion, logo_url, estado, notas_admin, owner_id, created_at, updated_at',
          )
          .eq('id', organizationId)
          .maybeSingle();

      if (organization == null) {
        throw const AdminServiceException('La organización ya no está disponible.');
      }

      Map<String, dynamic>? ownerProfile;
      final ownerId = organization['owner_id'] as String?;
      if (ownerId != null && ownerId.isNotEmpty) {
        ownerProfile = await _client
            .from('profiles')
            .select('user_id, display_name, telefono, ciudad, documento_tipo, documento_numero')
            .eq('user_id', ownerId)
            .maybeSingle();
      }

      final documents = <Map<String, dynamic>>[];
      try {
        dynamic response;
        if (ownerId != null && ownerId.isNotEmpty) {
          response = await _client
              .from('kyc_documentos')
              .select(
                'id, tipo, archivo_url, estado, notas_admin, created_at, updated_at, owner_type, owner_org_id, owner_user_id',
              )
              .or(
                'and(owner_type.eq.organizacion,owner_org_id.eq.$organizationId),and(owner_type.eq.user,owner_user_id.eq.$ownerId)',
              )
              .order('created_at', ascending: true);
        } else {
          response = await _client
              .from('kyc_documentos')
              .select(
                'id, tipo, archivo_url, estado, notas_admin, created_at, updated_at, owner_type, owner_org_id, owner_user_id',
              )
              .eq('owner_type', 'organizacion')
              .eq('owner_org_id', organizationId)
              .order('created_at', ascending: true);
        }

        documents.addAll((response as List<dynamic>).cast<Map<String, dynamic>>());
      } on PostgrestException catch (error) {
        throw AdminServiceException(error.message);
      }

      return AdminOrganizationDetail.fromJson(
        organization,
        ownerProfile: ownerProfile,
        documents: documents,
      );
    } on PostgrestException catch (error) {
      throw AdminServiceException(error.message);
    } on AdminServiceException {
      rethrow;
    } catch (_) {
      throw const AdminServiceException('No pudimos cargar el detalle de la organización.');
    }
  }

  Future<void> reviewDonation({
    required String donationId,
    required bool approve,
  }) async {
    final adminId = _currentUserId;
    if (adminId == null) {
      throw const AdminServiceException('Debes iniciar sesión como administrador.');
    }

    final decision = approve ? 'aprobada' : 'rechazada';
    final payload = {
      'estado': decision,
      'admin_validador': adminId,
      'fecha_validacion': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final Map<String, dynamic>? updated = await _client
          .from('donaciones')
          .update(payload)
          .eq('id', donationId)
          .eq('estado', 'pendiente')
          .select('id')
          .maybeSingle();

      if (updated == null) {
        throw const AdminServiceException(
          'La donación ya fue revisada o no está disponible.',
        );
      }
    } on PostgrestException catch (error) {
      throw AdminServiceException(error.message);
    } on AdminServiceException {
      rethrow;
    } catch (_) {
      throw const AdminServiceException('No pudimos actualizar la donación.');
    }
  }

  Future<double> _fetchApprovedDonationSum() async {
    final response = await _client
        .from('donaciones')
        .select('monto')
        .eq('estado', 'aprobada');

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    double total = 0;
    for (final row in rows) {
      final monto = row['monto'];
      if (monto is num) {
        total += monto.toDouble();
      }
    }
    return total;
  }

  String _formatCurrency(dynamic value) {
    if (value is num) {
      return 'Bs ${value.toStringAsFixed(2)}';
    }
    return 'Bs --';
  }

  String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> reviewCampaignRequest({
    required String solicitudId,
    required bool approve,
    String? message,
    String? categoriaId,
  }) async {
    final adminId = _currentUserId;
    if (adminId == null) {
      throw const AdminServiceException('Debes iniciar sesión como administrador.');
    }

    final trimmedMessage = message?.trim();
    if (!approve && (trimmedMessage == null || trimmedMessage.isEmpty)) {
      throw const AdminServiceException('Añade un mensaje para solicitar cambios.');
    }

    try {
      final Map<String, dynamic>? solicitud = await _client
          .from('solicitudes')
          .select('id, tipo, categoria_id')
          .eq('id', solicitudId)
          .maybeSingle();

      if (solicitud == null) {
        throw const AdminServiceException('La solicitud ya no está disponible.');
      }

      final solicitudTipo = solicitudTipoFromCode(solicitud['tipo'] as String?);

      if (approve) {
        // If admin provided a category, update the solicitud first
        if (categoriaId != null) {
          await _client
              .from('solicitudes')
              .update({'categoria_id': categoriaId})
              .eq('id', solicitudId);
        } else if (solicitud['categoria_id'] == null) {
          // Require category for campaigns if not already set
          if (solicitudTipo == SolicitudTipo.campania) {
            throw const AdminServiceException('Debes seleccionar una categoría para aprobar esta campaña.');
          }
        }

        if (solicitudTipo == SolicitudTipo.campania) {
          await _publishCampaignFromSolicitud(
            solicitudId: solicitudId,
            adminId: adminId,
          );
        } else {
          await _approveNonCampaignSolicitud(
            solicitudId: solicitudId,
            adminId: adminId,
          );
        }
        return;
      }

      await _client
          .from('solicitudes')
          .update({
            'estado': 'rechazada',
            'motivo_rechazo': trimmedMessage,
          })
          .eq('id', solicitudId);

      await _client.from('solicitud_reviews').insert({
        'solicitud_id': solicitudId,
        'admin_id': adminId,
        'decision': 'rechazada',
        'motivo': trimmedMessage,
      });
    } on PostgrestException catch (error) {
      throw AdminServiceException(error.message);
    } on AdminServiceException {
      rethrow;
    } catch (_) {
      throw const AdminServiceException('No pudimos actualizar la solicitud.');
    }
  }

  Future<void> reviewOrganization({
    required String organizationId,
    required bool approve,
    String? message,
  }) async {
    final adminId = _currentUserId;
    if (adminId == null) {
      throw const AdminServiceException('Debes iniciar sesión como administrador.');
    }

    final trimmedMessage = message?.trim();
    if (!approve && (trimmedMessage == null || trimmedMessage.isEmpty)) {
      throw const AdminServiceException('Describe el motivo del rechazo para notificar a la organización.');
    }

    final payload = <String, dynamic>{
      'estado': approve ? 'aprobada' : 'rechazada',
      'notas_admin': trimmedMessage,
    };

    if (approve && (trimmedMessage == null || trimmedMessage.isEmpty)) {
      payload['notas_admin'] = null;
    }

    try {
      final Map<String, dynamic>? updated = await _client
          .from('organizaciones')
          .update(payload)
          .eq('id', organizationId)
          .eq('estado', 'pendiente')
          .select('id')
          .maybeSingle();

      if (updated == null) {
        throw const AdminServiceException('La organización ya fue revisada o no está disponible.');
      }
    } on PostgrestException catch (error) {
      throw AdminServiceException(error.message);
    }
  }

  Future<void> _publishCampaignFromSolicitud({
    required String solicitudId,
    required String adminId,
  }) async {
    try {
      final result = await _client.rpc(
        'publish_campaign_from_solicitud',
        params: {
          'p_solicitud_id': solicitudId,
          'p_admin_id': adminId,
        },
      );

      if (result == null) {
        throw const AdminServiceException('No pudimos registrar la campaña publicada.');
      }
    } on PostgrestException catch (error) {
      throw AdminServiceException(error.message);
    }
  }

  Future<void> _approveNonCampaignSolicitud({
    required String solicitudId,
    required String adminId,
  }) async {
    await _client
        .from('solicitudes')
        .update({
          'estado': 'aprobada',
          'motivo_rechazo': null,
        })
        .eq('id', solicitudId);

    await _client.from('solicitud_reviews').insert({
      'solicitud_id': solicitudId,
      'admin_id': adminId,
      'decision': 'aprobada',
    });
  }
}

class AdminServiceException implements Exception {
  const AdminServiceException(this.message);

  final String message;

  @override
  String toString() => 'AdminServiceException: $message';
}
