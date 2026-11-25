import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/services/leap_websocket_service.dart';
import '../../../domain/models/leap_event.dart';

class LeapHudOverlay extends StatefulWidget {
  final Widget child;
  final LeapWebSocketService service;

  const LeapHudOverlay({super.key, required this.child, required this.service});

  @override
  State<LeapHudOverlay> createState() => _LeapHudOverlayState();
}

class _LeapHudOverlayState extends State<LeapHudOverlay> {
  StreamSubscription<LeapEvent>? _sub;
  bool _handDetected = false;
  double _x = 0.5;
  double _y = 0.5;
  double _progress = 0.0;
  String? _lastGestureLabel;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    _sub = widget.service.events.listen((event) {
      if (!mounted) return;
      if (event is LeapHandTracking) {
        setState(() {
          _handDetected = event.isHandDetected;
          _x = event.normalizedX;
          _y = event.normalizedY;
          _progress = event.gestureProgress;
        });
      } else if (event is LeapGestureDetected) {
        _badgeTimer?.cancel();
        setState(() {
          _lastGestureLabel = event.gesture.name;
        });
        _badgeTimer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _lastGestureLabel = null);
        });
      }
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_handDetected)
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final left = (_x * constraints.maxWidth) - 18;
                  final top = (_y * constraints.maxHeight) - 18;
                  return Stack(
                    children: [
                      Positioned(
                        left: left.clamp(0.0, constraints.maxWidth - 36),
                        top: top.clamp(0.0, constraints.maxHeight - 36),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            value: _progress > 0 ? _progress : 1.0,
                            strokeWidth: 3,
                            color: _progress > 0
                                ? Colors.amber
                                : Colors.tealAccent.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        if (_lastGestureLabel != null)
          Positioned(
            top: 48,
            right: 16,
            child: IgnorePointer(
              child: Material(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pan_tool_alt,
                        color: Colors.tealAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _lastGestureLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
