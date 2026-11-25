import 'package:flutter/material.dart';
import 'package:npi/orientation/map_zone.dart';

class ZoneInfoPanel extends StatelessWidget {
  const ZoneInfoPanel({
    super.key,
    required this.zone,
    required this.floorName,
    required this.onClose,
    required this.onDirections,
  });
  final MapZone zone;
  final String floorName;
  final VoidCallback onClose;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('zone-info-panel'),
    elevation: 8,
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 4, top: 4),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: zone.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  zone.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'Cerrar información',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planta: $floorName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Información provisional',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(zone.description),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onDirections,
              child: const Text('Llévame'),
            ),
          ),
        ),
      ],
    ),
  );
}
