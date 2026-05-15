import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/face_redaction_service.dart';
import '../../theme/app_colors.dart';
import 'app_buttons.dart';

/// Resultado de la pantalla de redacción.
class FaceRedactionResult {
  const FaceRedactionResult({
    required this.redactedBytes,
    required this.facesRedacted,
    required this.facesDetected,
  });

  final Uint8List redactedBytes;
  final int facesRedacted;
  final int facesDetected;
}

/// Pantalla intermedia que muestra una foto con las caras detectadas
/// resaltadas. El usuario puede tocar cada caja para incluirla o
/// excluirla de la redacción antes de subir.
class FaceRedactionPreview extends StatefulWidget {
  const FaceRedactionPreview({
    super.key,
    required this.imageBytes,
    required this.imagePath,
    required this.service,
  });

  final Uint8List imageBytes;
  final String imagePath;
  final FaceRedactionService service;

  static Future<FaceRedactionResult?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    required String imagePath,
    required FaceRedactionService service,
  }) {
    return Navigator.of(context).push<FaceRedactionResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FaceRedactionPreview(
          imageBytes: imageBytes,
          imagePath: imagePath,
          service: service,
        ),
      ),
    );
  }

  @override
  State<FaceRedactionPreview> createState() => _FaceRedactionPreviewState();
}

class _FaceRedactionPreviewState extends State<FaceRedactionPreview> {
  late Future<_DetectionData> _detectionFuture;
  final Set<int> _excludedIndices = <int>{};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _detectionFuture = _runDetection();
  }

  Future<_DetectionData> _runDetection() async {
    final image = await decodeImageFromList(widget.imageBytes);
    final faces = await widget.service.detectFaces(widget.imagePath);
    return _DetectionData(
      imageWidth: image.width.toDouble(),
      imageHeight: image.height.toDouble(),
      faces: faces,
    );
  }

  Future<void> _confirm(_DetectionData data) async {
    setState(() => _isProcessing = true);
    final included = <Rect>[];
    for (var i = 0; i < data.faces.length; i++) {
      if (!_excludedIndices.contains(i)) {
        included.add(data.faces[i]);
      }
    }
    final redacted = widget.service.redactRegions(
      originalBytes: widget.imageBytes,
      boxes: included,
    );
    if (!mounted) return;
    Navigator.of(context).pop(
      FaceRedactionResult(
        redactedBytes: redacted,
        facesRedacted: included.length,
        facesDetected: data.faces.length,
      ),
    );
  }

  void _skipRedaction(_DetectionData data) {
    Navigator.of(context).pop(
      FaceRedactionResult(
        redactedBytes: widget.imageBytes,
        facesRedacted: 0,
        facesDetected: data.faces.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Revisar privacidad',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.darkText,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.darkText),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Cancelar',
        ),
      ),
      body: FutureBuilder<_DetectionData>(
        future: _detectionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.bluePrimary),
                  SizedBox(height: 16),
                  Text('Analizando la imagen…'),
                ],
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _DetectionErrorView(
              onSkip: () => Navigator.of(context).pop(
                FaceRedactionResult(
                  redactedBytes: widget.imageBytes,
                  facesRedacted: 0,
                  facesDetected: 0,
                ),
              ),
            );
          }
          return _PreviewBody(
            data: snapshot.data!,
            imageBytes: widget.imageBytes,
            excludedIndices: _excludedIndices,
            isProcessing: _isProcessing,
            onToggleFace: (index) {
              setState(() {
                if (_excludedIndices.contains(index)) {
                  _excludedIndices.remove(index);
                } else {
                  _excludedIndices.add(index);
                }
              });
            },
            onConfirm: () => _confirm(snapshot.data!),
            onSkip: () => _skipRedaction(snapshot.data!),
          );
        },
      ),
    );
  }
}

class _DetectionData {
  const _DetectionData({
    required this.imageWidth,
    required this.imageHeight,
    required this.faces,
  });

  final double imageWidth;
  final double imageHeight;
  final List<Rect> faces;
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.data,
    required this.imageBytes,
    required this.excludedIndices,
    required this.isProcessing,
    required this.onToggleFace,
    required this.onConfirm,
    required this.onSkip,
  });

  final _DetectionData data;
  final Uint8List imageBytes;
  final Set<int> excludedIndices;
  final bool isProcessing;
  final ValueChanged<int> onToggleFace;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detected = data.faces.length;
    final included = detected - excludedIndices.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBanner(detected: detected, included: included),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = constraints.maxWidth / data.imageWidth;
                      final displayHeight = data.imageHeight * scale;
                      return SizedBox(
                        height: displayHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.memory(imageBytes, fit: BoxFit.cover),
                            ),
                            for (var i = 0; i < data.faces.length; i++)
                              _FaceBox(
                                rect: data.faces[i],
                                scale: scale,
                                index: i,
                                isExcluded: excludedIndices.contains(i),
                                onTap: () => onToggleFace(i),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  detected == 0
                      ? 'No se detectaron caras. Si la imagen contiene personas que no querés mostrar, cancelá y volvé a subir una versión ya editada.'
                      : 'Tocá una caja para excluirla del tachado. Las cajas naranjas se tachan al subir. Las grises quedan visibles.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: AppColors.darkText.withValues(alpha: 0.07),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: detected == 0 ? 'Subir sin tachar' : 'No tachar',
                    expanded: true,
                    onPressed: isProcessing ? null : onSkip,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    label: isProcessing
                        ? 'Procesando…'
                        : included > 0
                            ? 'Tachar $included y subir'
                            : 'Subir foto',
                    icon: isProcessing ? null : Icons.check_rounded,
                    expanded: true,
                    onPressed: isProcessing ? null : onConfirm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FaceBox extends StatelessWidget {
  const _FaceBox({
    required this.rect,
    required this.scale,
    required this.index,
    required this.isExcluded,
    required this.onTap,
  });

  final Rect rect;
  final double scale;
  final int index;
  final bool isExcluded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isExcluded ? AppColors.darkText : AppColors.orangeAction;
    return Positioned(
      left: rect.left * scale,
      top: rect.top * scale,
      width: rect.width * scale,
      height: rect.height * scale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: isExcluded ? 0.10 : 0.30),
            border: Border.all(
              color: color,
              width: 2.5,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isExcluded ? '○ ${index + 1}' : '● ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.detected, required this.included});

  final int detected;
  final int included;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = detected == 0
        ? AppColors.warning
        : included > 0
            ? AppColors.greenSuccess
            : AppColors.bluePrimary;
    final message = detected == 0
        ? 'No detectamos caras automáticamente.'
        : included == detected
            ? 'Se tacharán $detected ${detected == 1 ? 'cara' : 'caras'} antes de publicar.'
            : included == 0
                ? 'Ninguna cara será tachada.'
                : 'Se tacharán $included de $detected caras detectadas.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            detected == 0
                ? Icons.info_outline_rounded
                : included > 0
                    ? Icons.privacy_tip_rounded
                    : Icons.visibility_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectionErrorView extends StatelessWidget {
  const _DetectionErrorView({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos analizar la imagen automáticamente.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subila si confías en que no muestra datos sensibles, o cancelá y editala manualmente antes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.darkText.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Subir sin tachar',
              icon: Icons.upload_rounded,
              onPressed: onSkip,
            ),
          ],
        ),
      ),
    );
  }
}
