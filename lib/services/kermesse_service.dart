import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kermesse.dart';

class KermesseService {
  KermesseService(this._client);

  final SupabaseClient _client;

  Future<List<KermesseSummary>> fetchApprovedKermesses({int limit = 50}) async {
    try {
      final response = await _client
          .from('solicitudes')
          .select('id, titulo, descripcion, portada_url, created_at, updated_at')
          .eq('estado', 'aprobada')
          .eq('tipo', 'kermesse')
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
      return rows.map(KermesseSummary.fromJson).toList();
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('KermesseService.fetchApprovedKermesses error: ${error.message}');
      Error.throwWithStackTrace(
        KermesseServiceException(
          error.message.isNotEmpty
              ? error.message
              : 'No pudimos cargar las kermesses aprobadas.',
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('KermesseService.fetchApprovedKermesses error: $error');
      Error.throwWithStackTrace(
        const KermesseServiceException('No pudimos cargar las kermesses aprobadas.'),
        stackTrace,
      );
    }
  }
}

class KermesseServiceException implements Exception {
  const KermesseServiceException(this.message);

  final String message;

  @override
  String toString() => 'KermesseServiceException: $message';
}
