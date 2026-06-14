import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/campaign.dart';
import '../../services/campaign_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_network_image.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/premium_empty_state.dart';
import '../widgets/premium_hero.dart';

class CampaignEvidencePage extends StatefulWidget {
  const CampaignEvidencePage({
    super.key,
    required this.campaign,
    required this.campaignService,
    this.currentUserId,
    this.isAdmin = false,
  });

  final CampaignSummary campaign;
  final CampaignService campaignService;
  final String? currentUserId;
  final bool isAdmin;

  @override
  State<CampaignEvidencePage> createState() => _CampaignEvidencePageState();
}

class _CampaignEvidencePageState extends State<CampaignEvidencePage> {
  late CampaignSummary _campaign;
  List<CampaignEvidence> _evidences = const [];
  bool _loading = true;
  String? _errorMessage;

  bool get _isCreator =>
      widget.currentUserId != null &&
      widget.campaign.creatorId == widget.currentUserId;

  bool get _canUpload =>
      _isCreator &&
      (_campaign.verificationStatus ==
              VerificationStatus.pendienteEvidencia ||
          _campaign.verificationStatus == VerificationStatus.enRevision);

  bool get _canAdminAction =>
      widget.isAdmin &&
      _campaign.verificationStatus == VerificationStatus.enRevision;

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    _loadEvidences();
  }

  Future<void> _loadEvidences() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await widget.campaignService
          .fetchEvidencesByCampaign(_campaign.id);
      if (!mounted) return;
      setState(() {
        _evidences = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No pudimos cargar las evidencias.';
        _loading = false;
      });
    }
  }

  Future<void> _openUploadSheet() async {
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _UploadEvidenceSheet(
        campaignId: _campaign.id,
        campaignService: widget.campaignService,
      ),
    );
    if (uploaded == true && mounted) {
      _loadEvidences();
      // El trigger en DB cambia el estado a en_revision al subir.
      setState(() {
        _campaign = _campaign.copyWith(
          verificationStatus: VerificationStatus.enRevision,
        );
      });
    }
  }

  Future<void> _approveAsAdmin() async {
    final confirmed = await _confirm(
      title: 'Aprobar verificación',
      message:
          '¿Confirmás que la evidencia es suficiente para marcar esta campaña como verificada?',
      confirmLabel: 'Aprobar',
    );
    if (confirmed != true) return;
    try {
      await widget.campaignService.adminApproveVerification(_campaign.id);
      if (!mounted) return;
      setState(() {
        _campaign = _campaign.copyWith(
          verificationStatus: VerificationStatus.verificada,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaña verificada.')),
      );
    } on CampaignServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _rejectAsAdmin() async {
    final reason = await _askReason();
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await widget.campaignService.adminRejectVerification(
        campaignId: _campaign.id,
        reason: reason.trim(),
      );
      if (!mounted) return;
      setState(() {
        _campaign = _campaign.copyWith(
          verificationStatus: VerificationStatus.pendienteEvidencia,
          rejectionReason: reason.trim(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidencia rechazada.')),
      );
    } on CampaignServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<String?> _askReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
        ),
        title: const Text('Motivo del rechazo'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Explica al creador qué le falta…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvidence(CampaignEvidence ev) async {
    final ok = await _confirm(
      title: 'Eliminar evidencia',
      message: '¿Quitar este archivo? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (ok != true) return;
    try {
      await widget.campaignService.deleteEvidence(ev);
      if (!mounted) return;
      setState(() => _evidences =
          _evidences.where((e) => e.id != ev.id).toList(growable: false));
    } on CampaignServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: PremiumAppBar(
        title: 'Evidencias',
        actions: [
          PremiumAppBarAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _loadEvidences,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.bluePrimary),
            )
          : _buildBody(),
      floatingActionButton: _canUpload
          ? FloatingActionButton.extended(
              backgroundColor: _campaign.verificationStatus ==
                      VerificationStatus.enRevision
                  ? AppColors.bluePrimary
                  : AppColors.orangeAction,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: Text(
                _campaign.verificationStatus ==
                        VerificationStatus.enRevision
                    ? 'Agregar más'
                    : 'Subir evidencia',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onPressed: _openUploadSheet,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return PremiumEmptyState(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        title: 'No pudimos cargar las evidencias',
        description: _errorMessage!,
        blobColors: [
          AppColors.error.withValues(alpha: 0.08),
          AppColors.bluePrimary.withValues(alpha: 0.06),
        ],
        action: AppPrimaryButton(
          label: 'Reintentar',
          icon: Icons.refresh_rounded,
          onPressed: _loadEvidences,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.bluePrimary,
      onRefresh: _loadEvidences,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppColors.space20,
              AppColors.space12,
              AppColors.space20,
              AppColors.space16,
            ),
            sliver: SliverToBoxAdapter(
              child: _CampaignHeader(campaign: _campaign),
            ),
          ),
          if (_campaign.rejectionReason?.trim().isNotEmpty == true)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppColors.space20,
                0,
                AppColors.space20,
                AppColors.space16,
              ),
              sliver: SliverToBoxAdapter(
                child: _RejectionCard(reason: _campaign.rejectionReason!),
              ),
            ),
          if (_canAdminAction)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppColors.space20,
                0,
                AppColors.space20,
                AppColors.space16,
              ),
              sliver: SliverToBoxAdapter(
                child: _AdminActions(
                  onApprove: _approveAsAdmin,
                  onReject: _rejectAsAdmin,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppColors.space20,
              0,
              AppColors.space20,
              AppColors.space12,
            ),
            sliver: SliverToBoxAdapter(
              child: PremiumSectionHeader(
                title: 'Evidencias (${_evidences.length})',
                accentGradient: AppColors.primaryGradient,
              ),
            ),
          ),
          if (_evidences.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppColors.space20,
                0,
                AppColors.space20,
                AppColors.space32,
              ),
              sliver: SliverToBoxAdapter(
                child: _NoEvidenceCard(canUpload: _canUpload),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppColors.space20,
                AppColors.space4,
                AppColors.space20,
                AppColors.space64 + AppColors.space24,
              ),
              sliver: _EvidenceGallery(
                evidences: _evidences,
                canDelete: _canUpload,
                currentUserId: widget.currentUserId,
                onDelete: _deleteEvidence,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Campaign header ─────────────────────────────────────────────────────────

class _CampaignHeader extends StatelessWidget {
  const _CampaignHeader({required this.campaign});
  final CampaignSummary campaign;

  @override
  Widget build(BuildContext context) {
    final status = campaign.verificationStatus;

    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (campaign.coverUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: AppNetworkImage(
                      url: campaign.coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: AppColors.greenHope.withValues(alpha: 0.10),
                        child: const Icon(Icons.campaign_rounded,
                            color: AppColors.greenHope, size: 32),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.greenHope.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                  child: const Icon(Icons.campaign_rounded,
                      color: AppColors.greenHope, size: 36),
                ),
              const SizedBox(width: AppColors.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: AppColors.fontSizeMd,
                        fontWeight: AppColors.fontWeightExtraBold,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(status: status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space12),
          Row(
            children: [
              _miniStat(
                Icons.payments_rounded,
                'Bs ${campaign.raisedAmount.toStringAsFixed(0)}',
                AppColors.greenHope,
              ),
              const SizedBox(width: AppColors.space16),
              _miniStat(
                Icons.people_rounded,
                '${campaign.donorCount} donantes',
                AppColors.bluePrimary,
              ),
            ],
          ),
          if (campaign.verificationStatus ==
              VerificationStatus.pendienteEvidencia) ...[
            const SizedBox(height: AppColors.space12),
            _DeadlinePill(campaign: campaign),
          ] else if (campaign.verificationStatus ==
              VerificationStatus.enRevision) ...[
            const SizedBox(height: AppColors.space12),
            _ReviewWaitingPill(),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: AppColors.fontSizeSm,
            fontWeight: AppColors.fontWeightExtraBold,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    late final IconData icon;
    switch (status) {
      case VerificationStatus.verificada:
        color = AppColors.greenHope;
        label = 'Verificada';
        icon = Icons.verified_rounded;
        break;
      case VerificationStatus.pendienteEvidencia:
        color = AppColors.orangeAction;
        label = 'Pendiente de evidencia';
        icon = Icons.hourglass_top_rounded;
        break;
      case VerificationStatus.enRevision:
        color = AppColors.bluePrimary;
        label = 'En revisión';
        icon = Icons.fact_check_rounded;
        break;
      case VerificationStatus.sinVerificar:
        color = AppColors.grayDark;
        label = 'Sin verificar';
        icon = Icons.report_gmailerrorred_rounded;
        break;
      case VerificationStatus.noAplica:
        color = AppColors.greenHope;
        label = 'Meta alcanzada';
        icon = Icons.check_circle_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.space12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppColors.fontSizeXs,
              fontWeight: AppColors.fontWeightExtraBold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill que se muestra cuando ya hay evidencia y estamos esperando que
/// el admin revise. Sin countdown, color neutro.
class _ReviewWaitingPill extends StatelessWidget {
  const _ReviewWaitingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.space12, vertical: AppColors.space8),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: const [
          Icon(Icons.fact_check_rounded,
              color: AppColors.bluePrimary, size: 16),
          SizedBox(width: AppColors.space8),
          Expanded(
            child: Text(
              'Evidencia enviada · Esperando aprobación del admin.',
              style: TextStyle(
                color: AppColors.bluePrimary,
                fontSize: AppColors.fontSizeSm,
                fontWeight: AppColors.fontWeightExtraBold,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlinePill extends StatelessWidget {
  const _DeadlinePill({required this.campaign});
  final CampaignSummary campaign;

  @override
  Widget build(BuildContext context) {
    final days = campaign.daysUntilEvidenceDeadline;
    if (days == null) return const SizedBox.shrink();
    final isUrgent = days <= 3;
    final color = isUrgent ? AppColors.error : AppColors.orangeAction;
    final text = days < 0
        ? 'Plazo vencido'
        : days == 0
            ? 'Vence hoy'
            : days == 1
                ? 'Queda 1 día para subir evidencia'
                : 'Quedan $days días para subir evidencia';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.space12, vertical: AppColors.space8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: color, size: 16),
          const SizedBox(width: AppColors.space8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: AppColors.fontSizeSm,
                fontWeight: AppColors.fontWeightExtraBold,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rejection card ──────────────────────────────────────────────────────────

class _RejectionCard extends StatelessWidget {
  const _RejectionCard({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.feedback_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'El admin pidió más evidencia',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeBase,
                    fontWeight: AppColors.fontWeightExtraBold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    color: AppColors.mediumText,
                    fontSize: AppColors.fontSizeSm,
                    height: 1.4,
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

// ─── Admin actions ───────────────────────────────────────────────────────────

class _AdminActions extends StatelessWidget {
  const _AdminActions({required this.onApprove, required this.onReject});

  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowSm,
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.space8),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: AppColors.bluePrimary, size: 20),
              ),
              const SizedBox(width: AppColors.space12),
              const Expanded(
                child: Text(
                  'Decisión del administrador',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeBase,
                    fontWeight: AppColors.fontWeightExtraBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Aprobar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.greenHope,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppColors.space12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusMd),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: AppColors.fontWeightExtraBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppColors.space8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.4),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppColors.space12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusMd),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: AppColors.fontWeightExtraBold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Evidence card (in gallery list) ────────────────────────────────────────

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.evidence,
    required this.canDelete,
    required this.onDelete,
    this.allImages = const [],
  });

  final CampaignEvidence evidence;
  final bool canDelete;
  final VoidCallback onDelete;
  final List<CampaignEvidence> allImages;

  @override
  Widget build(BuildContext context) {
    final isImage = evidence.isImage && evidence.url.isNotEmpty;
    final imageList = allImages.isEmpty && isImage ? [evidence] : allImages;
    final imageIndex =
        imageList.indexWhere((e) => e.url == evidence.url).clamp(0, imageList.length - 1);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _FullscreenImagePage(
                    images: imageList,
                    initialIndex: imageIndex,
                  ),
                ),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                      url: evidence.url,
                      fit: BoxFit.cover,
                      errorWidget: _filePlaceholder(Icons.broken_image_rounded),
                    ),
                    Positioned(
                      right: AppColors.space8,
                      bottom: AppColors.space8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusSm),
                        ),
                        child: const Icon(
                          Icons.zoom_in_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPreview(),
            ),
          Padding(
            padding: const EdgeInsets.all(AppColors.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeBadge(type: evidence.typeEnum),
                    const Spacer(),
                    if (evidence.createdAt != null)
                      Text(
                        _formatDate(evidence.createdAt!),
                        style: const TextStyle(
                          color: AppColors.lightText,
                          fontSize: AppColors.fontSizeXs,
                          fontWeight: AppColors.fontWeightSemiBold,
                        ),
                      ),
                  ],
                ),
                if (evidence.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppColors.space8),
                  Text(
                    evidence.description!,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: AppColors.fontSizeSm,
                      height: 1.4,
                    ),
                  ),
                ],
                if (canDelete) ...[
                  const SizedBox(height: AppColors.space8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (evidence.isImage && evidence.url.isNotEmpty) {
      return AppNetworkImage(
        url: evidence.url,
        fit: BoxFit.cover,
        errorWidget: _filePlaceholder(Icons.broken_image_rounded),
      );
    }
    if (evidence.isVideo) {
      return _filePlaceholder(Icons.play_circle_fill_rounded,
          openable: true, color: AppColors.bluePrimary);
    }
    if (evidence.isPdf) {
      return _filePlaceholder(Icons.picture_as_pdf_rounded,
          openable: true, color: AppColors.error);
    }
    return _filePlaceholder(Icons.attach_file_rounded, openable: true);
  }

  Widget _filePlaceholder(IconData icon,
      {bool openable = false, Color color = AppColors.bluePrimary}) {
    return InkWell(
      onTap: openable && evidence.url.isNotEmpty
          ? () => launchUrl(Uri.parse(evidence.url),
              mode: LaunchMode.externalApplication)
          : null,
      child: Container(
        color: color.withValues(alpha: 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 56),
            const SizedBox(height: AppColors.space8),
            Text(
              evidence.filename ?? 'Archivo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: AppColors.fontSizeSm,
                fontWeight: AppColors.fontWeightExtraBold,
              ),
            ),
            if (openable) ...[
              const SizedBox(height: 2),
              Text(
                'Tocá para abrir',
                style: TextStyle(
                  color: AppColors.mediumText.withValues(alpha: 0.85),
                  fontSize: AppColors.fontSizeXs,
                  fontWeight: AppColors.fontWeightSemiBold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final EvidenceType type;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    late final IconData icon;
    switch (type) {
      case EvidenceType.foto:
        color = AppColors.greenHope;
        label = 'Foto';
        icon = Icons.photo_rounded;
        break;
      case EvidenceType.video:
        color = AppColors.bluePrimary;
        label = 'Video';
        icon = Icons.videocam_rounded;
        break;
      case EvidenceType.documento:
        color = AppColors.error;
        label = 'Documento';
        icon = Icons.picture_as_pdf_rounded;
        break;
      case EvidenceType.otro:
        color = AppColors.grayDark;
        label = 'Archivo';
        icon = Icons.attach_file_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.space8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppColors.fontSizeXs,
              fontWeight: AppColors.fontWeightExtraBold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Evidence gallery sliver ──────────────────────────────────────────────────

class _EvidenceGallery extends StatelessWidget {
  const _EvidenceGallery({
    required this.evidences,
    required this.canDelete,
    required this.currentUserId,
    required this.onDelete,
  });

  final List<CampaignEvidence> evidences;
  final bool canDelete;
  final String? currentUserId;
  final ValueChanged<CampaignEvidence> onDelete;

  @override
  Widget build(BuildContext context) {
    final images =
        evidences.where((e) => e.isImage && e.url.isNotEmpty).toList();
    final others =
        evidences.where((e) => !e.isImage || e.url.isEmpty).toList();

    // Single item or no photos → original full-width card list
    if (images.length <= 1) {
      return SliverList.separated(
        itemCount: evidences.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppColors.space12),
        itemBuilder: (context, index) {
          final ev = evidences[index];
          return _EvidenceCard(
            evidence: ev,
            canDelete: canDelete &&
                currentUserId != null &&
                ev.uploadedBy == currentUserId,
            onDelete: () => onDelete(ev),
            allImages: images,
          );
        },
      );
    }

    // Multiple images → 2-column photo grid so all are visible at a glance
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSize =
                  (constraints.maxWidth - AppColors.space8) / 2;
              return Wrap(
                spacing: AppColors.space8,
                runSpacing: AppColors.space8,
                children: [
                  for (var i = 0; i < images.length; i++)
                    SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: _ImageThumbnail(
                        evidence: images[i],
                        allImages: images,
                        heroIndex: i,
                        canDelete: canDelete &&
                            currentUserId != null &&
                            images[i].uploadedBy == currentUserId,
                        onDelete: () => onDelete(images[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (others.isNotEmpty)
          SliverPadding(
            padding:
                const EdgeInsets.only(top: AppColors.space12),
            sliver: SliverList.separated(
              itemCount: others.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppColors.space12),
              itemBuilder: (context, index) {
                final ev = others[index];
                return _EvidenceCard(
                  evidence: ev,
                  canDelete: canDelete &&
                      currentUserId != null &&
                      ev.uploadedBy == currentUserId,
                  onDelete: () => onDelete(ev),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── Image thumbnail (grid cell) ─────────────────────────────────────────────

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.evidence,
    required this.allImages,
    required this.heroIndex,
    required this.canDelete,
    required this.onDelete,
  });

  final CampaignEvidence evidence;
  final List<CampaignEvidence> allImages;
  final int heroIndex;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _FullscreenImagePage(
            images: allImages,
            initialIndex: heroIndex,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          color: AppColors.cardBackground,
          boxShadow: AppColors.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(url: evidence.url, fit: BoxFit.cover),
            Positioned(
              right: AppColors.space8,
              bottom: AppColors.space8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius:
                      BorderRadius.circular(AppColors.radiusSm),
                ),
                child: const Icon(Icons.zoom_in_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
            Positioned(
              left: AppColors.space8,
              bottom: AppColors.space8,
              child: _TypeBadge(type: evidence.typeEnum),
            ),
            if (canDelete)
              Positioned(
                right: AppColors.space8,
                top: AppColors.space8,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.85),
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusSm),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Fullscreen image viewer ──────────────────────────────────────────────────

class _FullscreenImagePage extends StatefulWidget {
  const _FullscreenImagePage({
    required this.images,
    required this.initialIndex,
  });

  final List<CampaignEvidence> images;
  final int initialIndex;

  @override
  State<_FullscreenImagePage> createState() => _FullscreenImagePageState();
}

class _FullscreenImagePageState extends State<_FullscreenImagePage> {
  late final PageController _page;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _page = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.images.length > 1
            ? Text(
                '${_current + 1} / ${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppColors.fontSizeSm,
                  fontWeight: AppColors.fontWeightSemiBold,
                ),
              )
            : null,
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _page,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, index) {
          final ev = widget.images[index];
          return InteractiveViewer(
            minScale: 0.7,
            maxScale: 6.0,
            child: Center(
              child: AppNetworkImage(
                url: ev.url,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── No-evidence placeholder ──────────────────────────────────────────────────

class _NoEvidenceCard extends StatelessWidget {
  const _NoEvidenceCard({required this.canUpload});
  final bool canUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppColors.space12),
            decoration: BoxDecoration(
              color: AppColors.orangeAction.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
            ),
            child: const Icon(
              Icons.collections_rounded,
              color: AppColors.orangeAction,
              size: 26,
            ),
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aún no hay evidencias',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeBase,
                    fontWeight: AppColors.fontWeightExtraBold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  canUpload
                      ? 'Subí fotos o videos de cómo se usó el dinero para que tu campaña quede verificada.'
                      : 'Cuando el creador suba las evidencias aparecerán acá.',
                  style: const TextStyle(
                    color: AppColors.mediumText,
                    fontSize: AppColors.fontSizeSm,
                    height: 1.4,
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

String _formatDate(DateTime d) {
  final months = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

// ─── Upload sheet ───────────────────────────────────────────────────────────

class _UploadEvidenceSheet extends StatefulWidget {
  const _UploadEvidenceSheet({
    required this.campaignId,
    required this.campaignService,
  });

  final String campaignId;
  final CampaignService campaignService;

  @override
  State<_UploadEvidenceSheet> createState() => _UploadEvidenceSheetState();
}

class _UploadEvidenceSheetState extends State<_UploadEvidenceSheet> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descController = TextEditingController();
  final List<_PendingFile> _pending = [];
  bool _uploading = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final list = await _picker.pickMultiImage(imageQuality: 85);
      if (list.isEmpty) return;
      for (final x in list) {
        final bytes = await x.readAsBytes();
        _pending.add(_PendingFile(
          xFile: x,
          bytes: bytes,
          type: EvidenceType.foto,
        ));
      }
      if (mounted) setState(() {});
    } catch (e) {
      _snack('No pudimos abrir la galería: $e');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final x = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 85);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      _pending.add(_PendingFile(
        xFile: x,
        bytes: bytes,
        type: EvidenceType.foto,
      ));
      if (mounted) setState(() {});
    } catch (e) {
      _snack('No pudimos abrir la cámara: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final x = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (bytes.length > 20 * 1024 * 1024) {
        _snack('El video supera los 20 MB permitidos.');
        return;
      }
      _pending.add(_PendingFile(
        xFile: x,
        bytes: bytes,
        type: EvidenceType.video,
      ));
      if (mounted) setState(() {});
    } catch (e) {
      _snack('No pudimos abrir el video: $e');
    }
  }

  void _removeAt(int i) {
    setState(() => _pending.removeAt(i));
  }

  Future<void> _upload() async {
    if (_pending.isEmpty) {
      _snack('Selecciona al menos un archivo.');
      return;
    }
    setState(() => _uploading = true);
    try {
      for (final p in _pending) {
        await widget.campaignService.uploadEvidence(
          campaignId: widget.campaignId,
          data: p.bytes,
          filename: p.filename,
          mimeType: p.mimeType,
          type: p.type,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CampaignServiceException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Error subiendo: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                AppColors.space20,
                AppColors.space12,
                AppColors.space20,
                AppColors.space24 + mq.padding.bottom,
              ),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.grayNeutral.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: AppColors.space20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppColors.space12),
                      decoration: BoxDecoration(
                        gradient: AppColors.actionGradient,
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orangeAction
                                .withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.cloud_upload_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppColors.space12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subir evidencia',
                            style: TextStyle(
                              color: AppColors.darkText,
                              fontSize: AppColors.fontSizeXl,
                              fontWeight: AppColors.fontWeightExtraBold,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Fotos y videos cortos (máx. 20 MB cada uno).',
                            style: TextStyle(
                              color: AppColors.mediumText,
                              fontSize: AppColors.fontSizeSm,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppColors.space20),
                Row(
                  children: [
                    Expanded(
                      child: _PickerButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Galería',
                        color: AppColors.bluePrimary,
                        onPressed: _uploading ? null : _pickPhotos,
                      ),
                    ),
                    const SizedBox(width: AppColors.space8),
                    Expanded(
                      child: _PickerButton(
                        icon: Icons.photo_camera_rounded,
                        label: 'Cámara',
                        color: AppColors.greenHope,
                        onPressed: _uploading ? null : _pickFromCamera,
                      ),
                    ),
                    const SizedBox(width: AppColors.space8),
                    Expanded(
                      child: _PickerButton(
                        icon: Icons.videocam_rounded,
                        label: 'Video',
                        color: AppColors.orangeAction,
                        onPressed: _uploading ? null : _pickVideo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppColors.space20),
                TextField(
                  controller: _descController,
                  enabled: !_uploading,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText:
                        'Ej. compra de medicamentos para los pacientes…',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(AppColors.space16),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusMd),
                      borderSide: const BorderSide(
                          color: AppColors.dividerColor, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusMd),
                      borderSide: const BorderSide(
                          color: AppColors.bluePrimary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: AppColors.space20),
                if (_pending.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppColors.space20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusLg),
                      border: Border.all(
                        color: AppColors.grayLight.withValues(alpha: 0.9),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.collections_rounded,
                            color: AppColors.lightText, size: 28),
                        SizedBox(width: AppColors.space12),
                        Expanded(
                          child: Text(
                            'Aún no seleccionaste archivos. Tocá los botones de arriba.',
                            style: TextStyle(
                              color: AppColors.mediumText,
                              fontSize: AppColors.fontSizeSm,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      for (var i = 0; i < _pending.length; i++) ...[
                        _PendingTile(
                          file: _pending[i],
                          onRemove: _uploading ? null : () => _removeAt(i),
                        ),
                        const SizedBox(height: AppColors.space8),
                      ],
                    ],
                  ),
                const SizedBox(height: AppColors.space24),
                AppPrimaryButton(
                  label: _uploading
                      ? 'Subiendo…'
                      : _pending.isEmpty
                          ? 'Selecciona archivos'
                          : 'Subir ${_pending.length} ${_pending.length == 1 ? "archivo" : "archivos"}',
                  icon: _uploading ? null : Icons.cloud_upload_rounded,
                  onPressed: _uploading || _pending.isEmpty ? null : _upload,
                ),
                const SizedBox(height: AppColors.space8),
                AppSecondaryButton(
                  label: 'Cancelar',
                  onPressed: _uploading
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PendingFile {
  _PendingFile({
    required this.xFile,
    required this.bytes,
    required this.type,
  });

  final XFile xFile;
  final Uint8List bytes;
  final EvidenceType type;

  String get filename => xFile.name;
  String get mimeType {
    final mt = xFile.mimeType;
    if (mt != null && mt.isNotEmpty) return mt;
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'jpg':
      case 'jpeg':
      default:
        return type == EvidenceType.video ? 'video/mp4' : 'image/jpeg';
    }
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: color.withValues(alpha: disabled ? 0.05 : 0.10),
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppColors.space12, vertical: AppColors.space12),
          child: Column(
            children: [
              Icon(icon,
                  color: color.withValues(alpha: disabled ? 0.5 : 1.0),
                  size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: disabled ? 0.5 : 1.0),
                  fontSize: AppColors.fontSizeSm,
                  fontWeight: AppColors.fontWeightExtraBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.file, required this.onRemove});

  final _PendingFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isImage = file.type == EvidenceType.foto;
    return Container(
      padding: const EdgeInsets.all(AppColors.space8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.grayLight.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            child: SizedBox(
              width: 56,
              height: 56,
              child: isImage
                  ? Image.memory(file.bytes, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.bluePrimary.withValues(alpha: 0.10),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: AppColors.bluePrimary,
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeSm,
                    fontWeight: AppColors.fontWeightExtraBold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(file.bytes.length / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: const TextStyle(
                    color: AppColors.mediumText,
                    fontSize: AppColors.fontSizeXs,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.error),
              onPressed: onRemove,
              tooltip: 'Quitar',
            ),
        ],
      ),
    );
  }
}
