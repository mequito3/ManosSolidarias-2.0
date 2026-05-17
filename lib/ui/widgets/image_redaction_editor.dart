import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';

import '../../theme/app_colors.dart';
import 'app_buttons.dart';

/// Resultado de la edición: bytes finales con las anotaciones quemadas.
class ImageRedactionResult {
  const ImageRedactionResult({
    required this.bytes,
    required this.hasEdits,
  });

  final Uint8List bytes;
  final bool hasEdits;
}

/// Pantalla fullscreen donde el usuario tacha manualmente las regiones
/// sensibles de una foto pintando líneas negras sobre ellas.
/// Solo soporta pincel libre negro — sin formas geométricas, sin colores.
class ImageRedactionEditor extends StatefulWidget {
  const ImageRedactionEditor({
    super.key,
    required this.imageBytes,
  });

  final Uint8List imageBytes;

  /// Helper de navegación: empuja la pantalla y devuelve el resultado.
  /// Retorna `null` si el usuario canceló.
  static Future<ImageRedactionResult?> show(
    BuildContext context, {
    required Uint8List imageBytes,
  }) {
    return Navigator.of(context).push<ImageRedactionResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageRedactionEditor(imageBytes: imageBytes),
      ),
    );
  }

  @override
  State<ImageRedactionEditor> createState() => _ImageRedactionEditorState();
}

class _ImageRedactionEditorState extends State<ImageRedactionEditor> {
  late final ImagePainterController _controller;
  double _strokeWidth = 24;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController(
      color: Colors.black,
      strokeWidth: _strokeWidth,
      mode: PaintMode.freeStyle,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateStroke(double value) {
    setState(() => _strokeWidth = value);
    _controller.setStrokeWidth(value);
  }

  Future<void> _confirm() async {
    setState(() => _isExporting = true);
    try {
      final exported = await _controller.exportImage();
      if (!mounted) return;
      if (exported == null) {
        Navigator.of(context).pop(
          ImageRedactionResult(bytes: widget.imageBytes, hasEdits: false),
        );
        return;
      }
      Navigator.of(context).pop(
        ImageRedactionResult(bytes: exported, hasEdits: true),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isExporting = false);
    }
  }

  void _skipEditing() {
    Navigator.of(context).pop(
      ImageRedactionResult(bytes: widget.imageBytes, hasEdits: false),
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
          'Tachar zonas sensibles',
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
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              color: AppColors.bluePrimary.withValues(alpha: 0.06),
              child: const Text(
                'Pinta sobre caras, nombres o documentos que no quieras mostrar.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.darkText,
                  height: 1.4,
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.black,
                child: ImagePainter.memory(
                  widget.imageBytes,
                  controller: _controller,
                  scalable: true,
                  showControls: false,
                ),
              ),
            ),
            // Barra de herramientas minimal: grosor + undo + borrar todo
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.brush_rounded,
                      size: 18, color: AppColors.darkText),
                  Expanded(
                    child: Slider(
                      value: _strokeWidth,
                      min: 8,
                      max: 60,
                      activeColor: AppColors.bluePrimary,
                      inactiveColor: AppColors.dividerColor,
                      onChanged: _isExporting ? null : _updateStroke,
                    ),
                  ),
                  _ToolButton(
                    icon: Icons.undo_rounded,
                    tooltip: 'Deshacer',
                    onTap: _isExporting ? null : _controller.undo,
                  ),
                  const SizedBox(width: 6),
                  _ToolButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Borrar todo',
                    onTap: _isExporting ? null : _controller.clear,
                  ),
                ],
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'No tachar',
                      expanded: true,
                      onPressed: _isExporting ? null : _skipEditing,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      label: _isExporting ? 'Aplicando…' : 'Aplicar y subir',
                      icon: _isExporting ? null : Icons.check_rounded,
                      expanded: true,
                      onPressed: _isExporting ? null : _confirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: onTap == null
                  ? AppColors.darkText.withValues(alpha: 0.30)
                  : AppColors.darkText,
            ),
          ),
        ),
      ),
    );
  }
}
