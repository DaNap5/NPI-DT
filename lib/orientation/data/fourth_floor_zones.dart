import 'package:flutter/material.dart';
import 'package:npi/orientation/map_zone.dart';

// The four red vertices on the user's 1024 × 768 fourth-floor reference.
const fourthFloorZones = <MapZone>[
  MapZone(
    id: 'despachos-4',
    number: 1,
    name: 'Despachos',
    description:
        'Zona de despachos del personal docente e investigador. '
        'Espacios de trabajo y atención académica, como consultas y tutorías acordadas con el profesorado.',
    color: Color(0xFFAD6BBA),
    marker: Offset(240 / 1024, 395 / 768),
    polygons: [
      [
        Offset(14 / 1024, 553 / 768),
        Offset(485 / 1024, 138 / 768),
        Offset(541 / 1024, 204 / 768),
        Offset(177 / 1024, 554 / 768),
      ],
    ],
  ),
];
