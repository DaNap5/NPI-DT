import 'package:flutter/material.dart';
import 'package:npi/orientation/map_zone.dart';

// Four red vertices on the user's full 1024 × 768 fifth-floor reference.
const fifthFloorZones = <MapZone>[
  MapZone(
    id: 'sala-usos-multiples',
    number: 1,
    name: 'Sala de usos múltiples',
    description:
        'Espacio polivalente para reuniones, encuentros y actividades de la escuela. '
        'Su uso puede adaptarse a distintas necesidades académicas y colectivas.',
    color: Color(0xFF2988B8),
    marker: Offset(302 / 1024, 346 / 768),
    polygons: [
      [
        Offset(219 / 1024, 318 / 768),
        Offset(322 / 1024, 286 / 768),
        Offset(371 / 1024, 372 / 768),
        Offset(257 / 1024, 408 / 768),
      ],
    ],
  ),
];
