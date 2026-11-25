import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'tilt_gesture.dart';

class EventTiltInput {
  EventTiltInput({
    required this.onSave,
    required this.onDiscard,
    required this.onProgress,
    required this.onCancel,
    this.onUnavailable,
  });
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final ValueChanged<double> onProgress;
  final VoidCallback onCancel;
  final VoidCallback? onUnavailable;
  final _gesture = TiltGesture();
  final _clock = Stopwatch();
  StreamSubscription<AccelerometerEvent>? _accel;
  StreamSubscription<GyroscopeEvent>? _gyro;
  double _gz = 0;
  int _lastMicros = 0;
  double _angle = 0;
  double _cooldown = 0;
  TiltAction _locked = TiltAction.none;
  bool suspended = false;
  bool enabled = true;
  bool _active = false;
  bool _disposed = false;
  bool _unavailable = false;
  bool get isSupported =>
      !_unavailable &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static const _threshold = math.pi / 6;

  void start() {
    if (_active || _disposed || !isSupported) return;
    _active = true;
    reset();
    _clock.start();
    _lastMicros = _clock.elapsedMicroseconds;
    _gyro = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 16),
    ).listen((event) => _gz = event.z, onError: _failed);
    _accel =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 16),
        ).listen((event) {
          final micros = _clock.elapsedMicroseconds;
          final dt = (micros - _lastMicros) / 1000000;
          _lastMicros = micros;
          if (_active) {
            addSample(ax: event.x, ay: event.y, az: event.z, gz: _gz, dt: dt);
          }
        }, onError: _failed);
  }

  void _failed(Object error) {
    stop();
    _unavailable = true;
    onUnavailable?.call();
  }

  void reset() {
    _gesture.reset();
    _angle = 0;
    _cooldown = 0;
    _locked = TiltAction.none;
    _gz = 0;
  }

  /// A deterministic sample entry point also used by the sensor stream.
  void addSample({
    required double ax,
    required double ay,
    required double az,
    required double gz,
    required double dt,
  }) {
    if (!_active ||
        _disposed ||
        !enabled ||
        dt <= 0 ||
        dt > 0.5 ||
        ![ax, ay, az, gz, dt].every((value) => value.isFinite)) {
      return;
    }
    final deviation = (math.sqrt(ax * ax + ay * ay + az * az) - 9.8).abs();
    final gyro = gz.abs();
    if (deviation >= 3 || gyro >= 7) {
      if (!suspended) {
        _cooldown = 0.45;
        _angle = 0;
        _locked = TiltAction.none;
        _gesture.reset();
        onCancel();
        return;
      }
    } else if ((deviation > 1.5 || gyro > 4.5) && !suspended) {
      final gyroFactor = gyro > 4.5 ? (gyro - 4.5) / (7 - 4.5) : 0.0;
      final accelFactor = deviation > 1.5 ? (deviation - 1.5) / (3 - 1.5) : 0.0;
      final calculated =
          math.max(gyroFactor, accelFactor).clamp(0.0, 1.0) * 0.15;
      if (calculated > _cooldown) _cooldown = calculated;
    }
    if (_cooldown > 0) {
      _cooldown -= dt;
    } else {
      final penalty = deviation > 1.2
          ? 1 - ((deviation - 1.2) / 1.8).clamp(0.0, 1.0) * 0.8
          : 1.0;
      final rate = gz * penalty;
      if (rate.abs() > 0.3) {
        _angle += rate * dt;
        _angle *= 0.99;
      } else {
        _angle *= 0.95;
        if (_angle.abs() < 0.01) _angle = 0;
      }
    }
    _angle = _angle.clamp(-_threshold * 1.2, _threshold * 1.2);
    var normalized = (_angle / _threshold).clamp(-1.0, 1.0);
    if (_locked == TiltAction.save) {
      if (normalized < 0.35) {
        _locked = TiltAction.none;
      } else if (normalized > 0) {
        normalized = 0;
      }
    } else if (_locked == TiltAction.discard) {
      if (normalized > -0.35) {
        _locked = TiltAction.none;
      } else if (normalized < 0) {
        normalized = 0;
      }
    }
    if (suspended) return;
    _gesture.update(normalized, dt);
    onProgress(_gesture.progress);
    final action = _gesture.action;
    if (action != TiltAction.none) {
      _locked = action;
      _gesture.reset();
      if (action == TiltAction.save) {
        onSave();
      } else {
        onDiscard();
      }
    }
  }

  void stop() {
    _active = false;
    _accel?.cancel();
    _accel = null;
    _gyro?.cancel();
    _gyro = null;
    _clock.stop();
    reset();
  }

  void dispose() {
    stop();
    _disposed = true;
  }
}
