import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_entry.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController(this._service);

  final NotificationService _service;

  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _markingAll = false;
  String? _errorMessage;
  List<NotificationEntry> _notifications = const [];
  final Set<String> _processing = <String>{};
  RealtimeChannel? _channel;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get isMarkingAll => _markingAll;
  String? get errorMessage => _errorMessage;
  List<NotificationEntry> get notifications => _notifications;
  int get unreadCount => _notifications.where((entry) => entry.isUnread).length;
  bool get hasRealtimeSubscription => _channel != null;

  bool isProcessing(String id) => _processing.contains(id);

  Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }
    if (_hasLoaded && !forceRefresh) {
      return;
    }
    await _fetchNotifications();
  }

  Future<void> refreshNotifications() => _fetchNotifications();

  void subscribeToRealtime() {
    final currentUserId = _service.client.auth.currentUser?.id;
    if (currentUserId == null) {
      debugPrint('NotificationController.subscribeToRealtime: usuario no autenticado');
      return;
    }
    if (_channel != null) {
      return;
    }

    final channel = _service.client.channel('user-notifications-$currentUserId');

    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notificaciones',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUserId,
        ),
        callback: (payload) {
          _insertRealtimeNotification(
            Map<String, dynamic>.from(payload.newRecord),
          );
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notificaciones',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUserId,
        ),
        callback: (payload) {
          _updateRealtimeNotification(
            Map<String, dynamic>.from(payload.newRecord),
          );
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'notificaciones',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUserId,
        ),
        callback: (payload) {
          final id = payload.oldRecord['id'] as String?;
          if (id == null) return;
          _notifications = _notifications
              .where((entry) => entry.id != id)
              .toList(growable: false);
          notifyListeners();
        },
      );

    channel.subscribe((status, error) {
      if (error != null) {
        debugPrint('NotificationController.subscribe error: $error');
      }
    });

    _channel = channel;
  }

  Future<void> unsubscribeFromRealtime() async {
    final channel = _channel;
    if (channel == null) {
      return;
    }
    await channel.unsubscribe();
    _channel = null;
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((entry) => entry.id == id);
    if (index == -1) {
      return;
    }
    if (!_notifications[index].isUnread) {
      return;
    }
    if (_processing.contains(id)) {
      return;
    }

    _processing.add(id);
    notifyListeners();

    try {
      await _service.markAsRead(id);
      _notifications = List.of(_notifications)
        ..[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    } on NotificationServiceException catch (error) {
      notifyListeners();
      throw NotificationActionException(error.message);
    } catch (error) {
      debugPrint('NotificationController.markAsRead error: $error');
      notifyListeners();
      throw const NotificationActionException('No pudimos marcar la notificación como leída.');
    } finally {
      _processing.remove(id);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (_markingAll || unreadCount == 0) {
      return;
    }

    _markingAll = true;
    notifyListeners();

    try {
      await _service.markAllAsRead();
      _notifications = _notifications
          .map((entry) => entry.isUnread ? entry.copyWith(isRead: true) : entry)
          .toList(growable: false);
      notifyListeners();
    } on NotificationServiceException catch (error) {
      notifyListeners();
      throw NotificationActionException(error.message);
    } catch (error) {
      debugPrint('NotificationController.markAllAsRead error: $error');
      notifyListeners();
      throw const NotificationActionException('No pudimos marcar las notificaciones como leídas.');
    } finally {
      _markingAll = false;
      notifyListeners();
    }
  }

  Future<void> _fetchNotifications() async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final results = await _service.fetchNotifications();
      _notifications = results;
      _hasLoaded = true;
    } on NotificationServiceException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      debugPrint('NotificationController._fetchNotifications error: $error');
      _errorMessage = 'No pudimos cargar tus notificaciones.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  void _insertRealtimeNotification(Map<String, dynamic> data) {
    try {
      final entry = NotificationEntry.fromJson(data);
      final existingIndex = _notifications.indexWhere((item) => item.id == entry.id);
      if (existingIndex != -1) {
        _notifications = List.of(_notifications)..[existingIndex] = entry;
      } else {
        _notifications = <NotificationEntry>[entry, ..._notifications];
      }
      _hasLoaded = true;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('NotificationController._insertRealtimeNotification error: $e');
      debugPrint('$stackTrace');
    }
  }

  void _updateRealtimeNotification(Map<String, dynamic> data) {
    final entry = NotificationEntry.fromJson(data);
    final index = _notifications.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      _notifications = <NotificationEntry>[entry, ..._notifications];
    } else {
      _notifications = List.of(_notifications)
        ..[index] = entry;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    super.dispose();
  }
}

class NotificationActionException implements Exception {
  const NotificationActionException(this.message);

  final String message;

  @override
  String toString() => 'NotificationActionException: $message';
}
