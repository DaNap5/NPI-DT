import 'package:flutter/material.dart';
import 'package:npi/orientation/map_zone.dart';

// Red vertices transcribed from the full 1024 × 768 user reference.
const firstFloorZones = <MapZone>[
  MapZone(
    id: 'biblioteca',
    number: 1,
    name: 'Biblioteca',
    description:
        'Biblioteca de la escuela, con espacios para estudiar y consultar material académico. '
        'También dispone de ordenadores para apoyar el estudio y el trabajo universitario.',
    color: Color(0xFFE19A38),
    marker: Offset(302 / 1024, 354 / 768),
    polygons: [
      [
        Offset(200 / 1024, 319 / 768),
        Offset(468 / 1024, 225 / 768),
        Offset(589 / 1024, 400 / 768),
        Offset(455 / 1024, 453 / 768),
        Offset(297 / 1024, 501 / 768),
        Offset(278 / 1024, 509 / 768),
        Offset(235 / 1024, 408 / 768),
      ],
    ],
    holes: [
      [
        Offset(331 / 1024, 355 / 768),
        Offset(346 / 1024, 339 / 768),
        Offset(358 / 1024, 331 / 768),
        Offset(368 / 1024, 318 / 768),
        Offset(381 / 1024, 306 / 768),
        Offset(399 / 1024, 303 / 768),
        Offset(412 / 1024, 304 / 768),
        Offset(426 / 1024, 305 / 768),
        Offset(442 / 1024, 312 / 768),
        Offset(453 / 1024, 325 / 768),
        Offset(461 / 1024, 338 / 768),
        Offset(463 / 1024, 353 / 768),
        Offset(450 / 1024, 365 / 768),
        Offset(435 / 1024, 377 / 768),
        Offset(421 / 1024, 392 / 768),
        Offset(406 / 1024, 401 / 768),
        Offset(386 / 1024, 403 / 768),
        Offset(365 / 1024, 400 / 768),
        Offset(349 / 1024, 396 / 768),
        Offset(338 / 1024, 388 / 768),
        Offset(332 / 1024, 373 / 768),
      ],
    ],
  ),
  MapZone(
    id: 'aulas-1',
    number: 2,
    name: 'Aulas 1',
    description:
        'Conjunto de aulas de la primera planta, con una numeración análoga a la de las aulas 0. '
        'Son aulas más pequeñas que las de la planta baja, destinadas a actividades docentes.',
    color: Color(0xFF39956A),
    marker: Offset(731 / 1024, 360 / 768),
    polygons: [
      [
        Offset(520 / 1024, 178 / 768),
        Offset(579 / 1024, 132 / 768),
        Offset(985 / 1024, 573 / 768),
        Offset(826 / 1024, 565 / 768),
      ],
    ],
  ),
];
