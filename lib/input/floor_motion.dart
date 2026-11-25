enum FloorMotion { up, down, none }

enum FloorMotionError {
  none,
  insufficientMotion, // Hizo el gesto pero sin fuerza/ángulo suficiente
  excessiveMotion, // Movimiento demasiado brusco / sacudida fuerte
}
