import 'dart:async';

import 'package:flutter/foundation.dart';

enum MapFeedbackType { success, warning, error }

class FacultyMapViewModel extends ChangeNotifier {
  FacultyMapViewModel({int initialFloorIndex = 1})
    : _floorIndex = initialFloorIndex.clamp(0, 6);
  int _floorIndex;
  int get floorIndex => _floorIndex;
  String? feedbackMessage;
  MapFeedbackType? feedbackType;
  int feedbackId = 0;
  Timer? _feedbackTimer;

  void showFeedback(String? message, MapFeedbackType? type) {
    if (message == null || type == null) return;
    _feedbackTimer?.cancel();
    feedbackMessage = message;
    feedbackType = type;
    feedbackId++;
    notifyListeners();
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      feedbackMessage = null;
      feedbackType = null;
      notifyListeners();
    });
  }

  void nextFloor() => _move(1);
  void previousFloor() => _move(-1);
  void _move(int direction) {
    final next = (_floorIndex + direction).clamp(0, 6);
    if (next == _floorIndex) {
      showFeedback(
        direction > 0
            ? 'Ya estás en la última planta.'
            : 'Ya estás en la planta más baja.',
        MapFeedbackType.error,
      );
      return;
    }
    _floorIndex = next;
    showFeedback(
      direction > 0
          ? '¡Buen movimiento! Subiendo de planta.'
          : '¡Buen movimiento! Bajando de planta.',
      MapFeedbackType.success,
    );
  }

  void setFloor(int index) {
    if (index.clamp(0, 6) == _floorIndex) return;
    _floorIndex = index.clamp(0, 6);
    notifyListeners();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }
}
