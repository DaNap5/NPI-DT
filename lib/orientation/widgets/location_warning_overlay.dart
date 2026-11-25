import 'dart:async';

import 'package:flutter/material.dart';

class LocationWarningOverlay extends StatefulWidget {
  const LocationWarningOverlay({super.key, required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  State<LocationWarningOverlay> createState() => _LocationWarningOverlayState();
}

class _LocationWarningOverlayState extends State<LocationWarningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _dismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    _controller.reverse().whenComplete(widget.onDismissed);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top + 8;
    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
        child: Material(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(18),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Ubicación no disponible. Navegación manual activada.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
