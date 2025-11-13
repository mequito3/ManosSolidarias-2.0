import 'package:flutter/foundation.dart';

import '../models/organization.dart';
import '../services/organization_service.dart';

class OrganizationController extends ChangeNotifier {
  OrganizationController(this._service);

  final OrganizationService _service;

  bool _isLoading = false;
  bool _hasLoadedInitially = false;
  String? _errorMessage;
  List<OrganizationSummary> _organizations = const [];
  List<OrganizationSummary> _featuredOrganizations = const [];
  List<OrganizationSummary> _recentOrganizations = const [];
  List<OrganizationSummary> _contactOrganizations = const [];

  bool get isLoading => _isLoading;
  bool get hasLoadedInitially => _hasLoadedInitially;
  String? get errorMessage => _errorMessage;
  List<OrganizationSummary> get organizations => _organizations;
  List<OrganizationSummary> get featuredOrganizations => _featuredOrganizations;
  List<OrganizationSummary> get recentOrganizations => _recentOrganizations;
  List<OrganizationSummary> get contactOrganizations => _contactOrganizations;

  Future<void> ensureLoaded() async {
    if (_hasLoadedInitially || _isLoading) {
      return;
    }
    await loadOrganizations();
  }

  Future<void> refreshOrganizations() => loadOrganizations(forceRefresh: true);

  Future<void> loadOrganizations({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (_hasLoadedInitially && !forceRefresh) {
      return;
    }

    _isLoading = true;
    if (!forceRefresh) {
      notifyListeners();
    }

    _errorMessage = null;

    try {
      final organizations = await _service.fetchApprovedOrganizations();
      _organizations = organizations;
      _hasLoadedInitially = true;
      _computeSegments();
    } on OrganizationServiceException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      debugPrint('OrganizationController.loadOrganizations error: $error');
      _errorMessage = 'No pudimos cargar las organizaciones. Intenta nuevamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _computeSegments() {
    if (_organizations.isEmpty) {
      _featuredOrganizations = const [];
      _recentOrganizations = const [];
      _contactOrganizations = const [];
      return;
    }

    final withLogoOrSite = _organizations
        .where((org) => org.hasLogo || org.hasWebsite)
        .toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    _featuredOrganizations = withLogoOrSite.take(6).toList();

    final recents = List<OrganizationSummary>.from(_organizations)
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    _recentOrganizations = recents.take(8).toList();

    _contactOrganizations = _organizations
        .where((org) => org.hasDirectContact)
        .take(10)
        .toList();
  }
}
