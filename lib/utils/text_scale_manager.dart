import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona el escalado de texto personalizado en toda la aplicación
class TextScaleManager extends ChangeNotifier {
  static const String _prefsKey = 'text_scale_factor';
  static const double _minScale = 0.8;
  static const double _maxScale = 1.5;
  static const double _defaultScale = 1.0;

  double _textScaleFactor = _defaultScale;
  SharedPreferences? _prefs;

  double get textScaleFactor => _textScaleFactor;

  /// Opciones predefinidas de escala
  static const Map<String, double> presetScales = {
    'Pequeño': 0.85,
    'Normal': 1.0,
    'Grande': 1.15,
    'Muy grande': 1.3,
  };

  TextScaleManager() {
    _loadScale();
  }

  Future<void> _loadScale() async {
    _prefs = await SharedPreferences.getInstance();
    _textScaleFactor = _prefs?.getDouble(_prefsKey) ?? _defaultScale;
    notifyListeners();
  }

  /// Establece un factor de escala personalizado
  Future<void> setTextScale(double scale) async {
    if (scale < _minScale || scale > _maxScale) {
      throw ArgumentError('El factor de escala debe estar entre $_minScale y $_maxScale');
    }

    _textScaleFactor = scale;
    await _prefs?.setDouble(_prefsKey, scale);
    notifyListeners();
  }

  /// Establece una escala predefinida
  Future<void> setPresetScale(String preset) async {
    final scale = presetScales[preset];
    if (scale == null) {
      throw ArgumentError('Preset no válido: $preset');
    }
    await setTextScale(scale);
  }

  /// Incrementa la escala de texto
  Future<void> increaseScale() async {
    final newScale = (_textScaleFactor + 0.1).clamp(_minScale, _maxScale);
    await setTextScale(newScale);
  }

  /// Decrementa la escala de texto
  Future<void> decreaseScale() async {
    final newScale = (_textScaleFactor - 0.1).clamp(_minScale, _maxScale);
    await setTextScale(newScale);
  }

  /// Restaura la escala por defecto
  Future<void> resetScale() async {
    await setTextScale(_defaultScale);
  }

  /// Obtiene el nombre del preset actual (si coincide)
  String get currentPresetName {
    for (final entry in presetScales.entries) {
      if ((entry.value - _textScaleFactor).abs() < 0.01) {
        return entry.key;
      }
    }
    return 'Personalizado';
  }

  /// Verifica si se puede aumentar más
  bool get canIncrease => _textScaleFactor < _maxScale;

  /// Verifica si se puede disminuir más
  bool get canDecrease => _textScaleFactor > _minScale;
}

/// Widget que aplica el escalado de texto a sus hijos
class TextScaleWrapper extends StatelessWidget {
  const TextScaleWrapper({
    super.key,
    required this.textScaleManager,
    required this.child,
  });

  final TextScaleManager textScaleManager;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: textScaleManager,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaleManager.textScaleFactor),
          ),
          child: child!,
        );
      },
      child: child,
    );
  }
}
