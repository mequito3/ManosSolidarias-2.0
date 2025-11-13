import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/solicitud.dart';

class SolicitudService {
	SolicitudService(this._client);

	final SupabaseClient _client;

	String? get currentUserId => _client.auth.currentUser?.id;

	String requireCurrentUserId() {
		final id = currentUserId;
		if (id == null || id.isEmpty) {
			throw const SolicitudServiceException('Necesitas iniciar sesión para crear una solicitud.');
		}
		return id;
	}

	Future<List<SolicitudCategory>> fetchCategories() async {
		try {
			final response = await _client
					.from('categorias')
					.select('id, nombre, descripcion')
					.eq('activa', true)
					.order('orden')
					.order('nombre');

			final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
			return data.map(SolicitudCategory.fromJson).toList();
		} catch (error, stackTrace) {
			debugPrint('SolicitudService.fetchCategories error: $error');
			Error.throwWithStackTrace(
				const SolicitudServiceException('No pudimos cargar las categorías disponibles.'),
				stackTrace,
			);
		}
	}

	Future<List<SolicitudOrganization>> fetchOrganizationsForCurrentUser() async {
		try {
			final userId = requireCurrentUserId();
			final response = await _client
					.from('organizaciones')
					.select('id, nombre, estado')
					.eq('owner_id', userId)
					.order('created_at', ascending: false);

			final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
			return data.map(SolicitudOrganization.fromJson).toList();
		} on SolicitudServiceException {
			rethrow;
		} catch (error, stackTrace) {
			debugPrint('SolicitudService.fetchOrganizationsForCurrentUser error: $error');
			Error.throwWithStackTrace(
				const SolicitudServiceException('No pudimos cargar tus organizaciones registradas.'),
				stackTrace,
			);
		}
	}

	Future<Solicitud> createSolicitud(SolicitudDraft draft) async {
		final userId = requireCurrentUserId();
		final payload = draft.toInsertMap(userId: userId);
		try {
			final response = await _client
					.from('solicitudes')
					.insert(payload)
					.select()
					.single();
			return Solicitud.fromJson(response as Map<String, dynamic>);
		} on PostgrestException catch (error, stackTrace) {
			if (error.code == 'PGRST204' && error.message.contains("'tipo'")) {
				debugPrint('SolicitudService.createSolicitud fallback: esquema sin columna tipo, enviando nuevamente sin el campo.');
				final fallbackPayload = Map<String, dynamic>.from(payload)..remove('tipo');
				if (!(draft.descripcion.contains('Tipo de solicitud:') ||
						draft.descripcion.contains('Tipo seleccionado:'))) {
					final fallbackDescription =
						'Tipo de solicitud: ${draft.tipo.displayName}\n\n${draft.descripcion}'.trim();
					fallbackPayload['descripcion'] = fallbackDescription;
				}
				final response = await _client
						.from('solicitudes')
						.insert(fallbackPayload)
						.select()
						.single();
				return Solicitud.fromJson(response as Map<String, dynamic>);
			}
			debugPrint('SolicitudService.createSolicitud error (PostgrestException): ${error.message}');
			Error.throwWithStackTrace(
				SolicitudServiceException(error.message ?? 'No pudimos registrar tu solicitud. Intenta nuevamente.'),
				stackTrace,
			);
		} on SolicitudServiceException {
			rethrow;
		} catch (error, stackTrace) {
			debugPrint('SolicitudService.createSolicitud error: $error');
			Error.throwWithStackTrace(
				const SolicitudServiceException('No pudimos registrar tu solicitud. Intenta nuevamente.'),
				stackTrace,
			);
		}
	}

	Future<String> uploadCoverImage({
		required Uint8List data,
		required String contentType,
		required String fileExtension,
	}) async {
		final userId = requireCurrentUserId();
		final storage = _client.storage.from('documentos');
		var sanitizedExt = fileExtension.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toLowerCase();
		if (sanitizedExt.isEmpty) {
			sanitizedExt = 'jpg';
		}
		final timestamp = DateTime.now().millisecondsSinceEpoch;
		final objectPath = 'users/$userId/solicitudes/covers/$timestamp.$sanitizedExt';

		try {
			await storage.uploadBinary(
				objectPath,
				data,
				fileOptions: FileOptions(contentType: contentType, upsert: true),
			);
			return storage.getPublicUrl(objectPath);
		} on StorageException catch (error) {
			throw SolicitudServiceException(error.message);
		} catch (_) {
			throw const SolicitudServiceException('No pudimos subir la portada. Intenta de nuevo.');
		}
	}

	Future<String> uploadEvidenceImage({
		required Uint8List data,
		required String contentType,
		required String fileExtension,
	}) async {
		final userId = requireCurrentUserId();
		final storage = _client.storage.from('documentos');
		var sanitizedExt = fileExtension.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toLowerCase();
		if (sanitizedExt.isEmpty) {
			sanitizedExt = 'jpg';
		}
		final timestamp = DateTime.now().microsecondsSinceEpoch;
		final objectPath = 'users/$userId/solicitudes/evidencias/$timestamp.$sanitizedExt';

		try {
			await storage.uploadBinary(
				objectPath,
				data,
				fileOptions: FileOptions(contentType: contentType, upsert: true),
			);
			return storage.getPublicUrl(objectPath);
		} on StorageException catch (error) {
			throw SolicitudServiceException(error.message);
		} catch (_) {
			throw const SolicitudServiceException('No pudimos subir la evidencia. Intenta de nuevo.');
		}
	}
}

class SolicitudServiceException implements Exception {
	const SolicitudServiceException(this.message);

	final String message;

	@override
	String toString() => 'SolicitudServiceException: $message';
}
