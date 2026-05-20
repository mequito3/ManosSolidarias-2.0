import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/donor_trophy_entry.dart';

class DonorTrophyService {
  DonorTrophyService(this._client);

  final SupabaseClient _client;

  /// Trae el ranking de donantes.
  /// Por defecto 13 entradas (3 podio + 10 del resto) — alineado con el límite
  /// que muestra la UI para no transferir filas que no se renderizan.
  Future<List<DonorTrophyEntry>> fetchLeaderboard({int limit = 13}) async {
    try {
    final List<dynamic> response = await _client
      .rpc('get_donor_leaderboard', params: {'p_limit': limit})
      .select();

    return response
      .cast<Map<String, dynamic>>()
      .map(DonorTrophyEntry.fromJson)
      .toList();
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('DonorTrophyService.fetchLeaderboard error: ${error.message}');
      Error.throwWithStackTrace(
        DonorTrophyException(
          error.message.isNotEmpty ? error.message : 'No pudimos cargar el ranking en este momento.',
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('DonorTrophyService.fetchLeaderboard error: $error');
      Error.throwWithStackTrace(
        const DonorTrophyException('Ocurrió un problema al cargar el ranking de donantes.'),
        stackTrace,
      );
    }
  }

  Future<DonorTrophyProfile?> fetchCurrentUserProfile() async {
    try {
      final List<dynamic> response = await _client
          .rpc('get_current_user_trophy_profile')
          .select();

      if (response.isNotEmpty) {
        final raw = response.first as Map<String, dynamic>;
        return DonorTrophyProfile.fromJson(raw);
      }
      return null;
    } on PostgrestException catch (error, stackTrace) {
      // When the user is not authenticated or RLS blocks the call, return null gracefully.
      if (error.code == 'PGRST301') {
        return null;
      }
      debugPrint('DonorTrophyService.fetchCurrentUserProfile error: ${error.message}');
      Error.throwWithStackTrace(
        DonorTrophyException(
          error.message.isNotEmpty ? error.message : 'No pudimos obtener tu progreso solidario.',
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('DonorTrophyService.fetchCurrentUserProfile error: $error');
      Error.throwWithStackTrace(
        const DonorTrophyException('Ocurrió un problema al calcular tu progreso solidario.'),
        stackTrace,
      );
    }
  }
}

class DonorTrophyException implements Exception {
  const DonorTrophyException(this.message);

  final String message;

  @override
  String toString() => 'DonorTrophyException: $message';
}
