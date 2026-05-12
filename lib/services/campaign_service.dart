import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/campaign.dart';
import '../models/category.dart' as my_category;

class CampaignService {
  CampaignService(this._client);

  final SupabaseClient _client;

  bool get hasAuthenticatedUser => _client.auth.currentUser != null;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<my_category.Category>> fetchCategories() async {
    try {
      final response = await _client
          .from('categorias')
          .select()
          .eq('activa', true)
          .order('orden', ascending: true);
      
      final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
      return data.map(my_category.Category.fromJson).toList();
    } catch (error, stackTrace) {
      debugPrint('CampaignService.fetchCategories error: $error');
      return []; // Devolvemos vacío si falla para no romper el buscador
    }
  }

  Future<List<CampaignSummary>> fetchActiveCampaigns({
    String? category,
    int? limit,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (category != null && category.isNotEmpty) {
        params['p_category'] = category;
      }
      if (limit != null && limit > 0) {
        params['p_limit'] = limit;
      }

      final response = await _client.rpc(
        'list_public_campaigns',
        params: params.isEmpty ? null : params,
      );

      final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
      final campaigns = data.map(CampaignSummary.fromPublicView).toList();
  return await _markFavorites(campaigns);
    } catch (error, stackTrace) {
      debugPrint('CampaignService.fetchActiveCampaigns error: $error');
      Error.throwWithStackTrace(
        CampaignServiceException('No pudimos cargar las campañas activas.'),
        stackTrace,
      );
    }
  }

  Future<CampaignDetail?> fetchCampaignDetail(String campaignId) async {
    try {
      // IMPORTANTE: NO filtrar por estado aquí
      // Debe poder cargar campañas archivadas (que llegaron a 100%)
      final detailResponse = await _client
          .from('campanias')
          .select('*, categorias(nombre)')
          .eq('id', campaignId)
          .maybeSingle();

      if (detailResponse == null) {
        return null;
      }

      // Intentar obtener perfil del creador de forma segura
      try {
        final creadorId = detailResponse['creador_id'] as String?;
        if (creadorId != null && creadorId.isNotEmpty) {
          final profileResponse = await _client
              .from('profiles')
              .select('display_name, avatar_url')
              .eq('user_id', creadorId)
              .maybeSingle();
          
          if (profileResponse != null) {
            detailResponse['creator'] = profileResponse;
            debugPrint('✅ Creator profile loaded: ${profileResponse['display_name']}');
          }
        }
      } catch (profileError) {
        // Si falla la carga del perfil, continuamos sin él
        debugPrint('⚠️ Could not load creator profile: $profileError');
      }

  var rewards = <Map<String, dynamic>>[];
      try {
        final response = await _client
            .from('recompensas')
            .select()
            .eq('campania_id', campaignId);
        rewards = (response as List<dynamic>).cast<Map<String, dynamic>>();
      } catch (error) {
        debugPrint('CampaignService.fetchCampaignDetail rewards error: $error');
      }

      // La tabla 'actualizaciones' (novedades de campaña) aún no existe en el schema.
      // Se deja como lista vacía hasta que se cree en Supabase.
      final updates = <Map<String, dynamic>>[];

      var evidences = <Map<String, dynamic>>[];
      try {
        final response = await _client
            .from('evidencias')
            .select()
            .eq('campania_id', campaignId)
            .order('created_at', ascending: false);
        evidences = (response as List<dynamic>).cast<Map<String, dynamic>>();
      } catch (error) {
        debugPrint('CampaignService.fetchCampaignDetail evidences error: $error');
      }

      Map<String, dynamic>? paymentInstructionRow;
      try {
        final response = await _client.rpc(
          'get_campaign_payment_instructions',
          params: {'p_campaign_id': campaignId},
        );

        if (response is List && response.isNotEmpty) {
          final first = response.first;
          if (first is Map<String, dynamic>) {
            paymentInstructionRow = first;
          }
        } else if (response is Map<String, dynamic>) {
          paymentInstructionRow = response;
        }
      } catch (error) {
        debugPrint('CampaignService.fetchCampaignDetail payment instructions error: $error');
      }

      Map<String, dynamic>? publicViewRow;
      try {
        publicViewRow = await _client
            .from('v_campania_publica')
            .select('monto_objetivo, monto_actual, porcentaje, donadores')
            .eq('id', campaignId)
            .maybeSingle();
      } catch (error) {
        debugPrint('CampaignService.fetchCampaignDetail public view error: $error');
      }

      final detailJson = Map<String, dynamic>.from(detailResponse);
      if (publicViewRow != null) {
        detailJson
          ..addAll(publicViewRow)
          ..['donor_count'] = publicViewRow['donadores'];
      }

      return CampaignDetail.fromJson(
        detailJson,
        rewards: rewards,
        updates: updates,
        evidences: evidences,
        paymentInstructionRow: paymentInstructionRow,
      );
    } catch (error, stackTrace) {
      debugPrint('CampaignService.fetchCampaignDetail error: $error');
      Error.throwWithStackTrace(
        CampaignServiceException('No pudimos cargar el detalle de la campaña.'),
        stackTrace,
      );
    }
  }

  Future<List<CampaignComment>> fetchComments(String campaignId) async {
    try {
      final response = await _client
          .from('comentarios')
          .select(
            'id, contenido, created_at, estado, user_id, autor_nombre, autor_avatar_url',
          )
          .eq('campania_id', campaignId)
          .eq('estado', 'visible')
          .order('created_at', ascending: false)
          .limit(50);

      final data = (response as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      return data.map(CampaignComment.fromJson).toList();
    } catch (error, stackTrace) {
      debugPrint('CampaignService.fetchComments error: $error');
      Error.throwWithStackTrace(
        CampaignServiceException('No pudimos cargar los comentarios de la campaña.'),
        stackTrace,
      );
    }
  }

  Future<CampaignComment> createComment({
    required String campaignId,
    required String message,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw CampaignServiceException('Debes iniciar sesión para comentar.');
    }

    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw CampaignServiceException('Escribe tu mensaje antes de publicarlo.');
    }

    try {
      final profileResponse = await _client
          .from('profiles')
          .select('display_name, avatar_url')
          .eq('user_id', userId)
          .maybeSingle();

      String? displayName;
      String? avatarUrl;
      if (profileResponse != null) {
        final profileMap = Map<String, dynamic>.from(profileResponse as Map);
        displayName = profileMap['display_name'] as String?;
        avatarUrl = profileMap['avatar_url'] as String?;
      }

      final resolvedName = (displayName?.trim().isNotEmpty ?? false)
          ? displayName!.trim()
          : 'Miembro solidario';
      final resolvedAvatar = (avatarUrl?.trim().isNotEmpty ?? false) ? avatarUrl!.trim() : null;

      final response = await _client
          .from('comentarios')
          .insert(
            {
              'campania_id': campaignId,
              'user_id': userId,
              'contenido': trimmed,
              'autor_nombre': resolvedName,
              'autor_avatar_url': resolvedAvatar,
            },
          )
          .select('id, contenido, created_at, estado, user_id, autor_nombre, autor_avatar_url')
          .single();

      final data = Map<String, dynamic>.from(response as Map);
      return CampaignComment.fromJson(data);
    } on CampaignServiceException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('CampaignService.createComment error: $error');
      Error.throwWithStackTrace(
        CampaignServiceException('No pudimos publicar tu comentario. Intenta nuevamente.'),
        stackTrace,
      );
    }
  }

  Future<List<CampaignSummary>> searchCampaigns(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) {
      return fetchActiveCampaigns(limit: 20);
    }

    try {
      final response = await _client.rpc(
        'search_public_campaigns',
        params: {
          'p_term': trimmed,
        },
      );

      final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
      final campaigns = data.map(CampaignSummary.fromPublicView).toList();
  return await _markFavorites(campaigns);
    } catch (error, stackTrace) {
      debugPrint('CampaignService.searchCampaigns error: $error');
      Error.throwWithStackTrace(
        CampaignServiceException('No pudimos buscar campañas con ese término.'),
        stackTrace,
      );
    }
  }

  Future<void> setFavorite(String campaignId, {required bool shouldFavorite}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw CampaignServiceException('Debes iniciar sesión para gestionar favoritos.');
    }

    try {
      if (shouldFavorite) {
        await _client
            .from('favoritos')
            .upsert(
              {
                'user_id': userId,
                'campania_id': campaignId,
              },
              onConflict: 'user_id,campania_id',
            );
      } else {
        await _client
            .from('favoritos')
            .delete()
            .match({'user_id': userId, 'campania_id': campaignId});
      }
    } catch (error, stackTrace) {
      debugPrint('CampaignService.setFavorite error: $error');
      Error.throwWithStackTrace(
        CampaignServiceException('No pudimos actualizar tus favoritos. Intenta nuevamente.'),
        stackTrace,
      );
    }
  }

  Future<void> createDonation({
    required String campaignId,
    required double amount,
    String method = 'qr',
    String? message,
    String? reference,
    bool anonymous = false,
    String? rewardId,
    Uint8List? receiptBytes,
    String? receiptFileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw CampaignServiceException('Debes iniciar sesión para registrar una donación.');
    }

    if (amount <= 0) {
      throw CampaignServiceException('Ingresa un monto válido para continuar.');
    }

    final normalizedMethod = method.trim().toLowerCase();
    if (normalizedMethod != 'qr' && normalizedMethod != 'transferencia' && normalizedMethod != 'otro') {
      throw CampaignServiceException('Selecciona un método de pago válido.');
    }

    final payload = <String, dynamic>{
      'campania_id': campaignId,
      'user_id': userId,
      'monto': amount,
      'metodo': normalizedMethod,
      'anonimo': anonymous,
    };

    if (message != null && message.trim().isNotEmpty) {
      payload['mensaje'] = message.trim();
    }
    if (reference != null && reference.trim().isNotEmpty) {
      payload['referencia'] = reference.trim();
    }

    String? resolvedRewardId;
    if (rewardId != null && rewardId.trim().isNotEmpty) {
      resolvedRewardId = rewardId.trim();
    } else {
      resolvedRewardId = await _pickRewardAutomatically(
        campaignId: campaignId,
        amount: amount,
      );
    }
    if (resolvedRewardId != null && resolvedRewardId.isNotEmpty) {
      payload['recompensa_id'] = resolvedRewardId;
    }

    try {
      if (receiptBytes != null && receiptBytes.isNotEmpty) {
        final receiptUrl = await _uploadReceipt(
          userId: userId,
          campaignId: campaignId,
          bytes: receiptBytes,
          originalFileName: receiptFileName,
        );
        payload['comprobante_url'] = receiptUrl;
      }

      await _client.from('donaciones').insert(payload);
    } on CampaignServiceException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('CampaignService.createDonation error: $error');
      Error.throwWithStackTrace(
        CampaignServiceException('No pudimos registrar tu donación. Intenta nuevamente.'),
        stackTrace,
      );
    }
  }

  Future<String?> _pickRewardAutomatically({
    required String campaignId,
    required double amount,
  }) async {
    try {
      final response = await _client
          .from('recompensas')
          .select('id, monto_minimo, cantidad_limite, cantidad_reclamada')
          .eq('campania_id', campaignId)
          .order('monto_minimo', ascending: true);

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
      String? candidate;

      for (final row in rows) {
        final rewardId = row['id']?.toString();
        if (rewardId == null || rewardId.isEmpty) {
          continue;
        }

        final minAmount = (row['monto_minimo'] as num?)?.toDouble() ?? 0;
        if (amount < minAmount) {
          continue;
        }

        final limit = (row['cantidad_limite'] as num?)?.toInt();
        final claimed = (row['cantidad_reclamada'] as num?)?.toInt() ?? 0;
        if (limit != null && limit <= claimed) {
          continue;
        }

        candidate = rewardId;
      }

      return candidate;
    } catch (error) {
      debugPrint('CampaignService._pickRewardAutomatically error: $error');
      return null;
    }
  }

  Future<List<CampaignSummary>> _markFavorites(List<CampaignSummary> campaigns) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || campaigns.isEmpty) {
      return campaigns;
    }

    try {
      final response = await _client
          .from('favoritos')
          .select('campania_id')
          .eq('user_id', userId);

      final favorites = <String>{
        for (final row in (response as List<dynamic>))
          if (row is Map<String, dynamic> && row['campania_id'] != null)
            row['campania_id'].toString(),
      };

      if (favorites.isEmpty) {
        return campaigns;
      }

      return campaigns
          .map((campaign) => favorites.contains(campaign.id)
              ? campaign.copyWith(isFavorite: true)
              : campaign)
          .toList();
    } catch (error) {
      debugPrint('CampaignService._markFavorites error: $error');
      return campaigns;
    }
  }

  Future<String> _uploadReceipt({
    required String userId,
    required String campaignId,
    required Uint8List bytes,
    String? originalFileName,
  }) async {
    final extension = _extractFileExtension(originalFileName) ?? 'jpg';
    final normalizedExtension = extension.toLowerCase();
    final storage = _client.storage.from('comprobantes');
    final path = 'users/$userId/donaciones/$campaignId/${DateTime.now().microsecondsSinceEpoch}.$normalizedExtension';

    try {
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: _contentTypeForExtension(normalizedExtension),
          upsert: false,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('CampaignService._uploadReceipt error: $error');
      Error.throwWithStackTrace(
        CampaignServiceException('No pudimos subir el comprobante de tu donación. Intenta nuevamente.'),
        stackTrace,
      );
    }

    return storage.getPublicUrl(path);
  }

  String? _extractFileExtension(String? fileName) {
    if (fileName == null) {
      return null;
    }
    final trimmed = fileName.trim();
    final dotIndex = trimmed.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == trimmed.length - 1) {
      return null;
    }
    return trimmed.substring(dotIndex + 1);
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'bmp':
        return 'image/bmp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  /// Obtiene todas las solicitudes de campaña del usuario actual
  /// Incluye solicitudes pendientes, aprobadas y rechazadas
  Future<List<CampaignSummary>> fetchMyRequests() async {
    try {
      if (!hasAuthenticatedUser) {
        throw CampaignServiceException('Debes iniciar sesión para ver tus solicitudes.');
      }

      // Obtener solicitudes del usuario
      final requestsResponse = await _client
          .from('solicitudes')
          .select('''
            id,
            titulo,
            descripcion,
            portada_url,
            estado,
            monto_objetivo,
            created_at
          ''')
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> requestsData = 
          (requestsResponse as List).cast<Map<String, dynamic>>();

      final summaries = <CampaignSummary>[];
      
      for (final request in requestsData) {
        final requestId = request['id'] as String;
        
        // Buscar campaña asociada a esta solicitud
        Map<String, dynamic>? campaniaData;
        try {
          final campaniaResponse = await _client
              .from('campanias')
              .select('id, slug, monto_objetivo, monto_actual')
              .eq('solicitud_id', requestId)
              .maybeSingle();
          
          if (campaniaResponse != null) {
            campaniaData = campaniaResponse;
          }
        } catch (e) {
          debugPrint('Error fetching campaign for request $requestId: $e');
        }

        // Calcular montos y progreso
        final goalAmount = campaniaData != null 
            ? ((campaniaData['monto_objetivo'] as num?)?.toDouble() ?? 0.0)
            : ((request['monto_objetivo'] as num?)?.toDouble() ?? 0.0);
        final raisedAmount = campaniaData != null
            ? ((campaniaData['monto_actual'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        final completionPercentage = goalAmount > 0 
            ? (raisedAmount / goalAmount * 100).clamp(0.0, 100.0)
            : 0.0;

        // Contar donantes si hay campaña
        int donorCount = 0;
        if (campaniaData != null) {
          try {
            final donationsList = await _client
                .from('donaciones')
                .select('id')
                .eq('campania_id', campaniaData['id'])
                .eq('estado', 'aprobada');
            donorCount = (donationsList as List).length;
          } catch (e) {
            debugPrint('Error counting donors: $e');
          }
        }

        // Truncar descripción para shortDescription
        final descripcion = request['descripcion'] as String? ?? '';
        final shortDesc = descripcion.length > 150 
            ? '${descripcion.substring(0, 150)}...'
            : descripcion;

        // Crear summary combinando datos
        final summary = CampaignSummary(
          id: campaniaData?['id'] as String? ?? requestId,
          slug: campaniaData?['slug'] as String? ?? '',
          title: request['titulo'] as String? ?? 'Sin título',
          shortDescription: shortDesc,
          coverUrl: request['portada_url'] as String? ?? '',
          goalAmount: goalAmount,
          raisedAmount: raisedAmount,
          completionPercentage: completionPercentage,
          donorCount: donorCount,
          category: '',
          isFavorite: false,
          creatorId: currentUserId,
          status: request['estado'] as String?,
          requestId: requestId,
        );

        summaries.add(summary);
      }

      return summaries;
    } on CampaignServiceException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('CampaignService.fetchMyRequests error: $error');
      debugPrint('Stack trace: $stackTrace');
      Error.throwWithStackTrace(
        CampaignServiceException('Error: $error'),
        stackTrace,
      );
    }
  }

  /// Elimina una solicitud de campaña pendiente sin donaciones
  /// Solo el creador puede eliminar su propia solicitud
  /// Retorna true si se eliminó exitosamente, false si no se pudo (por permisos o estado)
  Future<bool> deletePendingRequest(String requestId) async {
    try {
      if (!hasAuthenticatedUser) {
        throw CampaignServiceException('Debes iniciar sesión para eliminar una solicitud.');
      }

      // Verificar que la solicitud existe, está pendiente, es del usuario actual y no tiene donaciones
      final checkResponse = await _client
          .from('solicitudes')
          .select('id, user_id, estado')
          .eq('id', requestId)
          .maybeSingle();

      if (checkResponse == null) {
        throw CampaignServiceException('La solicitud no existe.');
      }

      final userId = checkResponse['user_id'] as String?;
      final estado = checkResponse['estado'] as String?;

      if (userId != currentUserId) {
        throw CampaignServiceException('Solo puedes eliminar tus propias solicitudes.');
      }

      if (estado != 'pendiente') {
        throw CampaignServiceException('Solo puedes eliminar solicitudes pendientes.');
      }

      // Verificar que no tenga donaciones (si existe tabla campanias relacionada)
      try {
        final campaignCheck = await _client
            .from('campanias')
            .select('id, monto_actual')
            .eq('solicitud_id', requestId)
            .maybeSingle();

        if (campaignCheck != null) {
          final montoActual = (campaignCheck['monto_actual'] as num?)?.toDouble() ?? 0;
          if (montoActual > 0) {
            throw CampaignServiceException('No puedes eliminar una solicitud que ya tiene donaciones.');
          }
        }
      } catch (e) {
        // Si no existe la relación o hay error, continuamos
        debugPrint('Verificación de donaciones: $e');
      }

      // Eliminar la solicitud
      await _client
          .from('solicitudes')
          .delete()
          .eq('id', requestId)
          .eq('user_id', currentUserId!); // Doble verificación de seguridad

      return true;
    } on CampaignServiceException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('CampaignService.deletePendingRequest error: $error');
      Error.throwWithStackTrace(
        CampaignServiceException('No pudimos eliminar la solicitud. Intenta nuevamente.'),
        stackTrace,
      );
    }
  }
}

class CampaignServiceException implements Exception {
  CampaignServiceException(this.message);

  final String message;

  @override
  String toString() => 'CampaignServiceException: $message';
}
