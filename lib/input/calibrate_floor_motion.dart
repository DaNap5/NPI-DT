import 'dart:math' as math;

import 'package:npi/input/floor_motion_calibration.dart';

class CalibrateFloorMotion {
  // Cantidad mínima de muestras para considerar válida la calibración.
  static const int _minimumRestSamples = 5;
  static const int _minimumGestureSamples = 3;

  // Factores para calcular los umbrales a partir del ruido y los gestos.
  static const double _noiseMultiplier = 1.5;
  static const double _gestureMultiplier = 0.35;
  static const double _maximumThresholdRatio = 0.7;

  /// Calcula los umbrales personalizados para detectar los movimientos
  /// de subida y bajada de planta.
  ///
  /// Devuelve null si las muestras son insuficientes o no permiten
  /// distinguir adecuadamente los gestos del ruido en reposo.
  FloorMotionCalibration? execute({
    required List<double> restGyroSamples,
    required List<double> restAccelSamples,
    required List<double> upGyroPeaks,
    required List<double> downGyroPeaks,
    required List<double> accelPeaks,
  }) {
    if (!_hasEnoughSamples(restGyroSamples, _minimumRestSamples)) {
      return null;
    }

    if (!_hasEnoughSamples(restAccelSamples, _minimumRestSamples)) {
      return null;
    }

    if (!_hasEnoughSamples(upGyroPeaks, _minimumGestureSamples)) {
      return null;
    }

    if (!_hasEnoughSamples(downGyroPeaks, _minimumGestureSamples)) {
      return null;
    }

    if (!_hasEnoughSamples(accelPeaks, _minimumGestureSamples)) {
      return null;
    }

    // Calculamos el ruido en reposo utilizando el percentil 95
    // de los valores absolutos.
    final gyroNoise = _percentile95(restGyroSamples);
    final accelNoise = _percentile95(restAccelSamples);

    // Calculamos la intensidad habitual de los gestos.
    // Utilizamos la mediana para reducir la influencia de valores atípicos.
    final upGyroIntensity = _median(upGyroPeaks);
    final downGyroIntensity = _median(downGyroPeaks);
    final accelIntensity = _median(accelPeaks);

    // Para el giroscopio utilizamos la dirección más débil.
    // Así el umbral permitirá detectar tanto subidas como bajadas.
    final gyroGestureIntensity = math.min(upGyroIntensity, downGyroIntensity);

    final gyroThreshold = _calculateThreshold(
      noise: gyroNoise,
      gestureIntensity: gyroGestureIntensity,
    );

    final accelThreshold = _calculateThreshold(
      noise: accelNoise,
      gestureIntensity: accelIntensity,
    );

    if (gyroThreshold == null || accelThreshold == null) {
      return null;
    }

    return FloorMotionCalibration(
      gyroMinThreshold: gyroThreshold,
      accelMinThreshold: accelThreshold,
    );
  }

  bool _hasEnoughSamples(List<double> samples, int minimum) {
    return samples.length >= minimum &&
        samples.every((sample) => sample.isFinite);
  }

  /// Calcula el umbral entre el ruido en reposo y la intensidad del gesto.
  double? _calculateThreshold({
    required double noise,
    required double gestureIntensity,
  }) {
    if (!noise.isFinite ||
        !gestureIntensity.isFinite ||
        gestureIntensity <= 0) {
      return null;
    }

    final threshold = math.max(
      noise * _noiseMultiplier,
      gestureIntensity * _gestureMultiplier,
    );

    // Si el umbral queda demasiado cerca de la intensidad del gesto,
    // no existe suficiente separación para una detección fiable.
    if (threshold >= gestureIntensity * _maximumThresholdRatio) {
      return null;
    }

    return threshold;
  }

  double _median(List<double> values) {
    final sorted = values.map((value) => value.abs()).toList()..sort();

    final middle = sorted.length ~/ 2;

    if (sorted.length.isOdd) {
      return sorted[middle];
    }

    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  double _percentile95(List<double> values) {
    final sorted = values.map((value) => value.abs()).toList()..sort();

    final index = ((sorted.length - 1) * 0.95).ceil();

    return sorted[index];
  }
}
