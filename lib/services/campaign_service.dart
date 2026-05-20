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

  /// Detalle completo de una campaña.
  ///
  /// Usa el RPC consolidado `get_campaign_full_detail` que devuelve TODO
  /// (campaña + creador + recompensas + evidencias + instrucciones de pago
  /// + stats públicos) en **un solo round-trip**. Reemplaza 6 queries
  /// secuenciales/paralelas que hacíamos antes.
  Future<CampaignDetail?> fetchCampaignDetail(String campaignId) async {
    try {
      final response = await _client.rpc(
        'get_campaign_full_detail',
        params: {'p_campaign_id': campaignId},
      );

      if (response == null) {
        return null;
      }

      final root = Map<String, dynamic>.from(response as Map);
      final campaignRaw = root['campaign'];
      if (campaignRaw == null) {
        return null;
      }

      final detailJson = Map<String, dynamic>.from(campaignRaw as Map);

      final creator = root['creator'];
      if (creator is Map) {
        detailJson['creator'] = Map<String, dynamic>.from(creator);
      }

      final publicStats = root['public_stats'];
      if (publicStats is Map) {
        final statsMap = Map<String, dynamic>.from(publicStats);
        detailJson
          ..addAll(statsMap)
          ..['donor_count'] = statsMap['donadores'];
      }

      final rewardsRaw = root['rewards'] as List? ?? const [];
      final rewards = rewardsRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final evidencesRaw = root['evidences'] as List? ?? const [];
      final evidences = evidencesRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      Map<String, dynamic>? paymentInstructionRow;
      final paymentRaw = root['payment_instructions'];
      if (paymentRaw is Map) {
        paymentInstructionRow = Map<String, dynamic>.from(paymentRaw);
      }

      return CampaignDetail.fromJson(
        detailJson,
        rewards: rewards,
        updates: const [],
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
  /// Incluye solicitudes pendientes, aprobadas y rechazadas.
  ///
  /// Optimizado: usa 3 queries (solicitudes, campañas relacionadas en batch,
  /// donaciones aprobadas en batch) en vez de 1 + 2N queries secuenciales.
  Future<List<CampaignSummary>> fetchMyRequests() async {
    try {
      if (!hasAuthenticatedUser) {
        throw CampaignServiceException(
            'Debes iniciar sesión para ver tus solicitudes.');
      }

      // 1) Solicitudes del usuario
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

      if (requestsData.isEmpty) {
        return const <CampaignSummary>[];
      }

      final requestIds = requestsData
          .map((r) => r['id'] as String)
          .toList(growable: false);

      // 2) Campañas asociadas a esas solicitudes (una sola query con IN)
      final Map<String, Map<String, dynamic>> campaignsByRequestId = {};
      try {
        final campaignsResponse = await _client
            .from('campanias')
            .select('id, slug, solicitud_id, monto_objetivo, monto_actual')
            .inFilter('solicitud_id', requestIds);
        for (final row
            in (campaignsResponse as List).cast<Map<String, dynamic>>()) {
          final solicitudId = row['solicitud_id'] as String?;
          if (solicitudId != null) {
            campaignsByRequestId[solicitudId] = row;
          }
        }
      } catch (e) {
        debugPrint('Error fetching campaigns in batch: $e');
      }

      // 3) Conteo de donantes para esas campañas (una sola query con IN)
      final Map<String, int> donorCountsByCampaignId = {};
      final campaignIds = campaignsByRequestId.values
          .map((c) => c['id'] as String?)
          .whereType<String>()
          .toList(growable: false);
      if (campaignIds.isNotEmpty) {
        try {
          final donationsResponse = await _client
              .from('donaciones')
              .select('campania_id')
              .inFilter('campania_id', campaignIds)
              .eq('estado', 'aprobada');
          for (final row
              in (donationsResponse as List).cast<Map<String, dynamic>>()) {
            final campaniaId = row['campania_id'] as String?;
            if (campaniaId != null) {
              donorCountsByCampaignId.update(
                campaniaId,
                (v) => v + 1,
                ifAbsent: () => 1,
              );
            }
          }
        } catch (e) {
          debugPrint('Error counting donors in batch: $e');
        }
      }

      // 4) Armar los CampaignSummary
      return requestsData.map((request) {
        final requestId = request['id'] as String;
        final campaniaData = campaignsByRequestId[requestId];

        final goalAmount = campaniaData != null
            ? ((campaniaData['monto_objetivo'] as num?)?.toDouble() ?? 0.0)
            : ((request['monto_objetivo'] as num?)?.toDouble() ?? 0.0);
        final raisedAmount = campaniaData != null
            ? ((campaniaData['monto_actual'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        final completionPercentage = goalAmount > 0
            ? (raisedAmount / goalAmount * 100).clamp(0.0, 100.0)
            : 0.0;

        final donorCount = campaniaData != null
            ? (donorCountsByCampaignId[campaniaData['id'] as String?] ?? 0)
            : 0;

        final descripcion = request['descripcion'] as String? ?? '';
        final shortDesc = descripcion.length > 150
            ? '${descripcion.substring(0, 150)}...'
            : descripcion;

        return CampaignSummary(
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
      }).toList(growable: false);
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

  // ─── EVIDENCIAS DE CAMPAÑAS COMPLETADAS ───────────────────────────────────

  static const String _evidencesBucket = 'evidencias-campania';
  static const int _maxEvidenceBytes = 20 * 1024 * 1024; // 20 MB

  /// Lista las evidencias de una campaña (ordenadas por fecha desc).
  Future<List<CampaignEvidence>> fetchEvidencesByCampaign(
    String campaignId,
  ) async {
    try {
      final response = await _client
          .from('evidencias')
          .select()
          .eq('campania_id', campaignId)
          .order('created_at', ascending: false);
      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map(CampaignEvidence.fromJson).toList();
    } catch (error) {
      debugPrint('CampaignService.fetchEvidencesByCampaign error: $error');
      return const [];
    }
  }

  /// Sube un archivo de evidencia a Storage + inserta registro en la tabla.
  /// La ruta sigue la convención `{campania_id}/{timestamp}_{filename}` para
  /// que las RLS policies puedan validar ownership por carpeta.
  Future<CampaignEvidence> uploadEvidence({
    required String campaignId,
    required Uint8List data,
    required String filename,
    required String mimeType,
    required EvidenceType type,
    String? description,
  }) async {
    if (!hasAuthenticatedUser) {
      throw CampaignServiceException('Inicia sesión para subir evidencia.');
    }
    if (data.length > _maxEvidenceBytes) {
      throw CampaignServiceException(
        'El archivo excede los 20 MB permitidos.',
      );
    }

    final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$campaignId/${timestamp}_$safeName';

    try {
      await _client.storage.from(_evidencesBucket).uploadBinary(
            storagePath,
            data,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      final publicUrl = _client.storage
          .from(_evidencesBucket)
          .getPublicUrl(storagePath);

      final insertResponse = await _client
          .from('evidencias')
          .insert({
            'campania_id': campaignId,
            'uploaded_by': currentUserId,
            'tipo': type.dbValue,
            'url': publicUrl,
            'storage_path': storagePath,
            'filename': safeName,
            'mime_type': mimeType,
            'file_size_bytes': data.length,
            'descripcion': description?.trim().isEmpty == true
                ? null
                : description?.trim(),
          })
          .select()
          .single();

      return CampaignEvidence.fromJson(
          (insertResponse as Map).cast<String, dynamic>());
    } on StorageException catch (error) {
      debugPrint('uploadEvidence storage error: ${error.message}');
      throw CampaignServiceException(
        'No pudimos subir el archivo: ${error.message}',
      );
    } on PostgrestException catch (error) {
      debugPrint('uploadEvidence db error: ${error.message}');
      throw CampaignServiceException(
        error.message.isNotEmpty
            ? error.message
            : 'No pudimos registrar la evidencia.',
      );
    } catch (error) {
      debugPrint('uploadEvidence error: $error');
      throw CampaignServiceException(
        'No pudimos subir la evidencia. Intenta nuevamente.',
      );
    }
  }

  /// Campañas del usuario actual que requieren subir/completar evidencia
  /// (estado pendiente_evidencia o en_revision). Usado por el banner del home.
  Future<List<CampaignSummary>> fetchMyPendingEvidenceCampaigns() async {
    if (!hasAuthenticatedUser) return const [];
    try {
      final response = await _client
          .from('campanias')
          .select(
            'id, slug, titulo, descripcion_corta, portada_url, '
            'monto_objetivo, monto_actual, estado, '
            'verification_status, meta_alcanzada_at, evidencias_hasta, '
            'creador_id, es_anonimo',
          )
          .eq('creador_id', currentUserId!)
          .inFilter('verification_status',
              ['pendiente_evidencia', 'en_revision'])
          .order('evidencias_hasta', ascending: true);
      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map(CampaignSummary.fromPublicView).toList();
    } catch (error) {
      debugPrint('fetchMyPendingEvidenceCampaigns error: $error');
      return const [];
    }
  }

  /// El creador elimina una evidencia propia (solo mientras esté en revisión).
  Future<void> deleteEvidence(CampaignEvidence evidence) async {
    if (!hasAuthenticatedUser) {
      throw CampaignServiceException('Inicia sesión para borrar evidencia.');
    }
    try {
      if (evidence.storagePath != null) {
        await _client.storage
            .from(_evidencesBucket)
            .remove([evidence.storagePath!]);
      }
      await _client
          .from('evidencias')
          .delete()
          .eq('id', evidence.id);
    } catch (error) {
      debugPrint('deleteEvidence error: $error');
      throw CampaignServiceException(
        'No pudimos eliminar la evidencia.',
      );
    }
  }

  /// Admin: aprueba la verificación de una campaña.
  Future<void> adminApproveVerification(String campaignId) async {
    if (!hasAuthenticatedUser) {
      throw CampaignServiceException('Inicia sesión para verificar.');
    }
    try {
      await _client.rpc('admin_verify_campania', params: {
        'p_campania_id': campaignId,
        'p_admin_id': currentUserId,
      });
    } on PostgrestException catch (error) {
      throw CampaignServiceException(
        error.message.isNotEmpty
            ? error.message
            : 'No pudimos verificar la campaña.',
      );
    }
  }

  /// Admin: rechaza la evidencia y pide al creador subir más.
  Future<void> adminRejectVerification({
    required String campaignId,
    required String reason,
  }) async {
    if (!hasAuthenticatedUser) {
      throw CampaignServiceException('Inicia sesión para rechazar.');
    }
    try {
      await _client.rpc('admin_reject_campania_evidence', params: {
        'p_campania_id': campaignId,
        'p_admin_id': currentUserId,
        'p_reason': reason,
      });
    } on PostgrestException catch (error) {
      throw CampaignServiceException(
        error.message.isNotEmpty
            ? error.message
            : 'No pudimos rechazar la evidencia.',
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
