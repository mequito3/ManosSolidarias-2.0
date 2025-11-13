import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:saver_gallery/saver_gallery.dart';

import '../../../../models/campaign.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/campaign_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/highlight_wrapper.dart';

part 'campaign_detail_view.dart';
part 'story_section.dart';
part 'overview_sections.dart';
part 'evidence_section.dart';
part 'comments_section.dart';
part 'donation_sheet.dart';
part 'detail_error.dart';
part 'share_sheet.dart';

class CampaignDetailPage extends StatefulWidget {
  const CampaignDetailPage({
    super.key,
    required this.campaignSummary,
    required this.campaignService,
    required this.userProfile,
    this.highlightCommentId,
    this.highlightDonationId,
  });

  final CampaignSummary campaignSummary;
  final CampaignService campaignService;
  final UserProfile userProfile;
  
  /// ID del comentario que debe ser resaltado (desde notificación)
  final String? highlightCommentId;
  
  /// ID de la donación que debe ser resaltada (desde notificación)
  final String? highlightDonationId;

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  late Future<_CampaignDetailBundle> _bundleFuture;
  CampaignDetail? _lastDetail;
  List<CampaignComment> _comments = const [];
  bool _isSubmittingComment = false;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _bundleFuture = _loadDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<_CampaignDetailBundle> _loadDetail() async {
    final campaignId = widget.campaignSummary.id;

    final detail = await widget.campaignService.fetchCampaignDetail(campaignId);
    var comments = <CampaignComment>[];
    try {
      comments = await widget.campaignService.fetchComments(campaignId);
    } catch (error) {
      debugPrint('CampaignDetailPage._loadDetail comments error: $error');
    }

    if (mounted) {
      setState(() {
        _comments = comments;
      });
    }

    return _CampaignDetailBundle(detail: detail, comments: comments);
  }

  Future<void> _handleSubmitComment(String message) async {
    if (_isSubmittingComment) {
      return;
    }

    final trimmed = message.trim();
    if (trimmed.length < 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe al menos 3 caracteres para comentar.')),
        );
      }
      return;
    }

    if (!widget.campaignService.hasAuthenticatedUser) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para publicar un comentario.')),
        );
      }
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final newComment = await widget.campaignService.createComment(
        campaignId: widget.campaignSummary.id,
        message: trimmed,
      );

      if (!mounted) {
        return;
      }

      List<CampaignComment> refreshed = _comments;
      try {
        refreshed = await widget.campaignService.fetchComments(widget.campaignSummary.id);
      } catch (error) {
        debugPrint('CampaignDetailPage._handleSubmitComment refresh error: $error');
        refreshed = [newComment, ..._comments];
      }

      setState(() {
        _isSubmittingComment = false;
        _comments = refreshed;
        _commentController.clear();
      });

      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario publicado.')),
      );
    } on CampaignServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmittingComment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      debugPrint('CampaignDetailPage._handleSubmitComment error: $error');
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmittingComment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos publicar tu comentario. Intenta nuevamente.')),
      );
    }
  }

  Future<void> _handleSupportTap() async {
    // Validar que el usuario tiene datos básicos para donar
    if (!widget.userProfile.canDonate) {
      if (!mounted) return;
      
      final shouldComplete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Completa tu perfil'),
          content: const Text(
            'Para poder donar, necesitas completar tu información personal '
            '(nombre, documento, teléfono, ciudad y dirección).\n\n'
            '¿Deseas completar tu perfil ahora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Después'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Completar perfil'),
            ),
          ],
        ),
      );

      if (shouldComplete == true && mounted) {
        // Navegar a configuración de perfil
        Navigator.pushNamed(context, '/profile/settings');
      }
      return;
    }

    final detail = _lastDetail ??
        CampaignDetail(
          summary: widget.campaignSummary,
          longDescription: widget.campaignSummary.shortDescription,
        );

    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => _DonationPage(
          detail: detail,
          campaignService: widget.campaignService,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      setState(() {
        _bundleFuture = _loadDetail();
      });
    }
  }

  bool _canDeleteCampaign(CampaignSummary summary) {
    // Verificar si el usuario actual es el creador
    final currentUserId = widget.campaignService.currentUserId;
    if (currentUserId == null || summary.creatorId != currentUserId) {
      return false;
    }

    // Verificar que la campaña pueda ser eliminada (pendiente y sin donaciones)
    return summary.canBeDeleted;
  }

  Future<void> _handleDeleteRequest(CampaignSummary summary) async {
    if (!mounted) return;

    // Confirmar eliminación
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar solicitud'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta solicitud?\n\n'
          'Esta acción no se puede deshacer. Solo puedes eliminar '
          'solicitudes pendientes que no tengan donaciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Usar requestId si existe, sino usar el id de la campaña
      final requestId = summary.requestId ?? summary.id;
      final deleted = await widget.campaignService.deletePendingRequest(requestId);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (deleted) {
        // Cerrar la página de detalle y volver atrás
        Navigator.pop(context, true); // true indica que hubo cambios
        
        // Mostrar mensaje de éxito
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Solicitud eliminada correctamente');
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading
      
      // Mostrar error
      final message = e.toString().replaceAll('CampaignServiceException: ', '');
      AppSnackBar.showError(context, message);
    }
  }

  Future<void> _handleEvidenceTap(CampaignEvidence evidence) async {
    if (!mounted) {
      return;
    }

    final resolvedPreviewUrl = evidence.thumbnailUrl?.trim().isNotEmpty == true
        ? evidence.thumbnailUrl!.trim()
        : evidence.url.trim();
    final hasImagePreview = resolvedPreviewUrl.isNotEmpty &&
        (_isImageEvidenceType(evidence.type) || _looksLikeImageUrl(resolvedPreviewUrl));
    final heroTag = hasImagePreview ? 'campaign-evidence-${evidence.id}' : null;
    final normalizedDescription = _normalizeEvidenceDescription(evidence.description);

    await Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      opaque: true,
      pageBuilder: (routeContext, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: _EvidenceViewerPage(
            evidence: evidence,
            previewUrl: hasImagePreview ? resolvedPreviewUrl : null,
            hasImagePreview: hasImagePreview,
            heroTag: heroTag,
            description: normalizedDescription,
            onOpenLink: _openExternalLink,
          ),
        );
      },
    ));
  }

  Future<bool> _openExternalLink(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El enlace no es válido.')),
        );
      }
      return false;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos abrir el enlace.')),
        );
      }
      return launched;
    } catch (error) {
      debugPrint('CampaignDetailPage._openExternalLink error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un problema al abrir el enlace.')),
        );
      }
      return false;
    }
  }

  Future<void> _handleShare() async {
    final shareUrl = _buildShareUrl();
    final title = widget.campaignSummary.title.trim();
    final description = widget.campaignSummary.shortDescription.trim();
    final shareMessage = [
      if (title.isNotEmpty) title,
      if (description.isNotEmpty) description,
      'Súmate a la campaña: $shareUrl',
    ].join('\n\n');

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ShareSheet(
          title: 'Compartir campaña',
          subtitle: 'Difunde esta causa en tus canales de confianza.',
          options: [
            _ShareOption(
              icon: Icons.link_rounded,
              label: 'Enlace',
              description: 'Copiar link',
              iconColor: Colors.white,
              backgroundColor: AppColors.bluePrimary,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: shareUrl));
                if (!mounted) {
                  return;
                }
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enlace copiado al portapapeles.')),
                );
              },
            ),
            _ShareOption(
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              description: 'Enviar mensaje',
              iconColor: Colors.white,
              backgroundColor: Color(0xFF25D366),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareMessage)}');
                await _launchShareUri(uri);
              },
            ),
            _ShareOption(
              icon: Icons.facebook,
              label: 'Facebook',
              description: 'Publicar',
              iconColor: Colors.white,
              backgroundColor: Color(0xFF1877F2),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final uri = Uri.parse(
                  'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}',
                );
                await _launchShareUri(uri);
              },
            ),
            _ShareOption(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              description: 'Enviar correo',
              iconColor: Colors.white,
              backgroundColor: Color(0xFFEA4335),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final emailUri = Uri(
                  scheme: 'mailto',
                  queryParameters: {
                    'subject': title.isNotEmpty ? title : 'Campaña solidaria',
                    'body': shareMessage,
                  },
                );
                await _launchShareUri(emailUri);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchShareUri(Uri uri) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) {
        return;
      }
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No encontramos una aplicación para compartir.')),
        );
      }
    } catch (error) {
      debugPrint('CampaignDetailPage._launchShareUri error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos abrir la opción de compartir.')),
        );
      }
    }
  }

  String _buildShareUrl() {
    final slug = widget.campaignSummary.slug.trim();
    if (slug.isNotEmpty) {
      return 'https://manossolidarias.bo/campanas/$slug';
    }
    final id = widget.campaignSummary.id.trim();
    if (id.isNotEmpty) {
      return 'https://manossolidarias.bo/campanas/$id';
    }
    return 'https://manossolidarias.bo/campanas';
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.campaignSummary;
    final canSupport = !summary.isCompleted;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          summary.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          // Botón eliminar (solo para el creador de solicitudes pendientes sin donaciones)
          if (_canDeleteCampaign(summary))
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 22),
                color: AppColors.error,
                tooltip: 'Eliminar solicitud',
                onPressed: () => _handleDeleteRequest(summary),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: AppColors.space8),
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, size: 22),
              color: AppColors.bluePrimary,
              tooltip: 'Compartir campaña',
              onPressed: _handleShare,
            ),
          ),
        ],
      ),
      bottomNavigationBar: canSupport
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                minimum: const EdgeInsets.symmetric(
                  horizontal: AppColors.space24,
                  vertical: AppColors.space16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.actionGradient,
                    borderRadius: BorderRadius.circular(AppColors.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orangeAction.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _handleSupportTap,
                    icon: const Icon(Icons.favorite_rounded, size: 24),
                    label: const Text(
                      'Apoyar esta campaña',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppColors.space16),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusLg),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: FutureBuilder<_CampaignDetailBundle>(
        future: _bundleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _DetailError(
              onRetry: () {
                setState(() {
                  _bundleFuture = _loadDetail();
                });
              },
            );
          }

          final bundle = snapshot.data;
          final detail = bundle?.detail ??
              CampaignDetail(
                summary: summary,
                longDescription: summary.shortDescription,
              );
          final comments = _comments.isEmpty ? (bundle?.comments ?? const []) : _comments;

          _lastDetail = detail;

          return _CampaignDetailView(
            detail: detail,
            comments: comments,
            canSupport: canSupport,
            onSupportTap: canSupport ? _handleSupportTap : null,
            onEvidenceTap: _handleEvidenceTap,
            onOpenLink: (url) => _openExternalLink(url),
            canComment: widget.campaignService.hasAuthenticatedUser,
            commentController: _commentController,
            onSubmitComment: _handleSubmitComment,
            isSubmittingComment: _isSubmittingComment,
            // 🎯 Pasar parámetros de highlight
            highlightCommentId: widget.highlightCommentId,
            highlightDonationId: widget.highlightDonationId,
          );
        },
      ),
    );
  }
}

class _CampaignDetailBundle {
  const _CampaignDetailBundle({this.detail, this.comments = const []});

  final CampaignDetail? detail;
  final List<CampaignComment> comments;
}

bool _looksLikeImageUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('data:image/')) {
    return true;
  }

  final uri = Uri.tryParse(trimmed);
  final normalizedPath = (uri?.path ?? trimmed).toLowerCase();
  final sanitizedPath = normalizedPath.split('?').first.split('#').first;
  const imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif'];
  if (imageExtensions.any((ext) => sanitizedPath.endsWith(ext))) {
    return true;
  }

  final formatParam = uri?.queryParameters['format']?.toLowerCase();
  if (formatParam != null) {
    final normalizedFormat = formatParam.split('/').last;
    if (imageExtensions.any((ext) =>
        normalizedFormat.contains(ext.replaceAll('.', '')))) {
      return true;
    }
  }

  final contentTypeParam = uri?.queryParameters['contentType']?.toLowerCase();
  if (contentTypeParam != null) {
    final normalizedContentType = contentTypeParam.split('/').last;
    if (imageExtensions.any((ext) =>
        normalizedContentType.contains(ext.replaceAll('.', '')))) {
      return true;
    }
  }

  return false;
}

bool _isImageEvidenceType(String rawType) {
  final normalized = rawType.toLowerCase();
  return normalized == 'foto' ||
      normalized == 'fotografia' ||
      normalized == 'fotografía' ||
      normalized == 'imagen' ||
      normalized == 'image' ||
      normalized == 'photo' ||
      normalized == 'picture';
}

IconData _evidenceIconForType(String rawType) {
  final normalized = rawType.toLowerCase();
  if (normalized.contains('video')) {
    return Icons.videocam_outlined;
  }
  if (normalized.contains('pdf') ||
      normalized.contains('doc') ||
      normalized.contains('xls') ||
      normalized.contains('ppt')) {
    return Icons.insert_drive_file_outlined;
  }
  if (_isImageEvidenceType(normalized)) {
    return Icons.photo_library_outlined;
  }
  return Icons.attachment_outlined;
}

String _formatCurrency(double value) {
  if (value >= 1000000) {
    return 'Bs ${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return 'Bs ${(value / 1000).toStringAsFixed(1)}K';
  }
  return 'Bs ${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}';
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day/$month/$year';
}
