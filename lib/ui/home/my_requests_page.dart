import 'package:flutter/material.dart';
import '../../models/campaign.dart';
import '../../services/campaign_service.dart';
import '../../theme/app_colors.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({
    super.key,
    required this.campaignService,
    required this.onOpenCampaign,
  });

  final CampaignService campaignService;
  final ValueChanged<CampaignSummary> onOpenCampaign;

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  List<CampaignSummary>? _requests;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await widget.campaignService.fetchMyRequests();
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('CampaignServiceException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        backgroundColor: AppColors.bluePrimary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.lightBackground,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_requests == null || _requests!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.bluePrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests!.length,
        itemBuilder: (context, index) {
          final request = _requests![index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _RequestCard(
              request: request,
              onTap: () => widget.onOpenCampaign(request),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                size: 60,
                color: AppColors.bluePrimary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes solicitudes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las campañas que crees aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mediumText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error al cargar solicitudes',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onTap,
  });

  final CampaignSummary request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            if (request.coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    request.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.grayLight,
                      child: const Icon(Icons.image_not_supported, size: 48),
                    ),
                  ),
                ),
              ),
            
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado
                  _StatusBadge(status: request.status),
                  const SizedBox(height: 12),
                  
                  // Título
                  Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Descripción
                  Text(
                    request.shortDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mediumText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Progreso (solo si está aprobada)
                  if (request.status == 'aprobada') ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: request.normalizedProgress,
                            backgroundColor: AppColors.grayLight,
                            valueColor: const AlwaysStoppedAnimation(AppColors.greenHope),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${request.completionPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greenHope,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bs. ${request.raisedAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          'Meta: Bs. ${request.goalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mediumText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusData(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusData.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusData.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusData.icon,
            size: 16,
            color: statusData.color,
          ),
          const SizedBox(width: 6),
          Text(
            statusData.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusData.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusData _getStatusData(String? status) {
    switch (status) {
      case 'pendiente':
        return _StatusData(
          label: 'En revisión',
          icon: Icons.schedule,
          color: AppColors.orangeAction,
        );
      case 'aprobada':
        return _StatusData(
          label: 'Aprobada',
          icon: Icons.check_circle,
          color: AppColors.greenHope,
        );
      case 'rechazada':
        return _StatusData(
          label: 'Rechazada',
          icon: Icons.cancel,
          color: AppColors.error,
        );
      default:
        return _StatusData(
          label: 'Desconocido',
          icon: Icons.help_outline,
          color: AppColors.grayNeutral,
        );
    }
  }
}

class _StatusData {
  const _StatusData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
