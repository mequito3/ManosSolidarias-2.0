import 'package:flutter/foundation.dart';

import '../models/donor_trophy_entry.dart';
import '../services/donor_trophy_service.dart';

class DonorTrophyController extends ChangeNotifier {
  DonorTrophyController(this._service);

  final DonorTrophyService _service;

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
}
