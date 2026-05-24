import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_dashboard.dart';
import '../models/admin_donation_detail.dart';
import '../models/admin_organization_detail.dart';
import '../services/admin_service.dart';

class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController(SupabaseClient client)
      : _service = AdminService(client),
        _client = client;

  final AdminService _service;
  final SupabaseClient _client;
  RealtimeChannel? _realtimeChannel;

  bool _loading = false;
  String? _errorMessage;
  AdminDashboardMetrics? _metrics;
  List<AdminPendingItem> _pendingCampaigns = const [];
  List<AdminPendingItem> _pendingDonations = const [];
  List<AdminPendingItem> _pendingOrganizations = const [];
  List<AdminActiveCampaign> _activeCampaigns = const [];

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  AdminDashboardMetrics? get metrics => _metrics;
  List<AdminPendingItem> get pendingCampaigns => _pendingCampaigns;
  List<AdminPendingItem> get pendingDonations => _pendingDonations;
  List<AdminPendingItem> get pendingOrganizations => _pendingOrganizations;
  List<AdminActiveCampaign> get activeCampaigns => _activeCampaigns;

  Future<void> loadDashboard() async {
    if (_loading) {
      return;
    }
    _setLoading(true);

    try {
      final results = await Future.wait<dynamic>([
        _service.fetchDashboardMetrics(),
        _service.fetchPendingCampaignRequests(),
        _service.fetchPendingDonations(),
        _service.fetchPendingOrganizations(),
        _service.fetchActiveCampaigns(),
      ]);

      _metrics = results[0] as AdminDashboardMetrics;
      _pendingCampaigns = results[1] as List<AdminPendingItem>;
      _pendingDonations = results[2] as List<AdminPendingItem>;
      _pendingOrganizations = results[3] as List<AdminPendingItem>;
      _activeCampaigns = results[4] as List<AdminActiveCampaign>;
      _errorMessage = null;
    } catch (error) {
      debugPrint('AdminDashboardController.loadDashboard error: $error');
      _errorMessage = 'No pudimos cargar el panel administrativo.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() => loadDashboard();

  Future<void> approveCampaignRequest(String solicitudId, {String? categoriaId}) async {
    try {
      await _service.reviewCampaignRequest(
        solicitudId: solicitudId,
        approve: true,
        categoriaId: categoriaId,
      );    } on AdminServiceException catch (error) {
      throw AdminActionException(error.message);
    } catch (error) {
      debugPrint('AdminDashboardController.approveCampaignRequest error: $error');
      throw const AdminActionException('No pudimos aprobar la solicitud.');
    }
  }

  Future<void> requestChangesForCampaign(String solicitudId, String message) async {
    try {
      await _service.reviewCampaignRequest(
        solicitudId: solicitudId,
        approve: false,
        message: message,
      );    } on AdminServiceException catch (error) {
      throw AdminActionException(error.message);
    } catch (error) {
      debugPrint('AdminDashboardController.requestChangesForCampaign error: $error');
      throw const AdminActionException('No pudimos solicitar cambios para esta campaña.');
    }
  }

  Future<AdminDonationDetail> fetchDonationDetail(String donationId) async {
    try {
      return await _service.fetchDonationDetail(donationId);
    } on AdminServiceException catch (error) {
      throw AdminActionException(error.message);
    } catch (error) {
      debugPrint('AdminDashboardController.fetchDonationDetail error: $error');
      throw const AdminActionException('No pudimos cargar el detalle de la donación.');
    }
  }

  Future<void> approveDonation(String donationId) async {
    try {
      await _service.reviewDonation(donationId: donationId, approve: true);    } on AdminServiceException catch (error) {
      throw AdminActionException(error.message);
    } catch (error) {
      debugPrint('AdminDashboardController.approveDonation error: $error');
      throw const AdminActionException('No pudimos aprobar la donación.');
    }
  }

  Future<void> rejectDonation(String donationId) async {
    try {
      await _service.reviewDonation(donationId: donationId, approve: false);    } on AdminServiceException catch (error) {
      throw AdminActionException(error.message);
    } catch (error) {
      debugPrint('AdminDashboardController.rejectDonation error: $error');
      throw const AdminActionException('No pudimos rechazar la donación.');
    }
  }

  Future<AdminOrganizationDetail> fetchOrganizationDetail(String organizationId) async {
    try {
      return await _service
          .fetchOrganizationDetail(organizationId)
          .timeout(const Duration(seconds: 20));
    } on AdminServiceException catch (error) {
      throw AdminActionException(error.message);
    } catch (error) {
      debugPrint('AdminDashboardController.fetchOrganizationDetail error: $error');
      throw const AdminActionException('No pudimos cargar el detalle de la organización.');
    }
  }

  Future<void> approveOrganization(String organizationId, {String? notes}) async {
    try {
      await _service.reviewOrganization(
        organizationId: organizationId,
        approve: true,
        message: notes,
      );    } on AdminServiceException catch (error) {
      throw AdminActionException(error.message);
    } catch (error) {
      debugPrint('AdminDashboardController.approveOrganization error: $error');
      throw const AdminActionException('No pudimos aprobar la organización.');
    }
  }

  Future<void> rejectOrganization(String organizationId, String message) async {
    try {
      await _service.reviewOrganization(
        organizationId: organizationId,
        approve: false,
        message: message,
      );    } on AdminServiceException catch (error) {
      throw AdminActionException(error.message);
    } catch (error) {
      debugPrint('AdminDashboardController.rejectOrganization error: $error');
      throw const AdminActionException('No pudimos rechazar la organización.');
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  /// Suscribirse a notificaciones en tiempo real para el admin
  void subscribeToRealtime() {
    // Si ya existe una suscripción, no crear otra
    if (_realtimeChannel != null) {
      debugPrint('AdminDashboardController: Ya existe suscripción Realtime activa');
      return;
    }

    debugPrint('AdminDashboardController: Suscribiendo a cambios en tiempo real...');

    try {
      _realtimeChannel = _client
          .channel('admin_dashboard_updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'solicitudes',
            callback: _handleNewSolicitud,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'solicitudes',
            callback: _handleSolicitudUpdate,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'donaciones',
            callback: _handleNewDonacion,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'donaciones',
            callback: _handleDonacionUpdate,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'organizaciones',
            callback: _handleNewOrganizacion,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'organizaciones',
            callback: _handleOrganizacionUpdate,
          )
          .subscribe();

      debugPrint('AdminDashboardController: ✅ Suscripción Realtime configurada');
    } catch (e) {
      debugPrint('AdminDashboardController: ❌ Error al suscribirse a Realtime: $e');
    }
  }

  /// Cancelar suscripción al destruir el controller
  void unsubscribeFromRealtime() {
    if (_realtimeChannel != null) {
      debugPrint('AdminDashboardController: Cancelando suscripción Realtime...');
      _client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  // Handlers para eventos de Realtime

  void _handleNewSolicitud(PostgresChangePayload payload) {
    debugPrint('AdminDashboardController: 🔔 Nueva solicitud detectada');
    debugPrint('Payload: ${payload.newRecord}');
    
    final estado = payload.newRecord['estado'] as String?;
    
    // Solo refrescar si es una solicitud pendiente
    if (estado == 'pendiente' || estado == 'revision') {
      debugPrint('AdminDashboardController: Refrescando solicitudes pendientes...');
      _refreshSolicitudesPendientes();
    }
  }

  void _handleSolicitudUpdate(PostgresChangePayload payload) {
    debugPrint('AdminDashboardController: 🔄 Solicitud actualizada');
    
    final oldEstado = payload.oldRecord['estado'] as String?;
    final newEstado = payload.newRecord['estado'] as String?;
    
    // Si cambió el estado, refrescar
    if (oldEstado != newEstado) {
      debugPrint('AdminDashboardController: Estado cambió de $oldEstado a $newEstado');
      _refreshSolicitudesPendientes();
    }
  }

  void _handleNewDonacion(PostgresChangePayload payload) {
    debugPrint('AdminDashboardController: 🔔 Nueva donación detectada');
    debugPrint('Payload: ${payload.newRecord}');
    
    final estado = payload.newRecord['estado'] as String?;
    
    // Solo refrescar si es una donación pendiente
    if (estado == 'pendiente') {
      debugPrint('AdminDashboardController: Refrescando donaciones pendientes...');
      _refreshDonacionesPendientes();
    }
  }

  void _handleDonacionUpdate(PostgresChangePayload payload) {
    debugPrint('AdminDashboardController: 🔄 Donación actualizada');
    
    final oldEstado = payload.oldRecord['estado'] as String?;
    final newEstado = payload.newRecord['estado'] as String?;
    
    // Si cambió el estado, refrescar
    if (oldEstado != newEstado) {
      debugPrint('AdminDashboardController: Estado cambió de $oldEstado a $newEstado');
      _refreshDonacionesPendientes();
    }
  }

  void _handleNewOrganizacion(PostgresChangePayload payload) {
    debugPrint('AdminDashboardController: 🔔 Nueva organización detectada');
    debugPrint('Payload: ${payload.newRecord}');
    
    final estado = payload.newRecord['estado'] as String?;
    
    // Solo refrescar si está pendiente de verificación
    if (estado == 'pendiente' || estado == 'en_revision') {
      debugPrint('AdminDashboardController: Refrescando organizaciones pendientes...');
      _refreshOrganizacionesPendientes();
    }
  }

  void _handleOrganizacionUpdate(PostgresChangePayload payload) {
    debugPrint('AdminDashboardController: 🔄 Organización actualizada');
    
    final oldEstado = payload.oldRecord['estado'] as String?;
    final newEstado = payload.newRecord['estado'] as String?;
    
    // Si cambió el estado, refrescar
    if (oldEstado != newEstado) {
      debugPrint('AdminDashboardController: Estado cambió de $oldEstado a $newEstado');
      _refreshOrganizacionesPendientes();
    }
  }

  // Métodos de refresco parcial (más eficientes que refresh completo)

  Future<void> _refreshSolicitudesPendientes() async {
    try {
      final newPending = await _service.fetchPendingCampaignRequests();
      _pendingCampaigns = newPending;
      
      // También actualizar métricas
      final newMetrics = await _service.fetchDashboardMetrics();
      _metrics = newMetrics;
      
      notifyListeners();
      debugPrint('AdminDashboardController: ✅ Solicitudes actualizadas (${newPending.length} pendientes)');
    } catch (e) {
      debugPrint('AdminDashboardController: ❌ Error al refrescar solicitudes: $e');
    }
  }

  Future<void> _refreshDonacionesPendientes() async {
    try {
      final newPending = await _service.fetchPendingDonations();
      _pendingDonations = newPending;
      
      // También actualizar métricas
      final newMetrics = await _service.fetchDashboardMetrics();
      _metrics = newMetrics;
      
      notifyListeners();
      debugPrint('AdminDashboardController: ✅ Donaciones actualizadas (${newPending.length} pendientes)');
    } catch (e) {
      debugPrint('AdminDashboardController: ❌ Error al refrescar donaciones: $e');
    }
  }

  Future<void> _refreshOrganizacionesPendientes() async {
    try {
      final newPending = await _service.fetchPendingOrganizations();
      _pendingOrganizations = newPending;
      
      // También actualizar métricas
      final newMetrics = await _service.fetchDashboardMetrics();
      _metrics = newMetrics;
      
      notifyListeners();
      debugPrint('AdminDashboardController: ✅ Organizaciones actualizadas (${newPending.length} pendientes)');
    } catch (e) {
      debugPrint('AdminDashboardController: ❌ Error al refrescar organizaciones: $e');
    }
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    super.dispose();
  }
}

class AdminActionException implements Exception {
  const AdminActionException(this.message);

  final String message;

  @override
  String toString() => 'AdminActionException: $message';
}
