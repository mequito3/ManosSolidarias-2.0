import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../controllers/admin_dashboard_controller.dart';
import '../../../models/admin_dashboard.dart';
import '../../../models/admin_organization_detail.dart';
import '../../../theme/app_colors.dart';
import '../../../ui/widgets/detail_section.dart';
import 'admin_section_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Section list
// ─────────────────────────────────────────────────────────────────────────────

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
          description:
              'Valida los documentos y contactos antes de habilitar sus campañas públicas.',
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const AdminEmptyState(
              message: 'No hay organizaciones en espera de aprobación.')
        else
          ...List.generate(
            items.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 0 : 14),
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

// ─────────────────────────────────────────────────────────────────────────────
// Review card  (two-zone: dark header + white body)
// ─────────────────────────────────────────────────────────────────────────────

/// Fondo de marca (azul confianza → azul oscuro) para el hero/encabezado de
/// organización. Usa la paleta oficial, en tono sobrio (no el azul vibrante).
const LinearGradient _orgHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.blueSecondary, AppColors.bluePrimaryDark],
);

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header strip ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: _orgHeroGradient,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── White body ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date chip + Pending badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 13,
                              color: AppColors.bluePrimary
                                  .withValues(alpha: 0.85)),
                          const SizedBox(width: 5),
                          Text(
                            'Enviada el $formattedDate',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.bluePrimary
                                  .withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orangeAction.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusSm),
                      ),
                      child: Text(
                        'Pendiente',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.orangeAction,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumText,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.folder_shared_outlined, size: 18),
                    label: const Text('Revisar organización'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom-sheet launcher
// ─────────────────────────────────────────────────────────────────────────────

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
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => OrganizationReviewSheet(
      item: item,
      loadDetail: loadDetail,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget
// ─────────────────────────────────────────────────────────────────────────────

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
  State<OrganizationReviewSheet> createState() =>
      _OrganizationReviewSheetState();
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
    if (_notesPrefilled) return;
    final trimmed = notes?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      _notesCtrl.text = trimmed;
    }
    _notesPrefilled = true;
  }

  Future<void> _handleApprove() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    final notes = _notesCtrl.text.trim();
    try {
      await widget.onApprove(notes.isEmpty ? null : notes);
      if (!mounted) return;
      Navigator.of(context).pop(OrganizationReviewResult.approved);
    } on AdminActionException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage =
          'No pudimos aprobar la organización. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject() async {
    if (_isProcessing) return;
    final message = _notesCtrl.text.trim();
    if (message.isEmpty) {
      setState(() => _errorMessage =
          'Describe el motivo del rechazo para notificar a la organización.');
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      await widget.onReject(message);
      if (!mounted) return;
      Navigator.of(context).pop(OrganizationReviewResult.rejected);
    } on AdminActionException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage =
          'No pudimos rechazar la organización. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FB),
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppColors.radiusXl)),
          ),
          child: FutureBuilder<AdminOrganizationDetail>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _OrgLoadingState(item: widget.item);
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _OrgDetailError(onRetry: _retry);
              }
              final detail = snapshot.data!;
              _ensureNotesPrefilled(detail.adminNotes);
              final isPending = detail.status.toLowerCase() == 'pendiente';

              return _OrganizationDetailContent(
                scrollController: scrollController,
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
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading state (hero instantáneo desde el item + loader del cuerpo)
// ─────────────────────────────────────────────────────────────────────────────

class _OrgLoadingState extends StatelessWidget {
  const _OrgLoadingState({required this.item});

  final AdminPendingItem item;

  @override
  Widget build(BuildContext context) {
    final logoUrl = item.coverUrl;
    return Column(
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: const BoxDecoration(gradient: _orgHeroGradient),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: (logoUrl != null && logoUrl.isNotEmpty)
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.business_rounded,
                            color: Colors.white,
                            size: 28),
                      )
                    : const Icon(Icons.business_rounded,
                        color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enviada el ${formatAdminDateTime(item.createdAt)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text(
                  'Cargando detalle…',
                  style: TextStyle(color: AppColors.mediumText, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _OrgDetailError extends StatelessWidget {
  const _OrgDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.orangeAction.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: AppColors.orangeAction),
            ),
            const SizedBox(height: 18),
            const Text(
              'No pudimos cargar el detalle\nde la organización.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orangeAction),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail content
// ─────────────────────────────────────────────────────────────────────────────

class _OrganizationDetailContent extends StatelessWidget {
  const _OrganizationDetailContent({
    required this.scrollController,
    required this.item,
    required this.detail,
    required this.notesController,
    this.onApprove,
    this.onReject,
    this.isProcessing = false,
    this.errorMessage,
  });

  final ScrollController scrollController;
  final AdminPendingItem item;
  final AdminOrganizationDetail detail;
  final TextEditingController notesController;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isProcessing;
  final String? errorMessage;

  bool get _isEditable => onApprove != null || onReject != null;

  Color _docStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprobado':
        return AppColors.greenSuccess;
      case 'rechazado':
        return AppColors.error;
      default:
        return AppColors.orangeAction;
    }
  }

  Widget _mapWidget(String address) {
    const defaultLat = -16.5000;
    const defaultLng = -68.1500;
    double? lat;
    double? lng;
    final matches = RegExp(r'[-]?\d+\.\d+').allMatches(address).toList();
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
              child: const Icon(Icons.location_on,
                  color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdText = formatAdminDateTime(detail.createdAt);

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // ── Drag handle ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        // ── Hero header ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: BoxDecoration(
              gradient: detail.galleryUrls.isEmpty ? _orgHeroGradient : null,
              image: detail.galleryUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(detail.galleryUrls.first),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.45),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Logo / placeholder
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: detail.logoUrl != null &&
                              detail.logoUrl!.isNotEmpty
                          ? Image.network(
                              detail.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.business_rounded,
                                  color: Colors.white,
                                  size: 28),
                            )
                          : const Icon(Icons.business_rounded,
                              color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enviada el $createdText',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Status + type badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusMd),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            detail.status.toLowerCase() == 'aprobada' ||
                                    detail.status.toLowerCase() == 'aprobado'
                                ? Icons.verified_rounded
                                : Icons.schedule_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            detail.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((detail.type ?? '').isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusMd),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.category_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              detail.type!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Body sections ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Description
              if (detail.description?.isNotEmpty == true) ...[
                _OrgSectionCard(
                  icon: Icons.description_rounded,
                  title: 'Descripción',
                  child: Text(
                    detail.description!,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Owner
              if (detail.ownerName?.isNotEmpty == true ||
                  detail.ownerPhone?.isNotEmpty == true ||
                  detail.ownerCity?.isNotEmpty == true ||
                  detail.ownerDocumentNumber?.isNotEmpty == true) ...[
                _OrgSectionCard(
                  icon: Icons.person_rounded,
                  title: 'Responsable',
                  child: Column(
                    children: [
                      if (detail.ownerName?.isNotEmpty == true)
                        _OrgInfoRow(
                          icon: Icons.badge_rounded,
                          label: 'Nombre',
                          value: detail.ownerName!,
                        ),
                      if (detail.ownerPhone?.isNotEmpty == true)
                        _OrgInfoRow(
                          icon: Icons.phone_rounded,
                          label: 'Teléfono',
                          value: detail.ownerPhone!,
                        ),
                      if (detail.ownerCity?.isNotEmpty == true)
                        _OrgInfoRow(
                          icon: Icons.location_city_rounded,
                          label: 'Ciudad',
                          value: detail.ownerCity!,
                        ),
                      if (detail.ownerDocumentNumber?.isNotEmpty == true)
                        _OrgInfoRow(
                          icon: Icons.credit_card_rounded,
                          label: detail.ownerDocumentType?.isNotEmpty == true
                              ? 'Doc. (${detail.ownerDocumentType})'
                              : 'Documento',
                          value: detail.ownerDocumentNumber!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Contact
              if (detail.hasContactInfo) ...[
                _OrgSectionCard(
                  icon: Icons.contact_phone_rounded,
                  title: 'Datos de contacto',
                  child: Column(
                    children: [
                      if (detail.phone?.isNotEmpty == true)
                        _OrgInfoRow(
                          icon: Icons.phone_rounded,
                          label: 'Teléfono',
                          value: detail.phone!,
                        ),
                      if (detail.email?.isNotEmpty == true)
                        _OrgInfoRow(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          value: detail.email!,
                        ),
                      if (detail.website?.isNotEmpty == true)
                        _OrgInfoRow(
                          icon: Icons.language_rounded,
                          label: 'Sitio web',
                          value: detail.website!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Address + map
              if (detail.hasAddress) ...[
                _OrgSectionCard(
                  icon: Icons.location_on_rounded,
                  title: 'Ubicación',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.orangeAction
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusSm),
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                size: 17, color: AppColors.orangeAction),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              detail.address!,
                              style: const TextStyle(
                                color: AppColors.darkText,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusMd),
                        child: SizedBox(
                            height: 200,
                            child: _mapWidget(detail.address!)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Gallery
              if (detail.hasGallery) ...[
                _OrgSectionCard(
                  icon: Icons.photo_library_rounded,
                  title: 'Galería',
                  child: detail.galleryUrls.isEmpty
                      ? Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.grayDark
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusSm),
                              ),
                              child: const Icon(
                                  Icons.photo_library_outlined,
                                  size: 18,
                                  color: AppColors.grayDark),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'No hay imágenes en la galería.',
                                style: TextStyle(
                                    color: AppColors.mediumText, fontSize: 14),
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: detail.galleryUrls.length,
                          itemBuilder: (context, index) {
                            final url = detail.galleryUrls[index];
                            return ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusMd),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.grayLight,
                                      child: const Icon(
                                          Icons.broken_image_rounded,
                                          size: 40,
                                          color: AppColors.grayDark),
                                    ),
                                    loadingBuilder:
                                        (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: AppColors.grayLight,
                                        child: const Center(
                                            child:
                                                CircularProgressIndicator
                                                    .adaptive()),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${index + 1}/${detail.galleryUrls.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
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
                ),
                const SizedBox(height: 12),
              ],

              // Social links
              if (detail.hasSocialLinks) ...[
                _OrgSectionCard(
                  icon: Icons.share_rounded,
                  title: 'Redes sociales',
                  child: Column(
                    children: [
                      for (final link in detail.socialLinks)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.bluePrimary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppColors.radiusSm),
                                ),
                                child: const Icon(Icons.link_rounded,
                                    size: 16,
                                    color: AppColors.bluePrimary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SelectableText(
                                  link,
                                  style: const TextStyle(
                                    color: AppColors.bluePrimary,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_new_rounded,
                                    size: 18,
                                    color: AppColors.mediumText),
                                onPressed: () => _launchExternalUrl(link),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Documents
              if (detail.documents.isNotEmpty) ...[
                _OrgSectionCard(
                  icon: Icons.folder_special_rounded,
                  title: 'Documentos enviados',
                  child: Column(
                    children: [
                      for (int i = 0; i < detail.documents.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                              bottom:
                                  i < detail.documents.length - 1 ? 10 : 0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground,
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusMd),
                              border: Border.all(
                                  color: AppColors.dividerColor
                                      .withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.bluePrimary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppColors.radiusSm),
                                  ),
                                  child: const Icon(
                                      Icons.description_rounded,
                                      size: 18,
                                      color: AppColors.bluePrimary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detail.documents[i].type,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.darkText,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _docStatusColor(
                                                  detail.documents[i].status)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          detail.documents[i].status
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: _docStatusColor(
                                                detail.documents[i].status),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      if (detail.documents[i].adminNotes
                                              ?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          detail.documents[i].adminNotes!,
                                          style: const TextStyle(
                                            color: AppColors.mediumText,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new_rounded,
                                      size: 18,
                                      color: AppColors.mediumText),
                                  onPressed: () => _launchExternalUrl(
                                      detail.documents[i].url),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Notes + action buttons
              _OrgSectionCard(
                icon: Icons.edit_note_rounded,
                title: 'Notas para la organización',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: notesController,
                      enabled: _isEditable,
                      readOnly: !_isEditable,
                      maxLines: 4,
                      minLines: 3,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                          color: AppColors.darkText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _isEditable
                            ? 'Comparte observaciones, requisitos adicionales o el motivo del rechazo.'
                            : 'Sin notas registradas.',
                        filled: true,
                        fillColor: AppColors.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusMd),
                          borderSide: BorderSide(
                              color: AppColors.dividerColor
                                  .withValues(alpha: 0.8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusMd),
                          borderSide: BorderSide(
                              color: AppColors.dividerColor
                                  .withValues(alpha: 0.8)),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusSm),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 16, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(errorMessage!,
                                  style: const TextStyle(
                                      color: AppColors.error, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_isEditable) ...[
                      const SizedBox(height: 16),
                      // Aprobar — gradiente verde (mismo estilo que campaña)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.successGradient,
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.greenSuccess
                                  .withValues(alpha: 0.38),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          onPressed: isProcessing ? null : onApprove,
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_rounded,
                                  size: 20),
                          label: const Text(
                            'Aprobar organización',
                            style: TextStyle(
                              fontSize: AppColors.fontSizeMd,
                              fontWeight: AppColors.fontWeightBold,
                              letterSpacing: AppColors.letterSpacingWide,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppColors.space16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusMd),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Rechazar — outlined rojo, ancho completo (destructivo)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isProcessing ? null : onReject,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Rechazar organización'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusMd),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section card
// ─────────────────────────────────────────────────────────────────────────────

class _OrgSectionCard extends StatelessWidget {
  const _OrgSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      icon: icon,
      title: title,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info row
// ─────────────────────────────────────────────────────────────────────────────

class _OrgInfoRow extends StatelessWidget {
  const _OrgInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DetailInfoRow(icon: icon, label: label, value: value);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _launchExternalUrl(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return;
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('No se pudo abrir el enlace: $rawUrl');
  }
}
