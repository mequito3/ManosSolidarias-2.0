import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/organization.dart';
import '../services/organization_service.dart';

class OrganizationRegistrationController extends ChangeNotifier {
  OrganizationRegistrationController(this._service);

  final OrganizationService _service;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;
  String? _submitError;
  List<OrganizationSummary> _myOrganizations = const [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get loadError => _loadError;
  String? get submitError => _submitError;
  List<OrganizationSummary> get myOrganizations => _myOrganizations;

  Future<void> loadMyOrganizations({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _loadError = null;
    if (!forceRefresh) {
      notifyListeners();
    }

    try {
  _myOrganizations = await _service.fetchOrganizationsForOwner();
    } on OrganizationServiceException catch (error) {
      _loadError = error.message;
    } catch (error) {
      debugPrint('OrganizationRegistrationController.loadMyOrganizations error: $error');
      _loadError = 'No pudimos cargar tus organizaciones. Intenta nuevamente más tarde.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrganizationSummary?> submitOrganization(OrganizationDraft draft) async {
    if (_isSubmitting) {
      return null;
    }

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final organization = await _service.submitOrganizationDraft(draft);
      await loadMyOrganizations(forceRefresh: true);
      return organization;
    } on OrganizationServiceException catch (error) {
      _submitError = error.message;
    } catch (error) {
      debugPrint('OrganizationRegistrationController.submitOrganization error: $error');
      _submitError = 'No pudimos registrar la organización. Intenta nuevamente.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
    return null;
  }

  Future<String> uploadLogoImage({
    required Uint8List data,
    required String contentType,
    required String fileExtension,
  }) {
    return _service.uploadLogoImage(
      data: data,
      contentType: contentType,
      fileExtension: fileExtension,
    );
  }

  Future<String> uploadGalleryImage({
    required Uint8List data,
    required String contentType,
    required String fileExtension,
  }) {
    return _service.uploadGalleryImage(
      data: data,
      contentType: contentType,
      fileExtension: fileExtension,
    );
  }

  void clearSubmitError() {
    if (_submitError == null) {
      return;
    }
    _submitError = null;
    notifyListeners();
  }
}
