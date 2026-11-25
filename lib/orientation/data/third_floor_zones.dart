import 'package:flutter/material.dart';
import 'package:npi/orientation/map_zone.dart';

// Red vertices on the user's 1024 × 768 third-floor reference.
const thirdFloorZones = <MapZone>[
  MapZone(
    id: 'despachos-3',
    number: 1,
    name: 'Despachos',
    description:
        'Zona de despachos del personal docente e investigador. '
        'Espacios de trabajo y atención académica, como consultas y tutorías acordadas con el profesorado.',
    color: Color(0xFFAD6BBA),
    marker: Offset(242 / 1024, 436 / 768),
    polygons: [
      [
        Offset(30 / 1024, 564 / 768),
        Offset(486 / 1024, 161 / 768),
        Offset(533 / 1024, 222 / 768),
        Offset(187 / 1024, 577 / 768),
      ],
    ],
  ),
  MapZone(
    id: 'aulas-3',
    number: 2,
    name: 'Aulas 3',
    description:
        'Conjunto de aulas de la tercera planta, identificadas por la numeración correspondiente a este nivel. '
        'Son espacios para la docencia y el trabajo académico.',
    color: Color(0xFF39956A),
    marker: Offset(724 / 1024, 290 / 768),
    polygons: [
      [
        Offset(519 / 1024, 136 / 768),
        Offset(579 / 1024, 88 / 768),
        Offset(980 / 1024, 518 / 768),
        Offset(842 / 1024, 525 / 768),
        Offset(790 / 1024, 451 / 768),
        Offset(812 / 1024, 420 / 768),
        Offset(806 / 1024, 409 / 768),
        Offset(788 / 1024, 396 / 768),
        Offset(773 / 1024, 386 / 768),
        Offset(752 / 1024, 385 / 768),
        Offset(727 / 1024, 391 / 768),
      ],
    ],
  ),
];
