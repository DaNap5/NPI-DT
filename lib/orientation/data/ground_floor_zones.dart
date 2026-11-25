import 'package:flutter/material.dart';
import 'package:npi/orientation/map_zone.dart';

// Trial catalogue traced from the numbered user reference, not a full inventory.
// Each service has a continuous outline, crossing internal partitions.
// The circular stair core remains outside the classroom outline.
const groundFloorZones = <MapZone>[
  MapZone(
    id: 'hall',
    number: 1,
    name: 'Hall',
    description:
        'Zona de entrada y paso, con elementos decorativos que dan la bienvenida a la escuela. '
        'Sirve como punto de encuentro y conexión con otras dependencias.',
    color: Color(0xFF2988B8),
    marker: Offset(.377, .479),
    polygons: [
      [
        Offset(.331, .481),
        Offset(.348, .457),
        Offset(.372, .435),
        Offset(.395, .429),
        Offset(.421, .435),
        Offset(.447, .448),
        Offset(.451, .459),
        Offset(.433, .482),
        Offset(.410, .507),
        Offset(.395, .523),
        Offset(.390, .550),
        Offset(.375, .550),
        Offset(.357, .536),
        Offset(.343, .517),
        Offset(.334, .497),
      ],
    ],
  ),
  MapZone(
    id: 'secretaria',
    number: 2,
    name: 'Secretaría',
    description:
        'Punto de atención para gestiones universitarias y consultas administrativas. '
        'Aquí puedes orientarte sobre trámites relacionados con tus estudios.',
    color: Color(0xFFAD6BBA),
    marker: Offset(.455, .372),
    polygons: [
      [
        Offset(.421, .342),
        Offset(.452, .328),
        Offset(.482, .373),
        Offset(.510, .419),
        Offset(.480, .428),
        Offset(.460, .438),
        Offset(.450, .416),
        Offset(.429, .405),
        Offset(.397, .402),
        Offset(.414, .379),
        Offset(.428, .363),
      ],
    ],
  ),
  MapZone(
    id: 'aulas-0',
    number: 3,
    name: 'Aulas 0',
    description:
        'Conjunto de aulas de la planta baja, identificadas con números como 0.0, 0.1 o 0.2. '
        'Son espacios destinados a clases y otras actividades docentes.',
    color: Color(0xFF39956A),
    marker: Offset(.701, .395),
    polygons: [
      [
        Offset(.525, .254),
        Offset(.6, .180),
        Offset(.998, .75),
        Offset(.8, .73),
      ],
    ],
  ),
  // Provisional square around the entrance in the lower-left of the render.
  MapZone(
    id: 'faculty-entrance',
    number: 4,
    name: 'Puerta de la facultad',
    description: 'Entrada principal de la ETSIIT.',
    color: Color(0xFFB87932),
    marker: Offset(.152, .802),
    polygons: [
      [
        Offset(.122, .762),
        Offset(.182, .762),
        Offset(.182, .842),
        Offset(.122, .842),
      ],
    ],
  ),
];
