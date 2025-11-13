import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../controllers/admin_dashboard_controller.dart';
import '../../../models/admin_dashboard.dart';
import '../../../models/admin_organization_detail.dart';
import '../../../theme/app_colors.dart';
import 'admin_section_widgets.dart';

class OrganizationsSection extends StatelessWidget {
  const OrganizationsSection({
    super.key,
    required this.items,
    required this.onReview,
  });

  final List<AdminPendingItem> items;
  final ValueChanged<AdminPendingItem> onReview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionHeading(
          title: 'Organizaciones en revisión',
          description: 'Valida los documentos y contactos antes de habilitar sus campañas públicas.',
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const AdminEmptyState(message: 'No hay organizaciones en espera de aprobación.')
        else
          ...List.generate(
            items.length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 14),
              child: OrganizationReviewCard(
                item: items[index],
                onReview: () => onReview(items[index]),
              ),
            ),
          ),
      ],
    );
  }
}

class OrganizationReviewCard extends StatelessWidget {
  const OrganizationReviewCard({
    super.key,
    required this.item,
    required this.onReview,
  });

  final AdminPendingItem item;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = item.subtitle?.trim();
    final formattedDate = formatAdminDateTime(item.createdAt);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.approval_outlined, color: AppColors.bluePrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enviada el $formattedDate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.75),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.folder_shared_outlined),
                label: const Text('Revisar documentos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum OrganizationReviewResult { approved, rejected }

Future<OrganizationReviewResult?> showOrganizationReviewSheet({
  required BuildContext context,
  required AdminPendingItem item,
  required Future<AdminOrganizationDetail> Function() loadDetail,
  required Future<void> Function(String? notes) onApprove,
  required Future<void> Function(String message) onReject,
}) {
  return showModalBottomSheet<OrganizationReviewResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => OrganizationReviewSheet(
      item: item,
      loadDetail: loadDetail,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}

class OrganizationReviewSheet extends StatefulWidget {
  const OrganizationReviewSheet({
    super.key,
    required this.item,
    required this.loadDetail,
    required this.onApprove,
    required this.onReject,
  });

  final AdminPendingItem item;
  final Future<AdminOrganizationDetail> Function() loadDetail;
  final Future<void> Function(String? notes) onApprove;
  final Future<void> Function(String message) onReject;

  @override
  State<OrganizationReviewSheet> createState() => _OrganizationReviewSheetState();
}

class _OrganizationReviewSheetState extends State<OrganizationReviewSheet> {
  late Future<AdminOrganizationDetail> _future;
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;
  bool _notesPrefilled = false;

  @override
  void initState() {
    super.initState();
    _future = widget.loadDetail();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _future = widget.loadDetail();
      _errorMessage = null;
      _notesPrefilled = false;
    });
  }

  void _ensureNotesPrefilled(String? notes) {
    if (_notesPrefilled) {
      return;
    }
    final trimmed = notes?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      _notesCtrl.text = trimmed;
    }
    _notesPrefilled = true;
  }

  Future<void> _handleApprove() async {
    if (_isProcessing) {
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    final notes = _notesCtrl.text.trim();
    try {
      await widget.onApprove(notes.isEmpty ? null : notes);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(OrganizationReviewResult.approved);
    } on AdminActionException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'No pudimos aprobar la organización. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleReject() async {
    if (_isProcessing) {
      return;
    }
    final message = _notesCtrl.text.trim();
    if (message.isEmpty) {
      setState(() => _errorMessage = 'Describe el motivo del rechazo para notificar a la organización.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      await widget.onReject(message);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(OrganizationReviewResult.rejected);
    } on AdminActionException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'No pudimos rechazar la organización. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: viewInsets.bottom + 24,
        ),
        child: FutureBuilder<AdminOrganizationDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _OrganizationDetailError(onRetry: _retry);
            }

            final detail = snapshot.data;
            if (detail == null) {
              return _OrganizationDetailError(onRetry: _retry);
            }

            _ensureNotesPrefilled(detail.adminNotes);

            final isPending = detail.status.toLowerCase() == 'pendiente';

            return _OrganizationDetailContent(
              item: widget.item,
              detail: detail,
              notesController: _notesCtrl,
              onApprove: isPending ? _handleApprove : null,
              onReject: isPending ? _handleReject : null,
              isProcessing: _isProcessing,
              errorMessage: _errorMessage,
            );
          },
        ),
      ),
    );
  }
}

class _OrganizationDetailError extends StatelessWidget {
  const _OrganizationDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 42, color: AppColors.orangeAction),
        const SizedBox(height: 16),
        const Text(
          'No pudimos cargar el detalle de la organización.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }
}

class _OrganizationDetailContent extends StatelessWidget {
  const _OrganizationDetailContent({
    required this.item,
    required this.detail,
    required this.notesController,
    this.onApprove,
    this.onReject,
    this.isProcessing = false,
    this.errorMessage,
  });

  final AdminPendingItem item;
  final AdminOrganizationDetail detail;
  final TextEditingController notesController;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isProcessing;
  final String? errorMessage;

  bool get _isEditable => onApprove != null || onReject != null;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprobada':
      case 'aprobado':
        return AppColors.greenSuccess;
      case 'rechazada':
      case 'rechazado':
        return AppColors.orangeAction;
      default:
        return AppColors.bluePrimary;
    }
  }

  Widget _buildMapForAddress(String address) {
    // Coordenadas predeterminadas para Bolivia (La Paz centro)
    final defaultLat = -16.5000;
    final defaultLng = -68.1500;
    
    // Intentar extraer coordenadas del texto de dirección
    double? lat;
    double? lng;
    
    final coordPattern = RegExp(r'[-]?\d+\.\d+');
    final matches = coordPattern.allMatches(address).toList();
    
    if (matches.length >= 2) {
      lat = double.tryParse(matches[0].group(0) ?? '');
      lng = double.tryParse(matches[1].group(0) ?? '');
    }
    
    final center = LatLng(lat ?? defaultLat, lng ?? defaultLng);
    
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: lat != null && lng != null ? 15.0 : 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.manoslibres.manos_solidarias',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdText = formatAdminDateTime(detail.createdAt);
    final statusText = detail.status.toUpperCase();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (detail.logoUrl != null && detail.logoUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          detail.logoUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.bluePrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.business, size: 30, color: AppColors.bluePrimary),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enviada el $createdText',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Estado y Tipo
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.bluePrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fact_check, size: 20, color: AppColors.bluePrimary),
                          const SizedBox(width: 8),
                          const Text(
                            'Estado',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if ((detail.type ?? '').isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.orangeAction.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.orangeAction.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.category, size: 20, color: AppColors.orangeAction),
                            const SizedBox(width: 8),
                            const Text(
                              'Tipo',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.type!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (detail.description?.isNotEmpty == true) ...[
            const Text(
              'Descripción',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                detail.description!,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ],
          if (detail.ownerName?.isNotEmpty == true ||
              detail.ownerPhone?.isNotEmpty == true ||
              detail.ownerCity?.isNotEmpty == true ||
              detail.ownerDocumentNumber?.isNotEmpty == true)
            ...[
              const SizedBox(height: 18),
              const Text(
                'Responsable de la organización',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (detail.ownerName?.isNotEmpty == true)
                      _DetailRow(label: 'Nombre completo', value: detail.ownerName!),
                    if (detail.ownerPhone?.isNotEmpty == true)
                      _DetailRow(label: 'Teléfono', value: detail.ownerPhone!),
                    if (detail.ownerCity?.isNotEmpty == true)
                      _DetailRow(label: 'Ciudad', value: detail.ownerCity!),
                    if (detail.ownerDocumentNumber?.isNotEmpty == true)
                      _DetailRow(
                        label: detail.ownerDocumentType?.isNotEmpty == true
                            ? 'Documento (${detail.ownerDocumentType})'
                            : 'Documento',
                        value: detail.ownerDocumentNumber!,
                      ),
                  ],
                ),
              ),
            ],
          if (detail.hasContactInfo)
            ...[
              const SizedBox(height: 18),
              const Text(
                'Datos de contacto',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (detail.phone?.isNotEmpty == true)
                      _DetailRow(label: 'Teléfono', value: detail.phone!),
                    if (detail.email?.isNotEmpty == true)
                      _DetailRow(label: 'Email', value: detail.email!),
                    if (detail.website?.isNotEmpty == true)
                      _DetailRow(label: 'Sitio web', value: detail.website!),
                  ],
                ),
              ),
            ],
          if (detail.hasAddress)
            ...[
              const SizedBox(height: 18),
              const Text(
                'Ubicación',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20, color: AppColors.orangeAction),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            detail.address!,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 200,
                        child: _buildMapForAddress(detail.address!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          if (detail.hasGallery)
            ...[
              const SizedBox(height: 18),
              const Text(
                'Galería del espacio',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              if (detail.galleryUrls.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 32, color: Colors.grey),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'No hay imágenes disponibles en la galería',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: detail.galleryUrls.length,
                  itemBuilder: (context, index) {
                    final url = detail.galleryUrls[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Error al cargar',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${index + 1}/${detail.galleryUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          if (detail.hasSocialLinks)
            ...[
              const SizedBox(height: 18),
              const Text(
                'Redes sociales',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.bluePrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final link in detail.socialLinks)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.link, size: 20, color: AppColors.bluePrimary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SelectableText(
                                link,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 15,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.open_in_new, size: 20),
                              onPressed: () => _launchExternalUrl(link),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          if (detail.documents.isNotEmpty)
            ...[
              const SizedBox(height: 18),
              const Text(
                'Documentos enviados',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              for (final doc in detail.documents)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, size: 32, color: AppColors.bluePrimary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.type,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doc.status.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(doc.status),
                                fontSize: 13,
                              ),
                            ),
                            if (doc.adminNotes?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(
                                doc.adminNotes!,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _launchExternalUrl(doc.url),
                      ),
                    ],
                  ),
                ),
            ],
          const SizedBox(height: 24),
          TextField(
            controller: notesController,
            enabled: _isEditable,
            readOnly: !_isEditable,
            maxLines: 4,
            minLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Notas para la organización',
              hintText: 'Comparte observaciones, requisitos adicionales o el motivo del rechazo.',
              alignLabelWithHint: true,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.orangeAction),
            ),
          ],
          if (_isEditable) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing ? null : onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isProcessing ? null : onApprove,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _launchExternalUrl(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) {
    return;
  }
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('No se pudo abrir el enlace: $rawUrl');
  }
}