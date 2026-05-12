import 'package:flutter/material.dart';

/// Widget que resalta un elemento con una animación de borde brillante
/// Similar al estilo de Facebook cuando navegas desde una notificación
class HighlightWrapper extends StatefulWidget {
  const HighlightWrapper({
    super.key,
    required this.child,
    required this.shouldHighlight,
    this.highlightColor = const Color(0xFF2196F3),
    this.animationDuration = const Duration(milliseconds: 2000),
    this.pulseCount = 3,
  });

  /// Widget hijo que será resaltado
  final Widget child;

  /// Si debe mostrar el highlight o no
  final bool shouldHighlight;

  /// Color del borde de highlight
  final Color highlightColor;

  /// Duración total de la animación
  final Duration animationDuration;

  /// Número de pulsos del highlight
  final int pulseCount;

  @override
  State<HighlightWrapper> createState() => _HighlightWrapperState();
}

class _HighlightWrapperState extends State<HighlightWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Animación que pulsa de 0 a 1 múltiples veces
    _animation = TweenSequence<double>([
      for (int i = 0; i < widget.pulseCount; i++) ...[
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ],
    ]).animate(_controller);

    // Iniciar animación si debe resaltar
    if (widget.shouldHighlight) {
      // Pequeño delay para que el usuario vea la transición
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(HighlightWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambia el estado de highlight, reiniciar animación
    if (widget.shouldHighlight && !oldWidget.shouldHighlight) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shouldHighlight) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        final scale = 1.0 + (_animation.value * 0.02); // Sutil efecto de escala

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (opacity > 0) ...[
                  // Sombra interna (borde brillante)
                  BoxShadow(
                    color: widget.highlightColor.withValues(alpha: opacity * 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                  // Sombra externa más suave
                  BoxShadow(
                    color: widget.highlightColor.withValues(alpha: opacity * 0.2),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.highlightColor.withValues(alpha: opacity),
                  width: 2 + (opacity * 1), // Borde que crece
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Key global para poder hacer scroll a elementos específicos
class HighlightableKey extends GlobalKey {
  HighlightableKey(String id) : super.constructor();
}
