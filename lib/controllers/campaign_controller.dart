import 'package:flutter/foundation.dart';

import '../models/campaign.dart';
import '../services/campaign_service.dart';

class CampaignController extends ChangeNotifier {
  CampaignController(this._service);

  final CampaignService _service;

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
}
