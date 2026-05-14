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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

    final results = await Future.wait<dynamic>([
      widget.campaignService.fetchCampaignDetail(campaignId),
      widget.campaignService.fetchComments(campaignId).catchError((Object error) {
        debugPrint('CampaignDetailPage._loadDetail comments error: $error');
        return <CampaignComment>[];
      }),
    ]);

    final detail = results[0] as CampaignDetail?;
    final comments = (results[1] as List).cast<CampaignComment>();

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
        AppSnackBar.showError(context, 'Escribe al menos 3 caracteres para comentar.');
      }
      return;
    }

    if (!widget.campaignService.hasAuthenticatedUser) {
      if (mounted) {
        AppSnackBar.showError(context, 'Inicia sesión para publicar un comentario.');
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
      AppSnackBar.showSuccess(context, 'Comentario publicado.');
    } on CampaignServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmittingComment = false;
      });

      AppSnackBar.showError(context, error.message);
    } catch (error) {
      debugPrint('CampaignDetailPage._handleSubmitComment error: $error');
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmittingComment = false;
      });

      AppSnackBar.showError(context, 'No pudimos publicar tu comentario. Intenta nuevamente.');
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

    final allEvidences = _lastDetail?.evidences ?? [evidence];
    final initialIndex =
        allEvidences.indexWhere((e) => e.id == evidence.id).clamp(0, allEvidences.length - 1);

    await Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      pageBuilder: (routeContext, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: _EvidenceViewerPage(
            evidences: allEvidences,
            initialIndex: initialIndex,
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

  /// Mensaje enriquecido para WhatsApp (soporta *negrita* y _cursiva_).
  String _buildWhatsAppMessage() {
    final s = widget.campaignSummary;
    final title = s.title.trim();
    final desc = s.shortDescription.trim();
    final pct = s.completionPercentage.toStringAsFixed(0);
    final raised = _formatCurrency(s.raisedAmount);
    final goal = _formatCurrency(s.goalAmount);
    final donors = s.donorCount;
    final category = s.category.trim();
    final organizer = (s.organizerName ?? '').trim();

    final lines = <String>[
      '🌟 *${title.isNotEmpty ? title : 'Campaña solidaria'}* 🌟',
      '',
      '🙏 Esta causa solidaria en Bolivia necesita tu apoyo.',
      if (desc.isNotEmpty) '',
      if (desc.isNotEmpty) '"$desc"',
      '',
      '📊 *Progreso actual*',
      '💰 Recaudado: $raised  /  Meta: $goal',
      '📈 Avance: $pct% completado',
      if (donors > 0) '👥 $donors ${donors == 1 ? 'persona ya donó' : 'personas ya donaron'}',
      if (category.isNotEmpty) '📂 Categoría: $category',
      if (organizer.isNotEmpty) '🏢 Organiza: $organizer',
      '',
      '📲 Pide a tu contacto que descargue la app *Manos Solidarias* para apoyar la causa.',
      '',
      '_Difunde esta causa y ayuda a alcanzar la meta_ 💙',
    ];
    return lines.join('\n');
  }

  /// Cuerpo del correo con formato legible en cualquier cliente de email.
  String _buildEmailBody() {
    final s = widget.campaignSummary;
    final title = s.title.trim();
    final desc = s.shortDescription.trim();
    final pct = s.completionPercentage.toStringAsFixed(0);
    final raised = _formatCurrency(s.raisedAmount);
    final goal = _formatCurrency(s.goalAmount);
    final donors = s.donorCount;
    final category = s.category.trim();
    final organizer = (s.organizerName ?? '').trim();
    const separator = '------------------------------------------';

    final lines = <String>[
      'Hola,',
      '',
      'Te comparto esta campaña solidaria que merece tu apoyo:',
      '',
      separator,
      '📌 ${title.toUpperCase()}',
      if (category.isNotEmpty) 'Categoría: $category',
      if (organizer.isNotEmpty) 'Organizado por: $organizer',
      separator,
      if (desc.isNotEmpty) '',
      if (desc.isNotEmpty) '"$desc"',
      '',
      'PROGRESO ACTUAL',
      '• Recaudado : $raised',
      '• Meta      : $goal',
      '• Avance    : $pct%',
      if (donors > 0) '• Donantes  : $donors ${donors == 1 ? 'persona' : 'personas'}',
      '',
      'Para apoyar esta campaña, descarga la app Manos Solidarias.',
      '',
      '¡Juntos podemos lograrlo! Gracias por difundir esta causa.',
      '',
      separator,
      'Manos Solidarias  |  App solidaria en Bolivia',
    ];
    return lines.join('\n');
  }

  Future<void> _handleShare() async {
    final title = widget.campaignSummary.title.trim();
    final whatsAppText = _buildWhatsAppMessage();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _ShareSheet(
          campaignTitle: title.isNotEmpty ? title : 'Campaña solidaria',
          options: [
            _ShareOption(
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              description: 'Enviar por mensaje directo',
              accentColor: const Color(0xFF25D366),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final uri = Uri.parse(
                    'https://wa.me/?text=${Uri.encodeComponent(whatsAppText)}');
                await _launchShareUri(uri);
              },
            ),
            _ShareOption(
              icon: Icons.facebook,
              label: 'Facebook',
              description: 'Compartir en tu muro',
              accentColor: const Color(0xFF1877F2),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final quote = title.isNotEmpty
                    ? '🌟 $title — Súmate en Manos Solidarias 💙'
                    : '🌟 Campaña solidaria en Manos Solidarias 💙';
                final uri = Uri.parse(
                  'https://www.facebook.com/sharer/sharer.php'
                  '?quote=${Uri.encodeComponent(quote)}',
                );
                await _launchShareUri(uri);
              },
            ),
            _ShareOption(
              icon: Icons.mail_outline_rounded,
              label: 'Correo electrónico',
              description: 'Enviar a tus contactos',
              accentColor: const Color(0xFFEA4335),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final subject = title.isNotEmpty
                    ? '$title — Manos Solidarias'
                    : 'Campaña solidaria — Manos Solidarias';
                final emailUri = Uri(
                  scheme: 'mailto',
                  queryParameters: {
                    'subject': subject,
                    'body': _buildEmailBody(),
                  },
                );
                await _launchShareUri(emailUri);
              },
            ),
            _ShareOption(
              icon: Icons.copy_rounded,
              label: 'Copiar mensaje',
              description: 'Listo para pegar en cualquier app',
              accentColor: AppColors.bluePrimary,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: whatsAppText));
                Navigator.of(sheetContext).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Mensaje copiado al portapapeles.')),
                );
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

  @override
  Widget build(BuildContext context) {
    final summary = widget.campaignSummary;
    final canSupport = !summary.isCompleted;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: _GlassCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        title: const SizedBox.shrink(),
        actions: [
          if (_canDeleteCampaign(summary))
            Padding(
              padding: const EdgeInsets.only(right: 6, top: 10, bottom: 10),
              child: _GlassCircleButton(
                icon: Icons.delete_outline,
                onTap: () => _handleDeleteRequest(summary),
                tooltip: 'Eliminar solicitud',
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            child: _GlassCircleButton(
              icon: Icons.ios_share_rounded,
              onTap: _handleShare,
              tooltip: 'Compartir campaña',
            ),
          ),
        ],
      ),
      bottomNavigationBar: canSupport
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.darkText.withValues(alpha: 0.07),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSupportTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangeAction,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apoyar esta campaña',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.1,
                        ),
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
            userProfile: widget.userProfile,
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

/// Botón circular tipo iOS: blur sutil + fondo semi-transparente.
class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.black.withValues(alpha: 0.30),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(icon, color: Colors.white, size: 19),
            ),
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
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
  return 'Bs ${_thousandSepDetail(value.round())}';
}

String _thousandSepDetail(int value) {
  final isNegative = value < 0;
  final str = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return isNegative ? '-${buf.toString()}' : buf.toString();
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day/$month/$year';
}
