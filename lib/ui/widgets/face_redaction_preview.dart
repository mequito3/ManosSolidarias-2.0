import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/face_redaction_service.dart';
import '../../theme/app_colors.dart';
import 'app_buttons.dart';

/// Resultado de la pantalla de redacción.
class FaceRedactionResult {
  const FaceRedactionResult({
    required this.redactedBytes,
    required this.regionsRedacted,
    required this.regionsDetected,
  });

  final Uint8List redactedBytes;
  final int regionsRedacted;
  final int regionsDetected;
}

/// Pantalla intermedia que muestra una foto con caras + bloques de texto
/// detectados. PII de alta confianza (nombre, cédula) y caras vienen
/// pre-marcados para tachar. Texto genérico arranca en gris (opt-in).
class FaceRedactionPreview extends StatefulWidget {
  const FaceRedactionPreview({
    super.key,
    required this.imageBytes,
    required this.imagePath,
    required this.service,
    this.sensitiveNames = const [],
  });

  final Uint8List imageBytes;
  final String imagePath;
  final FaceRedactionService service;

  /// Strings que tratamos como PII al detectarse en bloques de texto.
  /// Típicamente el nombre del usuario + el nombre del beneficiario.
  final List<String> sensitiveNames;

  static Future<FaceRedactionResult?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    required String imagePath,
    required FaceRedactionService service,
    List<String> sensitiveNames = const [],
  }) {
    return Navigator.of(context).push<FaceRedactionResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FaceRedactionPreview(
          imageBytes: imageBytes,
          imagePath: imagePath,
          service: service,
          sensitiveNames: sensitiveNames,
        ),
      ),
    );
  }

  @override
  State<FaceRedactionPreview> createState() => _FaceRedactionPreviewState();
}

enum _ItemKind { face, highConfText, lowConfText }

class _RedactionItem {
  _RedactionItem({
    required this.rect,
    required this.kind,
    required this.isIncluded,
    this.text,
    this.reason,
  });

  final Rect rect;
  final _ItemKind kind;
  final String? text;
  final String? reason;
  bool isIncluded;
}

class _DetectionData {
  const _DetectionData({
    required this.imageWidth,
    required this.imageHeight,
    required this.items,
  });

  final double imageWidth;
  final double imageHeight;
  final List<_RedactionItem> items;
}

class _FaceRedactionPreviewState extends State<FaceRedactionPreview> {
  late Future<_DetectionData> _detectionFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _detectionFuture = _runDetection();
  }

  Future<_DetectionData> _runDetection() async {
    final image = await decodeImageFromList(widget.imageBytes);
    final facesFuture = widget.service.detectFaces(widget.imagePath);
    final textFuture = widget.service.detectTextBlocks(
      widget.imagePath,
      sensitiveNames: widget.sensitiveNames,
    );
    final faces = await facesFuture;
    final textBlocks = await textFuture;

    final items = <_RedactionItem>[];
    for (final face in faces) {
      items.add(_RedactionItem(
        rect: face,
        kind: _ItemKind.face,
        isIncluded: true,
      ));
    }
    for (final block in textBlocks) {
      final isHighConf =
          block.confidence == TextRedactionConfidence.highConfidencePii;
      items.add(_RedactionItem(
        rect: block.rect,
        kind: isHighConf ? _ItemKind.highConfText : _ItemKind.lowConfText,
        text: block.text,
        reason: block.matchedReason,
        isIncluded: isHighConf,
      ));
    }
    return _DetectionData(
      imageWidth: image.width.toDouble(),
      imageHeight: image.height.toDouble(),
      items: items,
    );
  }

  Future<void> _confirm(_DetectionData data) async {
    setState(() => _isProcessing = true);
    final included = data.items
        .where((item) => item.isIncluded)
        .map((item) => item.rect)
        .toList(growable: false);
    final redacted = widget.service.redactRegions(
      originalBytes: widget.imageBytes,
      boxes: included,
    );
    if (!mounted) return;
    Navigator.of(context).pop(
      FaceRedactionResult(
        redactedBytes: redacted,
        regionsRedacted: included.length,
        regionsDetected: data.items.length,
      ),
    );
  }

  void _skipRedaction(_DetectionData data) {
    Navigator.of(context).pop(
      FaceRedactionResult(
        redactedBytes: widget.imageBytes,
        regionsRedacted: 0,
        regionsDetected: data.items.length,
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
                  regionsRedacted: 0,
                  regionsDetected: 0,
                ),
              ),
            );
          }
          return _PreviewBody(
            data: snapshot.data!,
            imageBytes: widget.imageBytes,
            isProcessing: _isProcessing,
            onToggleItem: (index) {
              setState(() {
                final item = snapshot.data!.items[index];
                item.isIncluded = !item.isIncluded;
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

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.data,
    required this.imageBytes,
    required this.isProcessing,
    required this.onToggleItem,
    required this.onConfirm,
    required this.onSkip,
  });

  final _DetectionData data;
  final Uint8List imageBytes;
  final bool isProcessing;
  final ValueChanged<int> onToggleItem;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final included = data.items.where((it) => it.isIncluded).length;
    final faceCount = data.items.where((it) => it.kind == _ItemKind.face).length;
    final highConfTextCount = data.items
        .where((it) => it.kind == _ItemKind.highConfText)
        .length;
    final lowConfTextCount = data.items
        .where((it) => it.kind == _ItemKind.lowConfText)
        .length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBanner(
                  detected: data.items.length,
                  included: included,
                ),
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
                            for (var i = 0; i < data.items.length; i++)
                              _RedactionBox(
                                item: data.items[i],
                                scale: scale,
                                index: i,
                                onTap: () => onToggleItem(i),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _LegendCard(
                  faceCount: faceCount,
                  highConfTextCount: highConfTextCount,
                  lowConfTextCount: lowConfTextCount,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tocá una caja para incluirla o excluirla del tachado. '
                  'Las cajas con borde sólido se tachan al subir; '
                  'las grises punteadas quedan visibles.',
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
                    label: 'No tachar',
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

class _RedactionBox extends StatelessWidget {
  const _RedactionBox({
    required this.item,
    required this.scale,
    required this.index,
    required this.onTap,
  });

  final _RedactionItem item;
  final double scale;
  final int index;
  final VoidCallback onTap;

  Color get _baseColor {
    switch (item.kind) {
      case _ItemKind.face:
        return AppColors.orangeAction;
      case _ItemKind.highConfText:
        return AppColors.error;
      case _ItemKind.lowConfText:
        return AppColors.darkText;
    }
  }

  String get _label {
    switch (item.kind) {
      case _ItemKind.face:
        return 'Cara';
      case _ItemKind.highConfText:
        return 'PII';
      case _ItemKind.lowConfText:
        return 'Texto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final included = item.isIncluded;
    final color = _baseColor;
    return Positioned(
      left: item.rect.left * scale,
      top: item.rect.top * scale,
      width: item.rect.width * scale,
      height: item.rect.height * scale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: included ? 0.30 : 0.05),
            border: Border.all(
              color: color.withValues(alpha: included ? 1.0 : 0.40),
              width: included ? 2.5 : 1.5,
              style: included ? BorderStyle.solid : BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: included ? color : color.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              included ? '● $_label' : '○ $_label',
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
        ? 'No detectamos caras ni texto sensible.'
        : included == 0
            ? 'Ninguna región será tachada antes de publicar.'
            : 'Se tacharán $included ${included == 1 ? 'región' : 'regiones'} antes de publicar.';

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

class _LegendCard extends StatelessWidget {
  const _LegendCard({
    required this.faceCount,
    required this.highConfTextCount,
    required this.lowConfTextCount,
  });

  final int faceCount;
  final int highConfTextCount;
  final int lowConfTextCount;

  @override
  Widget build(BuildContext context) {
    final entries = <Widget>[
      if (faceCount > 0)
        _LegendDot(
          color: AppColors.orangeAction,
          label: '$faceCount ${faceCount == 1 ? 'cara' : 'caras'}',
          hint: 'Tachado por defecto',
        ),
      if (highConfTextCount > 0)
        _LegendDot(
          color: AppColors.error,
          label: '$highConfTextCount PII',
          hint: 'Nombres o documentos',
        ),
      if (lowConfTextCount > 0)
        _LegendDot(
          color: AppColors.darkText.withValues(alpha: 0.6),
          label: '$lowConfTextCount texto',
          hint: 'Tocá para tachar',
        ),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.hint,
  });

  final Color color;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· $hint',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.darkText.withValues(alpha: 0.55),
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
