import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Detección y redacción de caras on-device usando ML Kit.
///
/// El detector se inicializa una sola vez por instancia. Llamá [close]
/// cuando termines (típicamente al pop del page).
class FaceRedactionService {
  FaceRedactionService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate,
            enableContours: false,
            enableClassification: false,
            enableLandmarks: false,
            minFaceSize: 0.05,
          ),
        );

  final FaceDetector _detector;

  /// Detecta caras en el archivo en [imagePath]. Devuelve los rectángulos
  /// en coordenadas de pixel de la imagen original (no de la pantalla).
  Future<List<Rect>> detectFaces(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final faces = await _detector.processImage(input);
    return faces.map((face) {
      final r = face.boundingBox;
      return Rect.fromLTWH(r.left, r.top, r.width, r.height);
    }).toList(growable: false);
  }

  /// Aplica rectángulos negros sólidos sobre [boxes] en la imagen
  /// [originalBytes]. Devuelve un nuevo JPEG.
  ///
  /// Los rectángulos se expanden 12% para cubrir orejas, mentón y
  /// pelo que ML Kit suele dejar fuera del boundingBox.
  Uint8List redactRegions({
    required Uint8List originalBytes,
    required List<Rect> boxes,
  }) {
    if (boxes.isEmpty) {
      return originalBytes;
    }
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      return originalBytes;
    }
    final expanded = _expandBoxes(boxes, 0.12);
    for (final box in expanded) {
      final left = box.left.clamp(0, decoded.width - 1).toInt();
      final top = box.top.clamp(0, decoded.height - 1).toInt();
      final right = box.right.clamp(0, decoded.width).toInt();
      final bottom = box.bottom.clamp(0, decoded.height).toInt();
      img.fillRect(
        decoded,
        x1: left,
        y1: top,
        x2: right,
        y2: bottom,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
  }

  List<Rect> _expandBoxes(List<Rect> boxes, double factor) {
    return boxes.map((b) {
      final dx = b.width * factor;
      final dy = b.height * factor;
      return Rect.fromLTRB(
        b.left - dx,
        b.top - dy,
        b.right + dx,
        b.bottom + dy,
      );
    }).toList(growable: false);
  }

  Future<void> close() => _detector.close();
}
