import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/organization.dart';

class OrganizationService {
  OrganizationService(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  String requireCurrentUserId() {
    final id = currentUserId;
    if (id == null || id.isEmpty) {
      throw const OrganizationServiceException('Necesitas iniciar sesión para registrar una organización.');
    }
    return id;
  }

  Future<List<OrganizationSummary>> fetchApprovedOrganizations({int? limit}) async {
    try {
      var query = _client
          .from('organizaciones')
          .select(
            'id, nombre, tipo, descripcion, telefono, email, sitio_web, direccion, logo_url, estado, created_at, updated_at',
          )
          .eq('estado', 'aprobada')
          .order('created_at', ascending: false);

      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      final response = await query;
      final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
      return data.map(OrganizationSummary.fromJson).toList();
    } catch (error, stackTrace) {
      debugPrint('OrganizationService.fetchApprovedOrganizations error: $error');
      Error.throwWithStackTrace(
        const OrganizationServiceException('No pudimos cargar las organizaciones verificadas.'),
        stackTrace,
      );
    }
  }

  Future<List<OrganizationSummary>> fetchOrganizationsForOwner() async {
    try {
      final ownerId = requireCurrentUserId();
      final response = await _client
          .from('organizaciones')
          .select(
            'id, nombre, tipo, descripcion, telefono, email, sitio_web, direccion, logo_url, estado, created_at, updated_at',
          )
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
      return data.map(OrganizationSummary.fromJson).toList();
    } on OrganizationServiceException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('OrganizationService.fetchOrganizationsForOwner error: $error');
      Error.throwWithStackTrace(
        const OrganizationServiceException('No pudimos cargar tus organizaciones registradas.'),
        stackTrace,
      );
    }
  }

  Future<OrganizationSummary> submitOrganizationDraft(OrganizationDraft draft) async {
    final ownerId = requireCurrentUserId();
    final payload = draft.toInsertPayload(ownerId: ownerId);

    try {
      final Map<String, dynamic> response = await _client
          .from('organizaciones')
          .insert(payload)
          .select(
            'id, nombre, tipo, descripcion, telefono, email, sitio_web, direccion, logo_url, estado, created_at, updated_at',
          )
          .single();

      return OrganizationSummary.fromJson(response);
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('OrganizationService.submitOrganizationDraft error (PostgrestException): ${error.message}');
      Error.throwWithStackTrace(
        OrganizationServiceException(error.message),
        stackTrace,
      );
    } on OrganizationServiceException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('OrganizationService.submitOrganizationDraft error: $error');
      Error.throwWithStackTrace(
        const OrganizationServiceException('No pudimos registrar tu organización.'),
        stackTrace,
      );
    }
  }

  Future<String> uploadLogoImage({
    required Uint8List data,
    required String contentType,
    required String fileExtension,
  }) async {
    final ownerId = requireCurrentUserId();
    final storage = _client.storage.from('documentos');
    var sanitizedExt = fileExtension.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toLowerCase();
    if (sanitizedExt.isEmpty) {
      sanitizedExt = 'jpg';
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final objectPath = 'users/$ownerId/organizaciones/logo_$timestamp.$sanitizedExt';

    try {
      await storage.uploadBinary(
        objectPath,
        data,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      return storage.getPublicUrl(objectPath);
    } on StorageException catch (error) {
      throw OrganizationServiceException(error.message);
    } on OrganizationServiceException {
      rethrow;
    } catch (_) {
      throw const OrganizationServiceException('No pudimos subir el logo seleccionado.');
    }
  }

  Future<String> uploadGalleryImage({
    required Uint8List data,
    required String contentType,
    required String fileExtension,
  }) async {
    final ownerId = requireCurrentUserId();
    final storage = _client.storage.from('documentos');
    var sanitizedExt = fileExtension.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toLowerCase();
    if (sanitizedExt.isEmpty) {
      sanitizedExt = 'jpg';
    }
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final objectPath = 'users/$ownerId/organizaciones/gallery/gallery_$timestamp.$sanitizedExt';

    try {
      await storage.uploadBinary(
        objectPath,
        data,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      return storage.getPublicUrl(objectPath);
    } on StorageException catch (error) {
      throw OrganizationServiceException(error.message);
    } on OrganizationServiceException {
      rethrow;
    } catch (_) {
      throw const OrganizationServiceException('No pudimos subir la imagen del espacio.');
    }
  }
}

class OrganizationServiceException implements Exception {
  const OrganizationServiceException(this.message);

  final String message;

  @override
  String toString() => 'OrganizationServiceException: $message';
}
