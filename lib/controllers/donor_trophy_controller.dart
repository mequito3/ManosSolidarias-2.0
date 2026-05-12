import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/donor_trophy_entry.dart';
import '../services/donor_trophy_service.dart';

class DonorTrophyController extends ChangeNotifier {
  DonorTrophyController(this._service);

  final DonorTrophyService _service;
  RealtimeChannel? _realtimeChannel;
  Timer? _debounceTimer;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  List<DonorTrophyEntry> _entries = const [];
  DonorTrophyProfile? _profile;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  List<DonorTrophyEntry> get entries => _entries;
  DonorTrophyProfile? get profile => _profile;

  DonorTrophyEntry? get firstPlace {
    if (_entries.isEmpty) {
      return null;
    }
    return _entries.firstWhere(
      (entry) => entry.position == 1,
      orElse: () => _entries.first,
    );
  }

  List<DonorTrophyEntry> get topThree {
    final list = _entries.where((entry) => entry.isTopThree).toList();
    list.sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  List<DonorTrophyEntry> get remainingEntries {
    final list = _entries.where((entry) => entry.position > 3).toList();
    list.sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  Future<void> loadLeaderboard({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }
    if (_hasLoaded && !forceRefresh) {
      return;
    }
    await _fetchData();
  }

  Future<void> refresh() => _fetchData(force: true);

  /// Suscribe a cambios en tiempo real de donaciones (afecta el ranking)
  void subscribeToRealtime() {
    try {
      _realtimeChannel = Supabase.instance.client
          .channel('donor_trophy_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'donaciones',
            callback: (_) => _handleRealtimeUpdate(),
          )
          .subscribe();
      
      debugPrint('✅ DonorTrophyController: Subscribed to realtime updates');
    } catch (error) {
      debugPrint('❌ DonorTrophyController realtime subscription error: $error');
    }
  }

  /// Cancela la suscripción de realtime
  void unsubscribeFromRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    debugPrint('🔌 DonorTrophyController: Unsubscribed from realtime');
  }

  /// Maneja actualizaciones en tiempo real
  Future<void> _handleRealtimeUpdate() async {
    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();
    
    // Crear un nuevo timer que espera 1 segundo antes de refrescar
    // El ranking necesita más tiempo porque involucra cálculos complejos
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      debugPrint('🔄 DonorTrophyController: Realtime update detected, refreshing...');
      refresh();
    });
  }

  Future<void> _fetchData({bool force = false}) async {
    if (_isLoading && !force) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final leaderboardFuture = _service.fetchLeaderboard();
      final profileFuture = _service.fetchCurrentUserProfile();
      final results = await Future.wait([leaderboardFuture, profileFuture]);

      _entries = results[0] as List<DonorTrophyEntry>;
      _profile = results[1] as DonorTrophyProfile?;
      _hasLoaded = true;
    } on DonorTrophyException catch (error) {
      _errorMessage = error.message;
    } catch (error, stackTrace) {
      debugPrint('DonorTrophyController._fetchData error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = 'No pudimos cargar el ranking solidario. Intenta nuevamente.';
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    unsubscribeFromRealtime();
    super.dispose();
  }
}
