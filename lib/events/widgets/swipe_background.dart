// lib/ui/events/widgets/core/events_swipeable_list/swipe_background.dart

import 'package:flutter/material.dart';

class SwipeBackground extends StatelessWidget {
  const SwipeBackground({
    super.key,
    required this.dragOffset,
    required this.progress,
  });

  final double dragOffset;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (dragOffset == 0.0) {
      return const SizedBox.shrink();
    }

    final bool isSave = dragOffset > 0;
    final Color backgroundColor = isSave
        ? Colors.green.shade400
        : Colors.red.shade400;
    final IconData icon = isSave ? Icons.favorite : Icons.close;
    final Alignment alignment = isSave
        ? Alignment.centerLeft
        : Alignment.centerRight;

    final double opacity = progress.abs().clamp(0.0, 1.0);

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        alignment: alignment,
        child: Opacity(
          opacity: opacity,
          child: Icon(icon, color: Colors.white, size: 48),
        ),
      ),
    );
  }
}
