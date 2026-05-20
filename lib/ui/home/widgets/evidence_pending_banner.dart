import 'package:flutter/material.dart';

import '../../../models/campaign.dart';
import '../../../models/user_profile.dart';
import '../../../services/campaign_service.dart';
import '../../../theme/app_colors.dart';
import '../campaign_evidence_page.dart';

/// Banner que aparece en el home si el usuario tiene campañas que
/// requieren subir evidencia. Auto-oculta si no hay nada pendiente.
class EvidencePendingBanner extends StatefulWidget {
  const EvidencePendingBanner({
    super.key,
    required this.campaignService,
    required this.userProfile,
  });

  final CampaignService campaignService;
  final UserProfile userProfile;

  @override
  State<EvidencePendingBanner> createState() => _EvidencePendingBannerState();
}

class _EvidencePendingBannerState extends State<EvidencePendingBanner> {
  List<CampaignSummary> _pending = const [];
  bool _loading = true;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.campaignService.fetchMyPendingEvidenceCampaigns();
    if (!mounted) return;
    setState(() {
      _pending = list;
      _loading = false;
    });
  }

  void _openFirst() {
    final c = _pending.first;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CampaignEvidencePage(
          campaign: c,
          campaignService: widget.campaignService,
          currentUserId: widget.userProfile.userId,
          isAdmin: widget.userProfile.isAdmin,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pending.isEmpty || _dismissed) {
      return const SizedBox.shrink();
    }

    final first = _pending.first;
    final inReview =
        first.verificationStatus == VerificationStatus.enRevision;
    final days = first.daysUntilEvidenceDeadline;
    final isUrgent = !inReview && days != null && days <= 3;

    // En revision = neutro (azul). Pendiente = naranja, rojo si urgente.
    final accent = inReview
        ? AppColors.bluePrimary
        : isUrgent
            ? AppColors.error
            : AppColors.orangeAction;

    final String headerText;
    if (inReview) {
      headerText = _pending.length == 1
          ? 'Tu evidencia está en revisión'
          : '${_pending.length} campañas en revisión';
    } else {
      final base = _pending.length == 1
          ? 'Tenés 1 campaña pendiente de evidencia'
          : 'Tenés ${_pending.length} campañas pendientes de evidencia';
      final daysText = days == null
          ? ''
          : days < 0
              ? ' · Plazo vencido'
              : days == 0
                  ? ' · Vence hoy'
                  : days == 1
                      ? ' · Queda 1 día'
                      : ' · Quedan $days días';
      headerText = base + daysText;
    }

    final ctaText = inReview
        ? 'Esperando aprobación del admin.'
        : 'Tocá para subir fotos, recibos o videos.';

    final iconData = inReview
        ? Icons.fact_check_rounded
        : Icons.cloud_upload_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          onTap: _openFirst,
          child: Container(
            padding: const EdgeInsets.all(AppColors.space16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.12),
                  accent.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              border: Border.all(
                color: accent.withValues(alpha: 0.40),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, accent.withValues(alpha: 0.75)],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    iconData,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppColors.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        headerText,
                        style: TextStyle(
                          color: accent,
                          fontSize: AppColors.fontSizeSm,
                          fontWeight: AppColors.fontWeightExtraBold,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        first.title,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: AppColors.fontSizeBase,
                          fontWeight: AppColors.fontWeightBold,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ctaText,
                        style: const TextStyle(
                          color: AppColors.mediumText,
                          fontSize: AppColors.fontSizeXs,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppColors.space8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: accent.withValues(alpha: 0.10),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _dismissed = true),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: accent,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: accent, size: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}
