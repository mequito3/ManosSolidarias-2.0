import 'package:flutter/foundation.dart';

import '../models/donation_history_entry.dart';
import '../services/donation_history_service.dart';

class DonationHistoryController extends ChangeNotifier {
  DonationHistoryController(this._service);

  final DonationHistoryService _service;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  List<DonationHistoryEntry> _entries = const [];

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  List<DonationHistoryEntry> get entries => _entries;

  Future<void> loadHistory({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }
    if (_hasLoaded && !forceRefresh) {
      return;
    }
    await _fetchHistory();
  }

  Future<void> refreshHistory() => _fetchHistory();

  Future<void> _fetchHistory() async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final results = await _service.fetchCurrentUserDonations();
      _entries = results;
      _hasLoaded = true;
    } on DonationHistoryException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      debugPrint('DonationHistoryController._fetchHistory error: $error');
      _errorMessage = 'No pudimos cargar el historial. Intenta nuevamente.';
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
