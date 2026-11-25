class FloorMotionCalibration {
  const FloorMotionCalibration({
    required this.gyroMinThreshold,
    required this.accelMinThreshold,
  });

  /// Umbral mínimo del giroscopio para detectar un gesto.
  final double gyroMinThreshold;

  /// Umbral mínimo del acelerómetro para detectar un gesto.
  final double accelMinThreshold;

  /// Valores utilizados cuando todavía no existe una calibración.
  static const defaultCalibration = FloorMotionCalibration(
    gyroMinThreshold: 2.8,
    accelMinThreshold: 1.8,
  );
}
