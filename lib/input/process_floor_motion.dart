import 'package:npi/input/floor_motion.dart';
import 'package:npi/input/floor_motion_calibration.dart';

class ProcessFloorMotion {
  // Límites máximos de seguridad: no se modifican con la calibración.
  static const double _gyroMaxThreshold = 8.5;
  static const double _accelMaxThreshold = 14.0;

  (FloorMotion, FloorMotionError) execute({
    required double accelerationZ,
    required double gyroX,
    FloorMotionCalibration? calibration,
  }) {
    final thresholds = calibration ?? FloorMotionCalibration.defaultCalibration;

    // Comprobamos primero los límites máximos de seguridad.
    if (accelerationZ.abs() > _accelMaxThreshold ||
        gyroX.abs() > _gyroMaxThreshold) {
      return (FloorMotion.none, FloorMotionError.excessiveMotion);
    }

    // Comprobamos si el movimiento tiene suficiente intensidad.
    if (accelerationZ.abs() < thresholds.accelMinThreshold) {
      return (FloorMotion.none, FloorMotionError.none);
    }

    // Determinamos la dirección del movimiento.
    if (gyroX < -thresholds.gyroMinThreshold) {
      return (FloorMotion.down, FloorMotionError.none);
    }

    if (gyroX > thresholds.gyroMinThreshold) {
      return (FloorMotion.up, FloorMotionError.none);
    }

    return (FloorMotion.none, FloorMotionError.none);
  }
}
