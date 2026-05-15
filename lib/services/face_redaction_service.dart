import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Severidad con la que sugerimos tachar un bloque de texto detectado.
///
/// `highConfidencePii` ⇒ default ON (lo tachamos antes de mostrar la preview).
/// `genericText` ⇒ default OFF (el usuario decide si lo agrega al tachado).
enum TextRedactionConfidence { highConfidencePii, genericText }

/// Bloque de texto detectado por OCR con su clasificación de riesgo.
class TextRedactionBlock {
  TextRedactionBlock({
    required this.text,
    required this.rect,
    required this.confidence,
    this.matchedReason,
  });

  /// Texto reconocido.
  final String text;

  /// Bounding box en coordenadas de pixel de la imagen original.
  final Rect rect;

  /// Confianza de que es PII sensible.
  final TextRedactionConfidence confidence;

  /// Por qué se flagó (ej. "Coincide con nombre del usuario").
  final String? matchedReason;
}

/// Detección y redacción de caras + texto PII on-device usando ML Kit.
///
/// El detector y el OCR se inicializan una sola vez por instancia.
/// Llamá [close] cuando termines (típicamente al dispose del page).
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
        ),
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final FaceDetector _detector;
  final TextRecognizer _textRecognizer;

  // Patrón cédula boliviana: 6 a 10 dígitos consecutivos, opcional
  // extensión alfanumérica (ej. "1234567 LP"). Se aplica sobre cada
  // bloque, no la imagen entera.
  static final RegExp _cedulaPattern = RegExp(r'\b\d{6,10}\b');

  /// Detecta caras en el archivo en [imagePath]. Devuelve los rectángulos
  /// en coordenadas de pixel de la imagen original.
  Future<List<Rect>> detectFaces(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final faces = await _detector.processImage(input);
    return faces.map((face) {
      final r = face.boundingBox;
      return Rect.fromLTWH(r.left, r.top, r.width, r.height);
    }).toList(growable: false);
  }

  /// Detecta texto on-device y devuelve bloques clasificados por
  /// confianza de PII. Los strings de [sensitiveNames] se buscan como
  /// substring case-insensitive en cada bloque.
  Future<List<TextRedactionBlock>> detectTextBlocks(
    String imagePath, {
    required List<String> sensitiveNames,
  }) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _textRecognizer.processImage(input);
    final normalizedNames = sensitiveNames
        .map((n) => n.trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toList(growable: false);

    final blocks = <TextRedactionBlock>[];
    for (final block in result.blocks) {
      final text = block.text.trim();
      if (text.isEmpty) continue;
      final r = block.boundingBox;
      final rect = Rect.fromLTWH(
        r.left.toDouble(),
        r.top.toDouble(),
        r.width.toDouble(),
        r.height.toDouble(),
      );

      String? matchedName;
      final lower = text.toLowerCase();
      for (final name in normalizedNames) {
        if (lower.contains(name)) {
          matchedName = name;
          break;
        }
      }
      final hasCedula = _cedulaPattern.hasMatch(text);

      if (matchedName != null || hasCedula) {
        final reason = matchedName != null
            ? 'Coincide con un nombre del perfil'
            : 'Parece un número de documento';
        blocks.add(TextRedactionBlock(
          text: text,
          rect: rect,
          confidence: TextRedactionConfidence.highConfidencePii,
          matchedReason: reason,
        ));
      } else {
        blocks.add(TextRedactionBlock(
          text: text,
          rect: rect,
          confidence: TextRedactionConfidence.genericText,
        ));
      }
    }
    return blocks;
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

  Future<void> close() async {
    await _detector.close();
    await _textRecognizer.close();
  }
}
