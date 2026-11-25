import 'dart:math' as math;

enum SwipeDecision { none, save, discard }

sealed class SwipeState {
  final double progress;
  final SwipeDecision decision;

  const SwipeState({
    required this.progress,
    this.decision = SwipeDecision.none,
  });

  double get dragOffset;
  double get rotation;
  bool get isAnimating;

  bool hasVisualChangeFrom(SwipeState other) {
    if (runtimeType != other.runtimeType) return true;
    if (decision != other.decision) return true;
    return (dragOffset - other.dragOffset).abs() > 0.5;
  }
}

class SwipeIdle extends SwipeState {
  const SwipeIdle() : super(progress: 0.0);

  @override
  double get dragOffset => 0.0;
  @override
  double get rotation => 0.0;
  @override
  bool get isAnimating => false;
}

class SwipePanning extends SwipeState {
  @override
  final double dragOffset;

  const SwipePanning({
    required this.dragOffset,
    required super.progress,
    super.decision,
  });

  @override
  double get rotation => 0.0;
  @override
  bool get isAnimating => false;
}

class SwipeTilting extends SwipeState {
  final double normalizedTilt;
  final SwipeDecision armedDecision;
  final double returningTime; // Cronómetro para el Tiempo de Tránsito

  static const double _maxRotationAngle = math.pi / 12;

  const SwipeTilting({
    required this.normalizedTilt,
    this.armedDecision = SwipeDecision.none,
    this.returningTime = 0.0,
    required super.progress,
    super.decision,
  });

  @override
  double get dragOffset => progress * 180.0;

  @override
  double get rotation => progress * _maxRotationAngle;

  @override
  bool get isAnimating => false;
}

class SwipeAnimating extends SwipeState {
  @override
  final double dragOffset;
  @override
  final double rotation;

  const SwipeAnimating({
    required this.dragOffset,
    required this.rotation,
    required super.progress,
    required super.decision,
  });

  @override
  bool get isAnimating => true;
}
