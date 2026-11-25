import 'package:npi/storage/local_store.dart';
import 'package:flutter/material.dart';
import 'package:npi/orientation/data/second_floor_zones.dart';
import 'package:npi/orientation/map_zone.dart';
import 'package:npi/orientation/faculty_map_screen.dart';

class OriginMapPage extends StatelessWidget {
  const OriginMapPage({super.key, required this.store});
  final LocalStore store;

  Future<void> _confirmOrigin(BuildContext context, MapZone zone) async {
    if (zone.id != classroom27OriginZone.id) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aula 2.7'),
        content: const Text('¿Quieres seleccionar el aula 2.7 como origen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
    if (context.mounted && confirmed == true) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => FacultyMapScreen(
    title: 'Selecciona tu origen',
    store: store,
    initialFloorIndex: 3,
    additionalZonesByFloor: const {
      3: [classroom27OriginZone],
    },
    onZoneSelected: (zone) => _confirmOrigin(context, zone),
  );
}
