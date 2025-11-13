import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_entry.dart';

class NotificationService {
  NotificationService(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  Future<List<NotificationEntry>> fetchNotifications({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const NotificationServiceException('Necesitas iniciar sesión para ver tus notificaciones.');
    }

    try {
      final response = await _client.rpc(
        'get_user_notifications',
        params: {
          'p_limit': limit,
        },
      );

      if (response == null) {
        return const <NotificationEntry>[];
      }

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
      return rows.map(NotificationEntry.fromJson).toList();
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('NotificationService.fetchNotifications error: ${error.message}');
      Error.throwWithStackTrace(
        NotificationServiceException(
          error.message.isNotEmpty ? error.message : 'No pudimos cargar tus notificaciones.',
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('NotificationService.fetchNotifications error: $error');
      Error.throwWithStackTrace(
        const NotificationServiceException('No pudimos cargar tus notificaciones.'),
        stackTrace,
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const NotificationServiceException('Necesitas iniciar sesión para actualizar notificaciones.');
    }

    try {
      final result = await _client.rpc(
        'mark_notification_as_read',
        params: {
          'p_notification_id': notificationId,
        },
      );

    final updated = _interpretRpcBoolean(result);

      if (!updated) {
        throw const NotificationServiceException('No pudimos marcar la notificación como leída.');
      }
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('NotificationService.markAsRead error: ${error.message}');
      Error.throwWithStackTrace(
        NotificationServiceException(
          error.message.isNotEmpty ? error.message : 'No pudimos marcar la notificación como leída.',
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('NotificationService.markAsRead error: $error');
      Error.throwWithStackTrace(
        const NotificationServiceException('No pudimos marcar la notificación como leída.'),
        stackTrace,
      );
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const NotificationServiceException('Necesitas iniciar sesión para actualizar notificaciones.');
    }

    try {
  final result = await _client.rpc('mark_notifications_as_read');
  final updated = result is int ? result : (result is num ? result.toInt() : 0);
      if (updated == 0) {
        // No unread notifications were updated; not an error, but keep consistency.
        return;
      }
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('NotificationService.markAllAsRead error: ${error.message}');
      Error.throwWithStackTrace(
        NotificationServiceException(
          error.message.isNotEmpty ? error.message : 'No pudimos marcar las notificaciones como leídas.',
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('NotificationService.markAllAsRead error: $error');
      Error.throwWithStackTrace(
        const NotificationServiceException('No pudimos marcar las notificaciones como leídas.'),
        stackTrace,
      );
    }
  }

  bool _interpretRpcBoolean(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == 't' || normalized == '1' || normalized == 'yes';
    }
    if (value is Map) {
      return value.values.any(_interpretRpcBoolean);
    }
    return false;
  }
}

class NotificationServiceException implements Exception {
  const NotificationServiceException(this.message);

  final String message;

  @override
  String toString() => 'NotificationServiceException: $message';
}
