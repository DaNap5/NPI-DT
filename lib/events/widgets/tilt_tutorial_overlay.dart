import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:npi/events/tilt_tutorial_manager.dart';

class TiltTutorialOverlay extends StatefulWidget {
  const TiltTutorialOverlay({
    super.key,
    required this.tutorialManager,
    this.onSkip,
  });

  final TiltTutorialManager tutorialManager;
  final VoidCallback? onSkip;

  @override
  State<TiltTutorialOverlay> createState() => _TiltTutorialOverlayState();
}

class _TiltTutorialOverlayState extends State<TiltTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _gestureAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    widget.tutorialManager.addListener(_syncAnimation);
    _syncAnimation();

    _gestureAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  void _syncAnimation() {
    if (widget.tutorialManager.isActive) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void didUpdateWidget(covariant TiltTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tutorialManager != widget.tutorialManager) {
      oldWidget.tutorialManager.removeListener(_syncAnimation);
      widget.tutorialManager.addListener(_syncAnimation);
      _syncAnimation();
    }
  }

  @override
  void dispose() {
    widget.tutorialManager.removeListener(_syncAnimation);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.tutorialManager,
      builder: (context, _) {
        if (!widget.tutorialManager.isActive) {
          return const SizedBox.shrink();
        }

        final step = widget.tutorialManager.currentStep;
        final isCompleted = step == TiltTutorialStep.completed;
        final isPan =
            step == TiltTutorialStep.panSave ||
            step == TiltTutorialStep.panDiscard;
        final isSaveStep =
            step == TiltTutorialStep.panSave ||
            step == TiltTutorialStep.tiltSave;

        // Dirección visual:
        // Pan: Guardar (panSave) = Derecha (+1.0), Descartar (panDiscard) = Izquierda (-1.0)
        // Tilt: Guardar (tiltSave) = Izquierda (-1.0), Descartar (tiltDiscard) = Derecha (+1.0)
        final double direction =
            (step == TiltTutorialStep.panSave ||
                step == TiltTutorialStep.tiltDiscard)
            ? 1.0
            : -1.0;

        return Stack(
          children: [
            IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isCompleted)
                        SizedBox(
                          height: 130,
                          width: 220,
                          child: Center(
                            child: isPan
                                ? _buildPanAnimation(direction, isSaveStep)
                                : _buildTiltAnimation(direction, isSaveStep),
                          ),
                        )
                      else
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.greenAccent,
                          size: 72,
                        ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _getInstructionTitle(step),
                          key: ValueKey('title_$step'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!isCompleted)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _getInstructionSubtitle(step),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isCompleted)
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: TextButton(
                    onPressed: () {
                      widget.tutorialManager.skip();
                      widget.onSkip?.call();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black38,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Saltar'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPanAnimation(double direction, bool isSaveStep) {
    return AnimatedBuilder(
      animation: _gestureAnimation,
      builder: (context, child) {
        final double dx = _gestureAnimation.value * 65.0 * direction;
        final double tilt = _gestureAnimation.value * 0.12 * direction;

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(angle: tilt, child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              isSaveStep ? Icons.favorite_rounded : Icons.close_rounded,
              color: isSaveStep ? Colors.greenAccent : Colors.redAccent,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          const Icon(Icons.touch_app_rounded, color: Colors.white, size: 42),
        ],
      ),
    );
  }

  Widget _buildTiltAnimation(double direction, bool isSaveStep) {
    return AnimatedBuilder(
      animation: _gestureAnimation,
      builder: (context, child) {
        final double angle =
            _gestureAnimation.value * (math.pi / 6.0) * direction;

        return Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: Container(
        width: 68,
        height: 112,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              isSaveStep ? Icons.favorite_rounded : Icons.close_rounded,
              color: isSaveStep ? Colors.greenAccent : Colors.redAccent,
              size: 28,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getInstructionTitle(TiltTutorialStep step) {
    switch (step) {
      case TiltTutorialStep.panSave:
        return 'Desliza a la derecha para guardar';
      case TiltTutorialStep.panDiscard:
        return 'Desliza a la izquierda para descartar';
      case TiltTutorialStep.tiltSave:
        return 'Inclina a la izquierda para guardar';
      case TiltTutorialStep.tiltDiscard:
        return 'Inclina a la derecha para descartar';
      case TiltTutorialStep.completed:
        return '¡Perfecto! Ya lo dominas';
    }
  }

  String _getInstructionSubtitle(TiltTutorialStep step) {
    switch (step) {
      case TiltTutorialStep.panSave:
        return 'Arrastra la tarjeta con el dedo hacia la derecha';
      case TiltTutorialStep.panDiscard:
        return 'Ahora arrastra la tarjeta hacia la izquierda';
      case TiltTutorialStep.tiltSave:
        return 'También puedes usar la muñeca: inclina el móvil a la izquierda';
      case TiltTutorialStep.tiltDiscard:
        return 'Vuelve al centro e inclina el móvil a la derecha';
      case TiltTutorialStep.completed:
        return '';
    }
  }
}
