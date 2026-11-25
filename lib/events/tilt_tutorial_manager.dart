import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:npi/events/swipe_state.dart';

enum TiltTutorialStep {
  panSave, // Deslizar para guardar
  panDiscard, // Deslizar para descartar
  tiltSave, // Inclinar para guardar
  tiltDiscard, // Inclinar para descartar
  completed,
}

class TiltTutorialManager extends ChangeNotifier {
  bool _isActive = false;
  TiltTutorialStep _currentStep = TiltTutorialStep.panSave;
  Timer? _completionTimer;

  bool get isActive => _isActive;
  TiltTutorialStep get currentStep => _currentStep;

  bool get isPanPhase =>
      _isActive &&
      (_currentStep == TiltTutorialStep.panSave ||
          _currentStep == TiltTutorialStep.panDiscard);

  bool get isTiltPhase =>
      _isActive &&
      (_currentStep == TiltTutorialStep.tiltSave ||
          _currentStep == TiltTutorialStep.tiltDiscard);

  void start() {
    _completionTimer?.cancel();
    _isActive = true;
    _currentStep = TiltTutorialStep.panSave;
    notifyListeners();
  }

  void skip() {
    _completionTimer?.cancel();
    _isActive = false;
    _currentStep = TiltTutorialStep.completed;
    notifyListeners();
  }

  /// Retorna TRUE si el gesto realizado coincide con el paso actual del tutorial
  bool handleGesture(SwipeDecision decision, {required bool isFromPan}) {
    if (!_isActive) return false;

    // 1. Fase Pan (Deslizar con el dedo)
    if (_currentStep == TiltTutorialStep.panSave &&
        isFromPan &&
        decision == SwipeDecision.save) {
      _currentStep = TiltTutorialStep.panDiscard;
      notifyListeners();
      return true;
    }

    if (_currentStep == TiltTutorialStep.panDiscard &&
        isFromPan &&
        decision == SwipeDecision.discard) {
      _currentStep = TiltTutorialStep.tiltSave;
      notifyListeners();
      return true;
    }

    // 2. Fase Tilt (Inclinar el móvil)
    if (_currentStep == TiltTutorialStep.tiltSave &&
        !isFromPan &&
        decision == SwipeDecision.save) {
      _currentStep = TiltTutorialStep.tiltDiscard;
      notifyListeners();
      return true;
    }

    if (_currentStep == TiltTutorialStep.tiltDiscard &&
        !isFromPan &&
        decision == SwipeDecision.discard) {
      _currentStep = TiltTutorialStep.completed;
      notifyListeners();

      _completionTimer?.cancel();
      _completionTimer = Timer(const Duration(milliseconds: 900), () {
        _isActive = false;
        notifyListeners();
      });
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    super.dispose();
  }
}
