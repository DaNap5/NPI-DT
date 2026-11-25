import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:npi/input/floor_motion.dart';
import 'package:npi/input/floor_motion_calibration.dart';
import 'package:npi/input/calibrate_floor_motion.dart';
import 'package:npi/input/process_floor_motion.dart';

enum FloorMotionCalibrationStep {
  idle,
  resting,
  movingUp,
  movingDown,
  completed,
  failed,
}

enum MotionFeedbackType { success, warning, error }

class FloorMotionInput extends ChangeNotifier {
  FloorMotionInput({
    required this.onUp,
    required this.onDown,
    this._accelerationValues,
    this._gyroValues,
  });
  final VoidCallback onUp;
  final VoidCallback onDown;
  final Stream<double>? _accelerationValues;
  final Stream<double>? _gyroValues;
  final _processFloorMotion = ProcessFloorMotion();
  final _calibrateFloorMotion = CalibrateFloorMotion();
  StreamSubscription<double>? _accelSubscription;
  StreamSubscription<double>? _gyroSubscription;
  bool _active = false;
  bool _unavailable = false;

  void start() {
    if (_disposed || _active || !isSupported) return;
    _active = true;
    _lastAccelerationZ = 0;
    _lastGyroX = 0;
    _recentPeakAccelZ = 0;
    _lastAccelPeakTime = DateTime.fromMillisecondsSinceEpoch(0);
    _startListening();
    _waitUntilResting();
  }

  void stop() {
    _active = false;
    _accelSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
    _cancelCalibrationTimers();
    _rearmTimer?.cancel();
    _rearmTimer = null;
    _restingCheckTimer?.cancel();
    _restingCheckTimer = null;
    _errorClearTimer?.cancel();
    _errorClearTimer = null;
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    _isArmed = false;
    _attemptInProgress = false;
    if (isCalibrating) {
      _calibrationStep = FloorMotionCalibrationStep.failed;
      _calibrationMessage = 'Calibración interrumpida. Inténtalo de nuevo.';
    }
  }

  void _sensorFailed(Object error) {
    if (_disposed) return;
    stop();
    _unavailable = true;
    _showFeedback(
      'Sensores no disponibles. Usa los controles manuales.',
      MotionFeedbackType.warning,
    );
  }

  // ---------------------------------------------------------------------------
  // FEEDBACK
  // ---------------------------------------------------------------------------

  MotionFeedbackType? _feedbackType;
  MotionFeedbackType? get feedbackType => _feedbackType;

  String? _feedbackMessage;
  String? get feedbackMessage => _feedbackMessage;

  int _feedbackId = 0;
  int get feedbackId => _feedbackId;

  Timer? _feedbackTimer;

  void _showFeedback(String message, MotionFeedbackType type) {
    if (_disposed) return;

    _feedbackTimer?.cancel();

    _feedbackMessage = message;
    _feedbackType = type;
    _feedbackId++;

    notifyListeners();

    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (_disposed) return;

      _feedbackMessage = null;
      _feedbackType = null;

      notifyListeners();
    });
  }

  // ---------------------------------------------------------------------------
  // ESTADO GENERAL
  // ---------------------------------------------------------------------------

  FloorMotionError _motionError = FloorMotionError.none;
  FloorMotionError get motionError => _motionError;

  bool get isSupported =>
      !_unavailable &&
      ((_accelerationValues != null && _gyroValues != null) ||
          (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS)));

  bool _isArmed = true;
  bool _attemptInProgress = false;
  bool _isTutorialOpen = false;
  bool _disposed = false;

  double _lastAccelerationZ = 0.0;
  double _recentPeakAccelZ = 0.0;
  DateTime _lastAccelPeakTime = DateTime.fromMillisecondsSinceEpoch(0);
  double _lastGyroX = 0.0;

  Timer? _rearmTimer;
  Timer? _errorClearTimer;
  Timer? _restingCheckTimer;

  static const double _rearmAccelThreshold = 1.0;
  static const double _rearmGyroThreshold = 0.6;

  // Reducido de 250ms a 120ms para respuesta más ágil entre gestos consecutivos
  static const Duration _rearmDuration = Duration(milliseconds: 120);
  // Ampliado de 120ms a 220ms para absorber el desfase natural entre acelerómetro y giroscopio
  static const Duration _sensorSyncWindow = Duration(milliseconds: 220);

  void setTutorialOpen(bool isOpen) {
    if (_disposed || _isTutorialOpen == isOpen) return;

    _isTutorialOpen = isOpen;

    if (isOpen) {
      _rearmTimer?.cancel();
      _rearmTimer = null;
      _isArmed = false;
      _attemptInProgress = false;
    } else if (!isCalibrating) {
      _waitUntilResting();
    }
  }

  // ---------------------------------------------------------------------------
  // CALIBRACIÓN AUTOMÁTICA
  // ---------------------------------------------------------------------------

  static const int _requiredGestureCount = 3;
  static const int _minimumRestSamples = 5;

  // Umbrales para detectar cuándo empieza y termina un gesto automáticamente.
  static const double _gestureTriggerGyro = 0.45;
  static const double _gestureTriggerAccel = 0.45;

  static const double _minimumGyroGesturePeak = 0.5;
  static const double _minimumAccelGesturePeak = 0.5;

  static const Duration _restCalibrationDuration = Duration(seconds: 2);
  static const Duration _gestureEndQuietDuration = Duration(milliseconds: 250);
  static const Duration _gestureMaxDuration = Duration(milliseconds: 1500);

  FloorMotionCalibrationStep _calibrationStep = FloorMotionCalibrationStep.idle;
  FloorMotionCalibrationStep get calibrationStep => _calibrationStep;

  FloorMotionCalibration? _calibration;
  FloorMotionCalibration? get calibration => _calibration;

  bool _isCapturingGesture = false;
  bool get isCapturingGesture => _isCapturingGesture;

  /// Indica si el sistema está listo para detectar el inicio de un nuevo gesto
  /// (evita capturar el movimiento de retorno tras hacer un gesto).
  bool _readyForNextGesture = false;
  bool get readyForNextGesture => _readyForNextGesture;

  double _restProgress = 0.0;
  double get restProgress => _restProgress;

  String? _calibrationMessage;
  String? get calibrationMessage => _calibrationMessage;

  int _upGesturesCompleted = 0;
  int get upGesturesCompleted => _upGesturesCompleted;

  int _downGesturesCompleted = 0;
  int get downGesturesCompleted => _downGesturesCompleted;

  final List<double> _restGyroSamples = [];
  final List<double> _restAccelSamples = [];

  final List<double> _upGyroPeaks = [];
  final List<double> _downGyroPeaks = [];
  final List<double> _accelPeaks = [];

  final List<double> _currentGestureGyroSamples = [];
  final List<double> _currentGestureAccelSamples = [];

  Timer? _restProgressTimer;
  Timer? _gestureQuietTimer;
  Timer? _gestureTimeoutTimer;
  Timer? _gestureRearmTimer;

  double get _attemptStartGyroThreshold =>
      _calibration?.gyroMinThreshold ?? 1.3;

  bool get isCalibrating =>
      _calibrationStep == FloorMotionCalibrationStep.resting ||
      _calibrationStep == FloorMotionCalibrationStep.movingUp ||
      _calibrationStep == FloorMotionCalibrationStep.movingDown ||
      _calibrationStep == FloorMotionCalibrationStep.failed;

  int get calibrationProgress {
    switch (_calibrationStep) {
      case FloorMotionCalibrationStep.resting:
        return 0;

      case FloorMotionCalibrationStep.movingUp:
        return _upGesturesCompleted;

      case FloorMotionCalibrationStep.movingDown:
        return _downGesturesCompleted;

      case FloorMotionCalibrationStep.completed:
        return _requiredGestureCount * 2;

      default:
        return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // INICIO Y FLUJO AUTOMÁTICO DE CALIBRACIÓN
  // ---------------------------------------------------------------------------

  void startCalibration() {
    if (_disposed || !_active || !isSupported) return;

    _cancelCalibrationTimers();
    _rearmTimer?.cancel();
    _restingCheckTimer?.cancel();

    _rearmTimer = null;
    _restingCheckTimer = null;

    _isArmed = false;
    _attemptInProgress = false;

    _resetCalibrationSamples();

    _calibration = null;
    _calibrationMessage = null;
    _calibrationStep = FloorMotionCalibrationStep.resting;

    _isCapturingGesture = false;
    _readyForNextGesture = false;
    _restProgress = 0.0;

    _clearError();
    _startAutomaticRestPhase();
    notifyListeners();
  }

  void _startAutomaticRestPhase() {
    const tick = Duration(milliseconds: 100);
    int elapsedMs = 0;

    _restProgressTimer?.cancel();
    _restProgressTimer = Timer.periodic(tick, (timer) {
      if (_disposed || _calibrationStep != FloorMotionCalibrationStep.resting) {
        timer.cancel();
        return;
      }

      final bool isStill =
          _lastAccelerationZ.abs() < _rearmAccelThreshold &&
          _lastGyroX.abs() < _rearmGyroThreshold;

      if (!isStill) {
        elapsedMs = 0;
        _restProgress = 0.0;
        _restGyroSamples.clear();
        _restAccelSamples.clear();
        _calibrationMessage = 'Mantén el teléfono quieto para medir el reposo.';
        notifyListeners();
        return;
      }

      if (_calibrationMessage != null) {
        _calibrationMessage = null;
      }

      elapsedMs += tick.inMilliseconds;
      _restProgress = (elapsedMs / _restCalibrationDuration.inMilliseconds)
          .clamp(0.0, 1.0);
      notifyListeners();

      if (elapsedMs >= _restCalibrationDuration.inMilliseconds) {
        timer.cancel();
        _completeAutomaticRestPhase();
      }
    });
  }

  void _completeAutomaticRestPhase() {
    if (_disposed || _calibrationStep != FloorMotionCalibrationStep.resting) {
      return;
    }

    if (_restGyroSamples.length < _minimumRestSamples ||
        _restAccelSamples.length < _minimumRestSamples) {
      _failCalibration(
        'No se han recogido suficientes muestras en reposo. Inténtalo de nuevo.',
      );
      return;
    }

    _calibrationStep = FloorMotionCalibrationStep.movingUp;
    _calibrationMessage = null;
    _readyForNextGesture = false;
    _armNextCalibrationGesture();
    notifyListeners();
  }

  /// Espera a que el teléfono esté en reposo antes de habilitar la detección
  /// del siguiente gesto (evita falsos disparos por el movimiento de retorno).
  void _armNextCalibrationGesture() {
    _gestureRearmTimer?.cancel();
    _readyForNextGesture = false;

    _gestureRearmTimer = Timer.periodic(const Duration(milliseconds: 80), (
      timer,
    ) {
      if (_disposed ||
          (_calibrationStep != FloorMotionCalibrationStep.movingUp &&
              _calibrationStep != FloorMotionCalibrationStep.movingDown)) {
        timer.cancel();
        return;
      }

      final bool isResting =
          _lastAccelerationZ.abs() < _rearmAccelThreshold &&
          _lastGyroX.abs() < _rearmGyroThreshold;

      if (isResting) {
        timer.cancel();
        _readyForNextGesture = true;
        notifyListeners();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // CAPTURA AUTOMÁTICA DE GESTOS
  // ---------------------------------------------------------------------------

  void _handleCalibrationSensorTick() {
    if (_calibrationStep != FloorMotionCalibrationStep.movingUp &&
        _calibrationStep != FloorMotionCalibrationStep.movingDown) {
      return;
    }

    final bool isMoving =
        _lastGyroX.abs() >= _gestureTriggerGyro ||
        _lastAccelerationZ.abs() >= _gestureTriggerAccel;

    final bool isResting =
        _lastAccelerationZ.abs() < _rearmAccelThreshold &&
        _lastGyroX.abs() < _rearmGyroThreshold;

    // 1. Inicio automático del gesto.
    if (!_isCapturingGesture) {
      if (_readyForNextGesture && isMoving) {
        _beginAutomaticGestureCapture();
      }
      return;
    }

    // 2. Fin automático cuando vuelve al reposo durante _gestureEndQuietDuration.
    if (isResting) {
      _gestureQuietTimer ??= Timer(_gestureEndQuietDuration, () {
        _endAutomaticGestureCapture();
      });
    } else {
      _gestureQuietTimer?.cancel();
      _gestureQuietTimer = null;
    }
  }

  void _beginAutomaticGestureCapture() {
    if (_disposed || _isCapturingGesture) return;

    _readyForNextGesture = false;
    _isCapturingGesture = true;
    _calibrationMessage = null;

    _currentGestureGyroSamples.clear();
    _currentGestureAccelSamples.clear();

    _currentGestureGyroSamples.add(_lastGyroX);
    _currentGestureAccelSamples.add(_lastAccelerationZ);

    _gestureTimeoutTimer?.cancel();
    _gestureTimeoutTimer = Timer(_gestureMaxDuration, () {
      if (_isCapturingGesture) {
        _endAutomaticGestureCapture();
      }
    });

    notifyListeners();
  }

  void _endAutomaticGestureCapture() {
    if (_disposed || !_isCapturingGesture) return;

    _gestureQuietTimer?.cancel();
    _gestureQuietTimer = null;
    _gestureTimeoutTimer?.cancel();
    _gestureTimeoutTimer = null;

    _isCapturingGesture = false;

    if (_currentGestureGyroSamples.isEmpty ||
        _currentGestureAccelSamples.isEmpty) {
      _armNextCalibrationGesture();
      notifyListeners();
      return;
    }

    final gyroPeak = _signedPeak(_currentGestureGyroSamples);
    final accelPeak = _absolutePeak(_currentGestureAccelSamples);

    // Validar intensidad mínima.
    if (gyroPeak.abs() < _minimumGyroGesturePeak ||
        accelPeak < _minimumAccelGesturePeak) {
      _calibrationMessage =
          'Movimiento demasiado suave. Inclina el teléfono con más firmeza.';
      _armNextCalibrationGesture();
      notifyListeners();
      return;
    }

    final bool isUpGesture =
        _calibrationStep == FloorMotionCalibrationStep.movingUp;

    // Subida: giroscopio positivo.
    // Bajada: giroscopio negativo.
    final bool correctDirection = isUpGesture ? gyroPeak > 0 : gyroPeak < 0;

    if (!correctDirection) {
      _calibrationMessage = isUpGesture
          ? 'Dirección incorrecta: inclina hacia ATRÁS para subir.'
          : 'Dirección incorrecta: inclina hacia DELANTE para bajar.';

      _showFeedback(
        'Dirección incorrecta. Repite el movimiento en el sentido indicado.',
        MotionFeedbackType.warning,
      );
      _armNextCalibrationGesture();
      notifyListeners();
      return;
    }

    // Registrar gesto correcto.
    if (isUpGesture) {
      _upGyroPeaks.add(gyroPeak);
      _upGesturesCompleted++;

      if (_upGesturesCompleted >= _requiredGestureCount) {
        _calibrationStep = FloorMotionCalibrationStep.movingDown;
      }
    } else {
      _downGyroPeaks.add(gyroPeak);
      _downGesturesCompleted++;
    }

    _accelPeaks.add(accelPeak);

    _currentGestureGyroSamples.clear();
    _currentGestureAccelSamples.clear();
    _calibrationMessage = null;

    _showFeedback('¡Bien! Movimiento registrado.', MotionFeedbackType.success);

    if (_downGesturesCompleted >= _requiredGestureCount) {
      _finishCalibration();
      return;
    }

    _armNextCalibrationGesture();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // FINALIZAR CALIBRACIÓN
  // ---------------------------------------------------------------------------

  void _finishCalibration() {
    _cancelCalibrationTimers();

    final result = _calibrateFloorMotion.execute(
      restGyroSamples: _restGyroSamples,
      restAccelSamples: _restAccelSamples,
      upGyroPeaks: _upGyroPeaks,
      downGyroPeaks: _downGyroPeaks,
      accelPeaks: _accelPeaks,
    );

    if (result == null) {
      _failCalibration(
        'No se ha podido calcular una calibración fiable. Repite el proceso.',
      );
      return;
    }

    _calibration = result;
    _calibrationStep = FloorMotionCalibrationStep.completed;
    _calibrationMessage = null;

    _isArmed = false;
    _attemptInProgress = false;

    _showFeedback(
      '¡Calibración completada correctamente!',
      MotionFeedbackType.success,
    );
  }

  void activateMotionDetection() {
    if (_disposed || _calibrationStep != FloorMotionCalibrationStep.completed) {
      return;
    }

    _calibrationStep = FloorMotionCalibrationStep.idle;

    _isArmed = false;
    _attemptInProgress = false;

    _waitUntilResting();

    notifyListeners();
  }

  void _waitUntilResting() {
    _rearmTimer?.cancel();
    _restingCheckTimer?.cancel();

    _rearmTimer = null;
    _restingCheckTimer = null;

    void checkResting() {
      if (_disposed) return;

      final bool isResting =
          _lastAccelerationZ.abs() < _rearmAccelThreshold &&
          _lastGyroX.abs() < _rearmGyroThreshold;

      if (isResting) {
        _rearmTimer ??= Timer(_rearmDuration, () {
          if (_disposed) return;

          _isArmed = true;
          _rearmTimer = null;
        });
      } else {
        _rearmTimer?.cancel();
        _rearmTimer = null;
      }

      if (!_isArmed) {
        _restingCheckTimer = Timer(
          const Duration(milliseconds: 100),
          checkResting,
        );
      }
    }

    checkResting();
  }

  void _resetCalibrationSamples() {
    _restGyroSamples.clear();
    _restAccelSamples.clear();

    _upGyroPeaks.clear();
    _downGyroPeaks.clear();
    _accelPeaks.clear();

    _currentGestureGyroSamples.clear();
    _currentGestureAccelSamples.clear();

    _upGesturesCompleted = 0;
    _downGesturesCompleted = 0;
  }

  void _failCalibration(String message) {
    _cancelCalibrationTimers();
    _isCapturingGesture = false;
    _readyForNextGesture = false;
    _calibration = null;

    _calibrationStep = FloorMotionCalibrationStep.failed;
    _calibrationMessage = message;

    _isArmed = false;
    _attemptInProgress = false;

    _showFeedback(message, MotionFeedbackType.error);
  }

  void _cancelCalibrationTimers() {
    _restProgressTimer?.cancel();
    _restProgressTimer = null;
    _gestureQuietTimer?.cancel();
    _gestureQuietTimer = null;
    _gestureTimeoutTimer?.cancel();
    _gestureTimeoutTimer = null;
    _gestureRearmTimer?.cancel();
    _gestureRearmTimer = null;
  }

  // ---------------------------------------------------------------------------
  // CÁLCULOS DE MUESTRAS
  // ---------------------------------------------------------------------------

  double _absolutePeak(List<double> samples) {
    return samples.map((value) => value.abs()).reduce((a, b) => a > b ? a : b);
  }

  double _signedPeak(List<double> samples) {
    return samples.reduce((a, b) => a.abs() >= b.abs() ? a : b);
  }

  // ---------------------------------------------------------------------------
  // SENSORES
  // ---------------------------------------------------------------------------

  void _startListening() {
    if (!isSupported) return;

    _accelSubscription =
        (_accelerationValues ??
                userAccelerometerEventStream(
                  samplingPeriod: SensorInterval.gameInterval,
                ).map((event) => event.z))
            .listen((double accelerationZ) {
              if (_disposed || !_active || !accelerationZ.isFinite) return;

              _lastAccelerationZ = accelerationZ;

              final now = DateTime.now();
              if (now.difference(_lastAccelPeakTime) > _sensorSyncWindow ||
                  accelerationZ.abs() >= _recentPeakAccelZ.abs()) {
                _recentPeakAccelZ = accelerationZ;
                _lastAccelPeakTime = now;
              }

              if (_calibrationStep == FloorMotionCalibrationStep.resting) {
                _restAccelSamples.add(accelerationZ);
                return;
              }

              if (_calibrationStep == FloorMotionCalibrationStep.movingUp ||
                  _calibrationStep == FloorMotionCalibrationStep.movingDown) {
                if (_isCapturingGesture) {
                  _currentGestureAccelSamples.add(accelerationZ);
                }
                _handleCalibrationSensorTick();
                return;
              }

              _evaluateMovement();
            }, onError: _sensorFailed);

    _gyroSubscription =
        (_gyroValues ??
                gyroscopeEventStream(
                  samplingPeriod: SensorInterval.gameInterval,
                ).map((event) => event.x))
            .listen((double x) {
              if (_disposed || !_active || !x.isFinite) return;

              _lastGyroX = x;

              if (_calibrationStep == FloorMotionCalibrationStep.resting) {
                _restGyroSamples.add(x);
                return;
              }

              if (_calibrationStep == FloorMotionCalibrationStep.movingUp ||
                  _calibrationStep == FloorMotionCalibrationStep.movingDown) {
                if (_isCapturingGesture) {
                  _currentGestureGyroSamples.add(x);
                }
                _handleCalibrationSensorTick();
                return;
              }

              _evaluateMovement();
            }, onError: _sensorFailed);
  }

  // ---------------------------------------------------------------------------
  // DETECCIÓN DE MOVIMIENTO
  // ---------------------------------------------------------------------------

  void _evaluateMovement() {
    if (_disposed || !_active || _isTutorialOpen || isCalibrating) return;

    final now = DateTime.now();

    final double effectiveAccelZ =
        now.difference(_lastAccelPeakTime) <= _sensorSyncWindow
        ? _recentPeakAccelZ
        : _lastAccelerationZ;

    final (motion, detectionError) = _processFloorMotion.execute(
      accelerationZ: effectiveAccelZ,
      gyroX: _lastGyroX,
      calibration: _calibration,
    );

    // Movimiento demasiado brusco.
    if (detectionError == FloorMotionError.excessiveMotion) {
      _rearmTimer?.cancel();
      _rearmTimer = null;

      if (_isArmed) {
        _isArmed = false;
        _attemptInProgress = false;
        _triggerError(FloorMotionError.excessiveMotion);
      }
      return;
    }

    // Sin movimiento válido.
    if (motion == FloorMotion.none) {
      if (_isArmed && _lastGyroX.abs() >= _attemptStartGyroThreshold) {
        _attemptInProgress = true;
      }

      final bool isResting =
          _lastAccelerationZ.abs() < _rearmAccelThreshold &&
          _lastGyroX.abs() < _rearmGyroThreshold;

      if (isResting) {
        if (_isArmed && _attemptInProgress) {
          _attemptInProgress = false;
          _triggerError(FloorMotionError.insufficientMotion);
        }

        _rearmTimer ??= Timer(_rearmDuration, () {
          if (_disposed) return;

          _isArmed = true;
          _rearmTimer = null;
        });
      } else {
        _rearmTimer?.cancel();
        _rearmTimer = null;
      }

      return;
    }

    // Movimiento válido.
    _rearmTimer?.cancel();
    _rearmTimer = null;

    if (!_isArmed) return;

    _isArmed = false;
    _attemptInProgress = false;

    switch (motion) {
      case FloorMotion.up:
        onUp();
        break;

      case FloorMotion.down:
        onDown();
        break;

      case FloorMotion.none:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // PLANTAS Y ERRORES
  // ---------------------------------------------------------------------------

  void _triggerError(FloorMotionError error) {
    _errorClearTimer?.cancel();

    _motionError = error;

    final message = switch (error) {
      FloorMotionError.insufficientMotion =>
        'Movimiento demasiado suave. Inclina el teléfono con más firmeza.',
      FloorMotionError.excessiveMotion =>
        'Movimiento demasiado brusco. Inténtalo de forma más controlada.',
      FloorMotionError.none => '',
    };

    if (message.isNotEmpty) {
      _showFeedback(
        message,
        error == FloorMotionError.insufficientMotion
            ? MotionFeedbackType.warning
            : MotionFeedbackType.error,
      );
    } else {
      notifyListeners();
    }

    _errorClearTimer = Timer(const Duration(seconds: 2), _clearError);
  }

  void _clearError() {
    if (_motionError == FloorMotionError.none) return;

    _motionError = FloorMotionError.none;

    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    stop();
    _disposed = true;
    super.dispose();
  }
}
