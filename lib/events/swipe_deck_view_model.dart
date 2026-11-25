import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'events_view_model.dart';
import 'swipe_state.dart';
import 'pan_gesture.dart';
import 'tilt_tutorial_manager.dart';

class SwipeDeckViewModel extends ChangeNotifier {
  SwipeDeckViewModel(this.events) {
    tutorialManager.addListener(_onTutorialChanged);
  }
  final EventsViewModel events;
  final _pan = PanGesture();
  final tutorialManager = TiltTutorialManager();
  SwipeState _state = const SwipeIdle();
  Timer? _animation;
  bool _disposed = false;
  bool _committing = false;
  double get dragOffset => _state.dragOffset;
  double get swipeProgress => _state.progress;
  double get rotation => _state.rotation;
  bool get isProcessingSwipe =>
      _state is SwipeAnimating && _state.decision != SwipeDecision.none;
  bool get isSnappingBack =>
      _state is SwipeAnimating && _state.decision == SwipeDecision.none;
  bool get acceptsTilt =>
      !_disposed &&
      !events.isMutating &&
      !events.isLoading &&
      !_committing &&
      _state is! SwipeAnimating &&
      _state is! SwipePanning &&
      events.events.isNotEmpty &&
      !tutorialManager.isPanPhase;

  void _onTutorialChanged() {
    if (!_disposed) notifyListeners();
  }

  void resetTutorial() {
    snapBack();
    tutorialManager.start();
  }

  void showTiltProgress(double progress) {
    if (!acceptsTilt) return;
    _state = SwipeTilting(normalizedTilt: progress, progress: progress);
    notifyListeners();
  }

  void saveByTilt() {
    if (acceptsTilt) unawaited(_executeSwipe(SwipeDecision.save));
  }

  void discardByTilt() {
    if (acceptsTilt) unawaited(_executeSwipe(SwipeDecision.discard));
  }

  void handlePanStart(DragStartDetails details) {
    if (_committing ||
        isProcessingSwipe ||
        events.isMutating ||
        tutorialManager.isTiltPhase) {
      return;
    }
    _animation?.cancel();
    _state = const SwipePanning(dragOffset: 0, progress: 0);
    notifyListeners();
  }

  void handlePanUpdate(DragUpdateDetails details, double width) {
    if (_committing ||
        isProcessingSwipe ||
        events.isMutating ||
        tutorialManager.isTiltPhase) {
      return;
    }
    _state = _pan.updateDrag(
      currentState: _state,
      deltaX: details.delta.dx,
      dragRatio: (_state.dragOffset + details.delta.dx) / width,
    );
    notifyListeners();
  }

  void handlePanEnd(DragEndDetails details, double width) {
    if (_committing ||
        isProcessingSwipe ||
        events.isMutating ||
        tutorialManager.isTiltPhase) {
      return;
    }
    _state = _pan.evaluateEnd(
      currentState: _state,
      velocityX: details.velocity.pixelsPerSecond.dx,
      currentDragRatio: _state.dragOffset / width,
    );
    if (_state.decision == SwipeDecision.none) {
      snapBack();
    } else {
      unawaited(
        _executeSwipe(
          _state.decision,
          exitDistance: width * 1.2,
          isFromPan: true,
        ),
      );
    }
  }

  void snapBack() {
    if (_disposed || _committing) return;
    _animation?.cancel();
    _state = const SwipeAnimating(
      dragOffset: 0,
      rotation: 0,
      progress: 0,
      decision: SwipeDecision.none,
    );
    notifyListeners();
    _animation = Timer(const Duration(milliseconds: 200), () {
      _state = const SwipeIdle();
      if (!_disposed) notifyListeners();
    });
  }

  Future<void> _executeSwipe(
    SwipeDecision decision, {
    double exitDistance = 800,
    bool isFromPan = false,
  }) async {
    if (_disposed ||
        _committing ||
        events.isMutating ||
        events.events.isEmpty) {
      return;
    }
    if (tutorialManager.isActive) {
      tutorialManager.handleGesture(decision, isFromPan: isFromPan);
      snapBack();
      return;
    }
    final event = events.events.last;
    final owner = events.session.username;
    _committing = true;
    _animation?.cancel();
    _state = SwipeAnimating(
      dragOffset: decision == SwipeDecision.save ? exitDistance : -exitDistance,
      rotation: _state.rotation.clamp(-math.pi / 12, math.pi / 12),
      progress: decision == SwipeDecision.save ? 1 : -1,
      decision: decision,
    );
    notifyListeners();
    // The timer owns only presentation; persistence is awaited separately.
    _animation = Timer(const Duration(milliseconds: 200), () async {
      try {
        if (!_disposed && owner == events.session.username) {
          if (decision == SwipeDecision.save) {
            await events.saveEvent(event);
          } else {
            await events.discardEvent(event);
          }
        }
      } catch (_) {
        /* The feature viewmodel exposes persistence failure. */
      } finally {
        _committing = false;
        if (!_disposed) {
          _state = const SwipeIdle();
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _animation?.cancel();
    tutorialManager.removeListener(_onTutorialChanged);
    tutorialManager.dispose();
    super.dispose();
  }
}
