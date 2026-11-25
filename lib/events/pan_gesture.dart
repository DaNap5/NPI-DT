import 'package:npi/events/swipe_state.dart';

class PanGesture {
  static const double _dismissThresholdRatio = 0.35;
  static const double _velocityThreshold = 500.0;

  SwipeState updateDrag({
    required SwipeState currentState,
    required double deltaX,
    required double dragRatio,
  }) {
    // Si ya está saliendo, no permitimos que un toque accidental lo interrumpa
    if (currentState is SwipeAnimating) return currentState;

    final double currentOffset = currentState.dragOffset;
    final double newOffset = currentOffset + deltaX;
    final double normalizedProgress = (dragRatio / _dismissThresholdRatio)
        .clamp(-1.0, 1.0);

    return SwipePanning(
      dragOffset: newOffset,
      progress: normalizedProgress,
      decision: SwipeDecision.none,
    );
  }

  SwipeState evaluateEnd({
    required SwipeState currentState,
    required double velocityX,
    required double currentDragRatio,
  }) {
    final bool isDismissedRight =
        currentDragRatio > _dismissThresholdRatio ||
        velocityX > _velocityThreshold;
    final bool isDismissedLeft =
        currentDragRatio < -_dismissThresholdRatio ||
        velocityX < -_velocityThreshold;

    if (isDismissedRight) {
      return SwipePanning(
        dragOffset: currentState.dragOffset,
        progress: currentState.progress,
        decision: SwipeDecision.save,
      );
    } else if (isDismissedLeft) {
      return SwipePanning(
        dragOffset: currentState.dragOffset,
        progress: currentState.progress,
        decision: SwipeDecision.discard,
      );
    }

    return const SwipeIdle();
  }
}
