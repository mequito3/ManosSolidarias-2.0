import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/campaign.dart';
import '../services/campaign_service.dart';

class CampaignController extends ChangeNotifier {
  CampaignController(this._service);

  final CampaignService _service;
  RealtimeChannel? _realtimeChannel;
  Timer? _debounceTimer;

  bool _isLoading = false;
  String? _errorMessage;
  List<CampaignSummary> _campaigns = const [];
  List<CampaignSummary> _featuredCampaigns = const [];
  List<CampaignSummary> _nearGoalCampaigns = const [];
  List<CampaignSummary> _recentCampaigns = const [];
  List<CampaignSummary> _favoriteCampaigns = const [];
  List<CampaignSummary> _completedCampaigns = const [];

  CampaignService get service => _service;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CampaignSummary> get campaigns => _campaigns;
  List<CampaignSummary> get featuredCampaigns => _featuredCampaigns;
  List<CampaignSummary> get nearGoalCampaigns => _nearGoalCampaigns;
  List<CampaignSummary> get recentCampaigns => _recentCampaigns;
  List<CampaignSummary> get favoriteCampaigns => _favoriteCampaigns;
  List<CampaignSummary> get completedCampaigns => _completedCampaigns;

  Future<void> loadCampaigns({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    if (!forceRefresh) {
      notifyListeners();
    }

    _errorMessage = null;

    try {
      final campaigns = await _service.fetchActiveCampaigns();
      _partitionCampaigns(campaigns);
      _computeSegments();
    } on CampaignServiceException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      debugPrint('CampaignController.loadCampaigns error: $error');
      _errorMessage = 'No pudimos cargar las campañas. Intenta nuevamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCampaigns() => loadCampaigns(forceRefresh: true);

  /// Suscribe a cambios en tiempo real de campañas y donaciones
  void subscribeToRealtime() {
    try {
      _realtimeChannel = Supabase.instance.client
          .channel('campaigns_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'campanias',
            callback: (payload) {
              final data = payload.newRecord;
              final campaignId = data['id'] as String?;
              if (campaignId != null) {
                debugPrint('🔔 Campaña actualizada en tiempo real: $campaignId');
                _refreshSingleCampaign(campaignId);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'campanias',
            callback: (payload) {
              final data = payload.newRecord;
              debugPrint('🔔 Nueva campaña creada: ${data['id']}');
              _handleRealtimeUpdate();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'donaciones',
            callback: (payload) {
              final data = payload.newRecord;
              final campaignId = data['campania_id'] as String?;
              if (campaignId != null) {
                debugPrint('🔔 Donación actualizada, afecta campaña: $campaignId');
                _refreshSingleCampaign(campaignId);
              }
            },
          )
          .subscribe();
      
      debugPrint('✅ CampaignController: Subscribed to realtime updates');
    } catch (error) {
      debugPrint('❌ CampaignController realtime subscription error: $error');
    }
  }

  /// Cancela la suscripción de realtime
  void unsubscribeFromRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    debugPrint('🔌 CampaignController: Unsubscribed from realtime');
  }

  /// Recarga una sola campaña desde el servidor y actualiza todas las listas
  Future<void> _refreshSingleCampaign(String campaignId) async {
    _debounceTimer?.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        debugPrint('🔄 Refrescando campaña individual: $campaignId');
        
        // Consultar la campaña específica con todos los datos necesarios
        final response = await Supabase.instance.client
            .from('campanias')
            .select('''
              id, slug, titulo, descripcion_corta, portada_url,
              monto_objetivo, monto_actual, estado, fecha_inicio, fecha_fin,
              creador_id,
              categorias(nombre),
              organizaciones(nombre)
            ''')
            .eq('id', campaignId)
            .maybeSingle();

        if (response == null) {
          debugPrint('⚠️ Campaña $campaignId no encontrada');
          return;
        }

        // Contar donadores
        final donorsResponse = await Supabase.instance.client
            .from('donaciones')
            .select('id')
            .eq('campania_id', campaignId)
            .eq('estado', 'aprobada');

        // Construir datos completos para CampaignSummary
        final data = Map<String, dynamic>.from(response);
        data['donadores'] = (donorsResponse as List).length;
        data['categoria'] = response['categorias']?['nombre'] ?? 'General';
        data['organizacion_nombre'] = response['organizaciones']?['nombre'];
        data['porcentaje'] = data['monto_objetivo'] > 0
            ? (data['monto_actual'] / data['monto_objetivo'] * 100)
            : 0.0;

        // Crear campaña actualizada
        final updatedCampaign = CampaignSummary.fromPublicView(data);
        
        // Función para actualizar la campaña en una lista
        CampaignSummary updateIfMatch(CampaignSummary campaign) {
          return campaign.id == campaignId ? updatedCampaign : campaign;
        }

        // Actualizar en todas las listas
        _campaigns = _campaigns.map(updateIfMatch).toList();
        _featuredCampaigns = _featuredCampaigns.map(updateIfMatch).toList();
        _nearGoalCampaigns = _nearGoalCampaigns.map(updateIfMatch).toList();
        _recentCampaigns = _recentCampaigns.map(updateIfMatch).toList();
        _completedCampaigns = _completedCampaigns.map(updateIfMatch).toList();
        _favoriteCampaigns = _favoriteCampaigns.map(updateIfMatch).toList();

        // Recomputar segmentos
        _computeSegments();
        
        notifyListeners();
        debugPrint('✅ Campaña $campaignId actualizada en todas las listas');
      } catch (error) {
        debugPrint('❌ Error refrescando campaña individual: $error');
      }
    });
  }

  /// Maneja actualizaciones en tiempo real (fallback para casos generales)
  Future<void> _handleRealtimeUpdate() async {
    _debounceTimer?.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      debugPrint('🔄 CampaignController: Realtime update detected, refreshing...');
      refreshCampaigns();
    });
  }

  Future<bool?> toggleFavorite(CampaignSummary campaign) async {
    final desiredState = !campaign.isFavorite;
    _updateFavoriteFlag(campaign.id, desiredState);
    notifyListeners();

    try {
      await _service.setFavorite(campaign.id, shouldFavorite: desiredState);
      return desiredState;
    } catch (error) {
      debugPrint('CampaignController.toggleFavorite error: $error');
      _updateFavoriteFlag(campaign.id, !desiredState);
      notifyListeners();
      return null;
    }
  }

  void _computeSegments() {
    _favoriteCampaigns = [
      ..._campaigns,
      ..._completedCampaigns,
    ].where((campaign) => campaign.isFavorite).toList();

    if (_campaigns.isEmpty) {
      _featuredCampaigns = const [];
      _nearGoalCampaigns = const [];
      _recentCampaigns = const [];
      return;
    }

    _featuredCampaigns = _campaigns
        .where((campaign) => campaign.isVerified || campaign.isNearGoal)
        .take(4)
        .toList();

    _nearGoalCampaigns = _campaigns
        .where((campaign) => campaign.isNearGoal)
        .toList()
      ..sort((a, b) => b.normalizedProgress.compareTo(a.normalizedProgress));

    final campaignsWithDate = _campaigns
        .where((campaign) => campaign.startDate != null)
        .toList()
      ..sort((a, b) => b.startDate!.compareTo(a.startDate!));

    _recentCampaigns = campaignsWithDate.take(6).toList();
  }

  void _updateFavoriteFlag(String campaignId, bool isFavorite) {
    CampaignSummary transform(CampaignSummary campaign) {
      return campaign.id == campaignId ? campaign.copyWith(isFavorite: isFavorite) : campaign;
    }

    _campaigns = _campaigns.map(transform).toList();
    _featuredCampaigns = _featuredCampaigns.map(transform).toList();
    _nearGoalCampaigns = _nearGoalCampaigns.map(transform).toList();
    _recentCampaigns = _recentCampaigns.map(transform).toList();
    _completedCampaigns = _completedCampaigns.map(transform).toList();
    _favoriteCampaigns = [
      ..._campaigns,
      ..._completedCampaigns,
    ].where((campaign) => campaign.isFavorite).toList();
  }

  void _partitionCampaigns(List<CampaignSummary> campaigns) {
    final active = <CampaignSummary>[];
    final completed = <CampaignSummary>[];

    for (final campaign in campaigns) {
      if (campaign.isCompleted) {
        completed.add(campaign);
      } else {
        active.add(campaign);
      }
    }

    completed.sort((a, b) {
      final aDate = a.endDate ?? a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.endDate ?? b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateComparison = bDate.compareTo(aDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return b.completionPercentage.compareTo(a.completionPercentage);
    });

    _campaigns = active;
    _completedCampaigns = completed;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    unsubscribeFromRealtime();
    super.dispose();
  }
}
