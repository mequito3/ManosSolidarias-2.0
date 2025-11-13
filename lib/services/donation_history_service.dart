import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/donation_history_entry.dart';

class DonationHistoryService {
  DonationHistoryService(this._client);

  final SupabaseClient _client;

  Future<List<DonationHistoryEntry>> fetchCurrentUserDonations({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const DonationHistoryException('Necesitas iniciar sesión para ver tus donaciones.');
    }

    try {
      final response = await _client
          .from('donaciones')
          .select(
            'id, campania_id, monto, estado, comprobante_url, mensaje, metodo, referencia, anonimo, created_at, fecha_validacion, '
            'campanias ( titulo, portada_url ), '
            'recompensas ( titulo )',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
      return rows.map(DonationHistoryEntry.fromJson).toList();
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('DonationHistoryService.fetchCurrentUserDonations error: ${error.message}');
      Error.throwWithStackTrace(
        DonationHistoryException(
          error.message.isNotEmpty ? error.message : 'No pudimos cargar tu historial de donaciones.',
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('DonationHistoryService.fetchCurrentUserDonations error: $error');
      Error.throwWithStackTrace(
        const DonationHistoryException('No pudimos cargar tu historial de donaciones.'),
        stackTrace,
      );
    }
  }
}

class DonationHistoryException implements Exception {
  const DonationHistoryException(this.message);

  final String message;

  @override
  String toString() => 'DonationHistoryException: $message';
}
