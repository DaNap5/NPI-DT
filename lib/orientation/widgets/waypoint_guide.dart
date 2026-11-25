import 'package:flutter/material.dart';
import 'package:npi/orientation/waypoint.dart';

class WaypointGuide extends StatelessWidget {
  const WaypointGuide({
    super.key,
    required this.waypoints,
    required this.currentIndex,
    required this.onPrevious,
    required this.onNext,
    required this.onHome,
    required this.distanceMeters,
    required this.waypointReached,
    required this.automaticValidation,
    required this.locationUnavailable,
    required this.trackedWaypointName,
  });

  final List<Waypoint> waypoints;
  final int currentIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onHome;
  final double? distanceMeters;
  final bool waypointReached;
  final bool automaticValidation;
  final bool locationUnavailable;
  final String? trackedWaypointName;

  Widget _waypointImage(
    BuildContext context,
    Waypoint waypoint, {
    required double height,
    required bool showArrow,
    required Key key,
    required bool interactive,
  }) {
    final image = Image.asset(
      waypoint.image,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            waypoint.name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        key: key,
        children: [
          image,
          if (showArrow)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    waypoint.direction,
                    color: Colors.white,
                    size: 76,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(
              color: Colors.black54,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  waypoint.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final semanticContent = Semantics(
      image: true,
      label: waypoint.name,
      child: content,
    );

    if (!interactive) return semanticContent;

    return Semantics(
      button: true,
      label: 'Abrir imagen de ${waypoint.name}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFullImage(context, waypoint),
        child: semanticContent,
      ),
    );
  }

  void _showFullImage(BuildContext context, Waypoint waypoint) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.asset(
                waypoint.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(waypoint.name),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Cerrar imagen',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = waypoints[currentIndex];
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < waypoints.length - 1;
    final next = hasNext ? waypoints[currentIndex + 1] : null;
    final Widget? distanceStatus = automaticValidation && !locationUnavailable
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              distanceMeters == null
                  ? 'Calculando distancia...'
                  : waypointReached
                  ? 'Has llegado a ${trackedWaypointName ?? "tu destino"}'
                  : '${distanceMeters!.toStringAsFixed(0)}m hasta llegar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          )
        : null;

    return LayoutBuilder(
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          key: ValueKey('guide-step-$currentIndex'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: hasNext ? 5 : 6,
              child: _waypointImage(
                context,
                current,
                height: double.infinity,
                showArrow: hasNext || current.id == 'auxiliary_door',
                key: const ValueKey('current-waypoint-image'),
                interactive: false,
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.directions,
                      color: Colors.blue.shade700,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.3,
                            color: Color(0xFF0F172A),
                          ),
                          children: [
                            TextSpan(
                              text: 'Indicaciones: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            TextSpan(
                              text: 've hacia ${next.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ?distanceStatus,
              Expanded(
                flex: 2,
                child: _waypointImage(
                  context,
                  next,
                  height: double.infinity,
                  showArrow: false,
                  key: const ValueKey('next-waypoint-image'),
                  interactive: true,
                ),
              ),
            ] else ...[
              ?distanceStatus,
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBDEFB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF0D47A1),
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Has llegado a tu destino',
                            style: TextStyle(
                              color: Color(0xFF0D47A1),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onHome,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(68),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text(
                          'Volver a pantalla de inicio',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _NavigationControls(
              hasPrevious: hasPrevious,
              hasNext: hasNext,
              onPrevious: onPrevious,
              onNext: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationControls extends StatelessWidget {
  const _NavigationControls({
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hasPrevious)
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back),
            iconSize: 56,
            tooltip: 'Paso anterior',
          ),
        const Spacer(),
        if (hasNext)
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            iconSize: 56,
            tooltip: 'Siguiente paso',
          ),
      ],
    );
  }
}
