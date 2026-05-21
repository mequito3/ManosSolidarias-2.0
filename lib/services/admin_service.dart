import 'package:flutter/foundation.dart' hide Category;
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

  /// Métricas consolidadas del dashboard admin.
  ///
  /// Usa el RPC `get_admin_dashboard_metrics()` que devuelve TODO calculado
  /// server-side con agregados SQL en un solo round-trip. Reemplaza 8 queries
  /// y ~150 líneas de loops O(N) en Dart que procesaban las listas completas.
  Future<AdminDashboardMetrics> fetchDashboardMetrics() async {
    try {
      final response = await _client.rpc('get_admin_dashboard_metrics');

      if (response == null) {
        return _emptyMetrics();
      }

      final json = Map<String, dynamic>.from(response as Map);

      double asDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
      int asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
      String asString(dynamic v) => v?.toString() ?? '';

      return AdminDashboardMetrics(
        pendingRequests: asInt(json['pendingRequests']),
        pendingDonations: asInt(json['pendingDonations']),
        pendingOrganizations: asInt(json['pendingOrganizations']),
        activeCampaigns: asInt(json['activeCampaigns']),
        totalApprovedAmount: asDouble(json['totalApprovedAmount']),
        approvalRate: asDouble(json['approvalRate']),
        avgResponseTimeHours: asDouble(json['avgResponseTimeHours']),
        totalDonors: asInt(json['totalDonors']),
        repeatDonorsPercentage: asDouble(json['repeatDonorsPercentage']),
        campaignsCompletedThisMonth:
            asInt(json['campaignsCompletedThisMonth']),
        donationsThisMonth: asInt(json['donationsThisMonth']),
        donationsLastMonth: asInt(json['donationsLastMonth']),
        donationGrowthRate: asDouble(json['donationGrowthRate']),
        avgDonationAmount: asDouble(json['avgDonationAmount']),
        topCampaignCategory:
            asString(json['topCampaignCategory']).isEmpty
                ? 'N/A'
                : asString(json['topCampaignCategory']),
      );
    } catch (e) {
      debugPrint('Error in fetchDashboardMetrics RPC: $e');
      return _emptyMetrics();
    }
  }

  AdminDashboardMetrics _emptyMetrics() => const AdminDashboardMetrics(
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
        .select('id, titulo, descripcion, tipo, portada_url, portada_original_url, categoria_id, created_at, es_anonimo')
        .eq('estado', 'pendiente')
        .order('created_at', ascending: false);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();

    // Cargar evidencias enriquecidas (id + url_original) en una sola query,
    // y agruparlas por solicitud_id. Si falla, dejamos cada item sin
    // evidenceItems y el render hace fallback a evidenceUrls (regex legacy).
    final solicitudIds = rows.map((r) => r['id'] as String).toList(growable: false);
    final Map<String, List<AdminEvidenceItem>> evidenciasBySolicitud = {};
    if (solicitudIds.isNotEmpty) {
      try {
        final evRes = await _client
            .from('evidencias')
            .select('id, solicitud_id, url, url_original')
            .inFilter('solicitud_id', solicitudIds);
        final evRows = (evRes as List<dynamic>).cast<Map<String, dynamic>>();
        for (final ev in evRows) {
          final sid = ev['solicitud_id'] as String?;
          final url = ev['url'] as String?;
          final id = ev['id'] as String?;
          if (sid == null || url == null || id == null) continue;
          evidenciasBySolicitud.putIfAbsent(sid, () => []).add(
                AdminEvidenceItem(
                  id: id,
                  url: url,
                  urlOriginal: ev['url_original'] as String?,
                ),
              );
        }
      } catch (e) {
        debugPrint('AdminService.fetchPendingCampaignRequests evidencias error: $e');
      }
    }

    return rows
        .map(
          (row) {
            final desc = row['descripcion'] as String? ?? '';
            final tipo = solicitudTipoFromCode(row['tipo'] as String?);
            final beneficiaryInfo = _extractBeneficiaryInfo(desc);
            final solicitudId = row['id'] as String;
            final evItems = evidenciasBySolicitud[solicitudId];
            // Si hay evidencias en la tabla, usamos esas; si no, caemos al
            // legacy de extraer urls de la descripción.
            final evidenceUrls = (evItems != null && evItems.isNotEmpty)
                ? evItems.map((e) => e.url).toList(growable: false)
                : _extractEvidenceUrls(desc);
            final locationInfo = _extractLocationInfo(desc);
            final kermesseInfo = tipo == SolicitudTipo.kermesse ? _extractKermesseInfo(desc) : null;

            return AdminPendingItem(
              id: solicitudId,
              title: row['titulo'] as String,
              subtitle: _cleanDescription(desc),
              type: AdminItemType.campaignRequest,
              createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
              solicitudTipo: tipo,
              categoriaId: row['categoria_id'] as String?,
              beneficiaryName: beneficiaryInfo['name'],
              beneficiaryRelation: beneficiaryInfo['relation'],
              evidenceUrls: evidenceUrls,
              evidenceItems: evItems,
              coverUrl: row['portada_url'] as String?,
              coverOriginalUrl: row['portada_original_url'] as String?,
              kermesseLatitude: locationInfo['latitude'],
              kermesseLongitude: locationInfo['longitude'],
              kermesseAddress: locationInfo['address'],
              kermesseDate: kermesseInfo?['date'],
              kermesseBeneficiaries: kermesseInfo?['beneficiaries'],
              kermessePurpose: kermesseInfo?['purpose'],
              kermesseMenu: kermesseInfo?['menu'],
              kermesseShows: kermesseInfo?['shows'],
              esAnonimo: (row['es_anonimo'] as bool?) ?? false,
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

      final campaignId = donation['campania_id'] as String?;
      final donorId = donation['user_id'] as String?;
      final rewardId = donation['recompensa_id'] as String?;

      // 3 lookups secundarios EN PARALELO: campaña, perfil del donor, recompensa.
      final results = await Future.wait<dynamic>([
        if (campaignId != null && campaignId.isNotEmpty)
          _client
              .from('campanias')
              .select('titulo, estado')
              .eq('id', campaignId)
              .maybeSingle()
              .catchError((Object _) => null)
        else
          Future<Map<String, dynamic>?>.value(null),
        if (donorId != null && donorId.isNotEmpty)
          _client
              .from('profiles')
              .select('display_name, telefono')
              .eq('user_id', donorId)
              .maybeSingle()
              .catchError((Object _) => null)
        else
          Future<Map<String, dynamic>?>.value(null),
        if (rewardId != null && rewardId.isNotEmpty)
          _client
              .from('recompensas')
              .select('titulo')
              .eq('id', rewardId)
              .maybeSingle()
              .catchError((Object _) => null)
        else
          Future<Map<String, dynamic>?>.value(null),
      ]);

      final campaign = results[0] as Map<String, dynamic>?;
      final profile = results[1] as Map<String, dynamic>?;
      final reward = results[2] as Map<String, dynamic>?;

      final campaignTitle = _trimOrNull(campaign?['titulo'] as String?);
      final campaignStatus = _trimOrNull(campaign?['estado'] as String?);
      final donorName = _trimOrNull(profile?['display_name'] as String?);
      final donorPhone = _trimOrNull(profile?['telefono'] as String?);
      final rewardTitle = _trimOrNull(reward?['titulo'] as String?);

      // Email del donor: solo si tenemos permisos admin. NO bloquea: si falla
      // dejamos null y el UI muestra "—".
      String? donorEmail;
      if (donorId != null && donorId.isNotEmpty) {
        try {
          final user = await _client.auth.admin.getUserById(donorId);
          donorEmail = user.user?.email;
        } catch (_) {
          final currentUser = _client.auth.currentUser;
          if (currentUser?.id == donorId) {
            donorEmail = currentUser?.email;
          }
        }
      }

      final enrichedDonation = Map<String, dynamic>.from(donation);
      enrichedDonation['numero_operacion'] = null;
      enrichedDonation['entidad_bancaria'] = null;
      enrichedDonation['ip_registro'] = null;

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

      final ownerId = organization['owner_id'] as String?;

      // Perfil del owner + documentos KYC en PARALELO.
      final results = await Future.wait<dynamic>([
        if (ownerId != null && ownerId.isNotEmpty)
          _client
              .from('profiles')
              .select(
                  'user_id, display_name, telefono, ciudad, documento_tipo, documento_numero')
              .eq('user_id', ownerId)
              .maybeSingle()
              .catchError((Object _) => null)
        else
          Future<Map<String, dynamic>?>.value(null),
        (ownerId != null && ownerId.isNotEmpty
                ? _client
                    .from('kyc_documentos')
                    .select(
                      'id, tipo, archivo_url, estado, notas_admin, created_at, updated_at, owner_type, owner_org_id, owner_user_id',
                    )
                    .or(
                      'and(owner_type.eq.organizacion,owner_org_id.eq.$organizationId),and(owner_type.eq.user,owner_user_id.eq.$ownerId)',
                    )
                    .order('created_at', ascending: true)
                : _client
                    .from('kyc_documentos')
                    .select(
                      'id, tipo, archivo_url, estado, notas_admin, created_at, updated_at, owner_type, owner_org_id, owner_user_id',
                    )
                    .eq('owner_type', 'organizacion')
                    .eq('owner_org_id', organizationId)
                    .order('created_at', ascending: true))
            .then((value) =>
                (value as List<dynamic>).cast<Map<String, dynamic>>())
            .catchError((Object _) => <Map<String, dynamic>>[]),
      ]);

      final ownerProfile = results[0] as Map<String, dynamic>?;
      final documents = results[1] as List<Map<String, dynamic>>;

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

  /// Sube una nueva versión tachada de la portada y actualiza el campo
  /// `portada_url` de la solicitud. Útil cuando el admin retoca el tachado
  /// del usuario antes de aprobar.
  Future<String> reRedactSolicitudCover({
    required String solicitudId,
    required Uint8List newRedactedBytes,
    required String contentType,
    required String fileExtension,
  }) async {
    final solicitudRow = await _client
        .from('solicitudes')
        .select('user_id')
        .eq('id', solicitudId)
        .single();
    final userId = solicitudRow['user_id'] as String;
    final storage = _client.storage.from('documentos');
    var sanitizedExt = fileExtension.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toLowerCase();
    if (sanitizedExt.isEmpty) sanitizedExt = 'jpg';
    final ts = DateTime.now().microsecondsSinceEpoch;
    final nonce = ts.hashCode.toUnsigned(16).toRadixString(16).padLeft(4, '0');
    final objectPath = 'users/$userId/solicitudes/covers/${ts}_$nonce.$sanitizedExt';
    await storage.uploadBinary(
      objectPath,
      newRedactedBytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    final newUrl = storage.getPublicUrl(objectPath);
    await _client
        .from('solicitudes')
        .update({'portada_url': newUrl})
        .eq('id', solicitudId);
    return newUrl;
  }

  /// Sube una nueva versión tachada de una evidencia individual y actualiza
  /// el campo `url` en la fila correspondiente de la tabla `evidencias`.
  /// Mismo patrón que [reRedactSolicitudCover] pero para evidencias.
  Future<String> reRedactEvidence({
    required String evidenciaId,
    required Uint8List newRedactedBytes,
    required String contentType,
    required String fileExtension,
  }) async {
    // 1. Obtener solicitud_id de la evidencia para resolver el user_id dueño.
    final evidenciaRow = await _client
        .from('evidencias')
        .select('solicitud_id')
        .eq('id', evidenciaId)
        .single();
    final solicitudId = evidenciaRow['solicitud_id'] as String?;
    if (solicitudId == null) {
      throw const AdminServiceException(
        'La evidencia no está asociada a una solicitud (no podemos resolver el dueño para el path).',
      );
    }
    final solicitudRow = await _client
        .from('solicitudes')
        .select('user_id')
        .eq('id', solicitudId)
        .single();
    final userId = solicitudRow['user_id'] as String;

    // 2. Subir a path único bajo /users/<uid>/solicitudes/evidencias/.
    final storage = _client.storage.from('documentos');
    var sanitizedExt = fileExtension.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toLowerCase();
    if (sanitizedExt.isEmpty) sanitizedExt = 'jpg';
    final ts = DateTime.now().microsecondsSinceEpoch;
    final nonce = ts.hashCode.toUnsigned(16).toRadixString(16).padLeft(4, '0');
    final objectPath = 'users/$userId/solicitudes/evidencias/${ts}_$nonce.$sanitizedExt';
    await storage.uploadBinary(
      objectPath,
      newRedactedBytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    final newUrl = storage.getPublicUrl(objectPath);

    // 3. Actualizar la fila apuntando a la nueva versión tachada.
    await _client
        .from('evidencias')
        .update({'url': newUrl})
        .eq('id', evidenciaId);
    return newUrl;
  }
}

class AdminServiceException implements Exception {
  const AdminServiceException(this.message);

  final String message;

  @override
  String toString() => 'AdminServiceException: $message';
}
