import 'package:flutter/foundation.dart';

import '../models/kermesse.dart';
import '../services/kermesse_service.dart';

class KermesseController extends ChangeNotifier {
  KermesseController(this._service);

  final KermesseService _service;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  List<KermesseSummary> _kermesses = const [];

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  List<KermesseSummary> get kermesses => _kermesses;

  Future<void> loadKermesses({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (_hasLoaded && !forceRefresh) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final results = await _service.fetchApprovedKermesses();
      _kermesses = results;
      _hasLoaded = true;
    } on KermesseServiceException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      debugPrint('KermesseController.loadKermesses error: $error');
      _errorMessage = 'No pudimos cargar las kermesses. Intenta nuevamente.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshKermesses() async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final results = await _service.fetchApprovedKermesses();
      _kermesses = results;
      _hasLoaded = true;
    } on KermesseServiceException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      debugPrint('KermesseController.refreshKermesses error: $error');
      _errorMessage = 'No pudimos refrescar las kermesses. Intenta nuevamente.';
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
