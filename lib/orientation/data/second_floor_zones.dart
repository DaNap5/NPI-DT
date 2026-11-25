import 'package:flutter/material.dart';
import 'package:npi/orientation/map_zone.dart';

// Vertices marked by the user on the 1024 × 768 second-floor render.
const secondFloorZones = <MapZone>[
  MapZone(
    id: 'despachos-2',
    number: 1,
    name: 'Despachos',
    description:
        'Zona de despachos del personal docente e investigador. '
        'Espacios de trabajo y atención académica, como consultas y tutorías acordadas con el profesorado.',
    color: Color(0xFFAD6BBA),
    marker: Offset(255 / 1024, 438 / 768),
    polygons: [
      [
        Offset(38 / 1024, 595 / 768),
        Offset(490 / 1024, 177 / 768),
        Offset(532 / 1024, 240 / 768),
        Offset(194 / 1024, 597 / 768),
      ],
    ],
  ),
  MapZone(
    id: 'aulas-2',
    number: 2,
    name: 'Aulas 2',
    description:
        'Conjunto de aulas de la segunda planta, identificadas por la numeración correspondiente a este nivel. '
        'Se utilizan para clases y actividades académicas.',
    color: Color(0xFF39956A),
    marker: Offset(732 / 1024, 294 / 768),
    polygons: [
      [
        Offset(530 / 1024, 147 / 768),
        Offset(580 / 1024, 104 / 768),
        Offset(997 / 1024, 550 / 768),
        Offset(836 / 1024, 543 / 768),
        Offset(796 / 1024, 468 / 768),
        Offset(805 / 1024, 448 / 768),
        Offset(795 / 1024, 429 / 768),
        Offset(774 / 1024, 412 / 768),
        Offset(744 / 1024, 405 / 768),
        Offset(724 / 1024, 412 / 768),
      ],
    ],
  ),
];

// Approximate location for the origin-selection mock; the classroom geometry
// has not been confirmed against a numbered floor plan.
const classroom27OriginZone = MapZone(
  id: 'classroom-2-7',
  number: 3,
  name: 'Aula 2.7',
  description: 'Origen provisional de la ruta.',
  color: Color(0xFF1767B3),
  marker: Offset(851 / 1024, 461 / 768),
  polygons: [
    [
      Offset(816 / 1024, 422 / 768),
      Offset(883 / 1024, 443 / 768),
      Offset(887 / 1024, 483 / 768),
      Offset(841 / 1024, 475 / 768),
    ],
  ],
);
