enum LeapGestureType {
  swipeLeft,
  swipeRight,
  swipeUp,
  swipeDown,
  openHand,
  closedFist,
  pinch,
}

sealed class LeapEvent {
  const LeapEvent();
}

final class LeapHandTracking extends LeapEvent {
  final bool isHandDetected;
  final double normalizedX;
  final double normalizedY;
  final double gestureProgress;

  const LeapHandTracking({
    required this.isHandDetected,
    this.normalizedX = 0.5,
    this.normalizedY = 0.5,
    this.gestureProgress = 0.0,
  });
}

final class LeapGestureDetected extends LeapEvent {
  final LeapGestureType gesture;
  const LeapGestureDetected(this.gesture);
}
