import 'package:flutter/material.dart';

class SwipeableCardWrapper extends StatelessWidget {
  const SwipeableCardWrapper({
    super.key,
    required this.child,
    required this.dragOffset,
    this.rotation =
        0.0, // Recibimos la rotación (0.0 por defecto si usamos el dedo)
    required this.isAnimating,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final Widget child;
  final double dragOffset;
  final double rotation;
  final bool isAnimating;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: AnimatedContainer(
        duration: isAnimating
            ? const Duration(milliseconds: 200)
            : Duration.zero,
        curve: Curves.easeOut,
        // Translada en X y luego rota en Z desde el centro
        transform: Matrix4.identity()
          ..translateByDouble(dragOffset, 0.0, 0.0, 1.0)
          ..rotateZ(rotation),
        transformAlignment: Alignment.center,
        child: RepaintBoundary(child: child),
      ),
    );
  }
}
