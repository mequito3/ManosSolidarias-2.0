import 'dart:math';

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
			final solicitud = Solicitud.fromJson(response as Map<String, dynamic>);
			await _insertEvidencesForSolicitud(solicitud.id, draft.evidences);
			return solicitud;
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
				final solicitud = Solicitud.fromJson(response as Map<String, dynamic>);
				await _insertEvidencesForSolicitud(solicitud.id, draft.evidences);
				return solicitud;
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

	/// Persiste las URLs de evidencias en tabla `evidencias` con
	/// `solicitud_id` (sin campania_id porque la campaña aún no existe).
	/// El trigger `evidencias_migrate_on_campania_insert` las migra al
	/// campania_id cuando el admin aprueba la solicitud.
	Future<void> _insertEvidencesForSolicitud(
		String solicitudId,
		List<SolicitudDraftEvidence> evidences,
	) async {
		if (evidences.isEmpty) return;
		final rows = evidences
				.map((e) => {
							'solicitud_id': solicitudId,
							'url': e.url,
							'url_original': e.urlOriginal,
							'tipo': e.tipo,
							'descripcion': e.descripcion,
							'visibilidad': e.visibilidad,
						}..removeWhere((_, v) => v == null))
				.toList();
		try {
			await _client.from('evidencias').insert(rows);
		} on PostgrestException catch (error) {
			// No tumbamos la creación de la solicitud si las evidencias fallan.
			// El admin puede pedírselas después. Pero loggeamos para debug.
			debugPrint('SolicitudService._insertEvidencesForSolicitud error: ${error.message}');
		} catch (error) {
			debugPrint('SolicitudService._insertEvidencesForSolicitud error: $error');
		}
	}

	/// Genera un filename único: timestamp en microsegundos + nonce hex de 4
	/// dígitos. Evita colisiones cuando se suben 2 versiones de la misma
	/// imagen (redactada + original) en rápida sucesión, que con upsert:true
	/// sobreescribirían la primera silenciosamente.
	static final Random _filenameRandom = Random();
	String _uniqueFilename(String sanitizedExt) {
		final ts = DateTime.now().microsecondsSinceEpoch;
		final nonce = _filenameRandom.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
		return '${ts}_$nonce.$sanitizedExt';
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
		final objectPath = 'users/$userId/solicitudes/covers/${_uniqueFilename(sanitizedExt)}';

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

	/// Borra archivos de Storage dadas sus URLs públicas.
	/// Parsea cada URL para extraer el path relativo al bucket y los elimina.
	/// Fire-and-forget: errores se loggean pero no se propagan.
	Future<void> deleteStorageFiles(List<String> publicUrls) async {
		if (publicUrls.isEmpty) return;
		final storage = _client.storage.from('documentos');
		final paths = <String>[];
		for (final url in publicUrls) {
			// URL pública típica:
			// https://<project>.supabase.co/storage/v1/object/public/documentos/users/<uid>/solicitudes/covers/<ts>_<nonce>.jpg
			// El path relativo es lo que va después de '/documentos/'
			const marker = '/documentos/';
			final idx = url.indexOf(marker);
			if (idx == -1) continue;
			paths.add(url.substring(idx + marker.length));
		}
		if (paths.isEmpty) return;
		try {
			await storage.remove(paths);
		} catch (e) {
			debugPrint('SolicitudService.deleteStorageFiles error: $e');
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
		final objectPath = 'users/$userId/solicitudes/evidencias/${_uniqueFilename(sanitizedExt)}';

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
