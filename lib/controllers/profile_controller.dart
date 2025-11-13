import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._service);

  final ProfileService _service;

  bool _isLoading = false;
  String? _errorMessage;
  UserProfile? _profile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfile? get profile => _profile;
  bool get isAdmin => _profile?.isAdmin ?? false;
  bool get isProfileComplete => _profile?.meetsCompletionCriteria ?? false;

  Future<void> loadCurrentProfile() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _service.fetchCurrentProfile();
      _profile ??= await _service.ensureCurrentProfile();
      if (_profile == null) {
        _errorMessage = 'No encontramos tu perfil en la base de datos.';
      } else {
        _errorMessage = null;
      }
    } catch (error) {
      _errorMessage = 'No pudimos cargar tu perfil.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserProfile?> saveProfile(UserProfile profile) async {
    try {
      final updated = await _service.upsertProfile(profile);
      _profile = updated;
      _errorMessage = null;
      notifyListeners();
      return updated;
    } on ProfileServiceException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'No pudimos guardar tu perfil.';
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshProfile() => loadCurrentProfile();
}
