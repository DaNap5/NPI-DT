import 'package:flutter/material.dart';
import 'package:npi/orientation/map_zone.dart';

// Only the red vertex marks from the user's 1024 × 768 reference.
// Pixel divisions are kept explicit to make manual corrections straightforward.
const basementZones = <MapZone>[
  MapZone(
    id: 'cafeteria',
    number: 1,
    name: 'Cafetería',
    description:
        'Espacio para tomar algo y hacer una pausa entre clases. '
        'Un punto de encuentro informal dentro de la escuela.',
    color: Color(0xFFE19A38),
    marker: Offset(289 / 1024, 371 / 768),
    polygons: [
      [
        Offset(220 / 1024, 365 / 768),
        Offset(320 / 1024, 329 / 768),
        Offset(401 / 1024, 294 / 768),
        Offset(412 / 1024, 324 / 768),
        Offset(353 / 1024, 339 / 768),
        Offset(321 / 1024, 365 / 768),
        Offset(300 / 1024, 392 / 768),
        Offset(289 / 1024, 419 / 768),
        Offset(261 / 1024, 444 / 768),
      ],
    ],
  ),
  MapZone(
    id: 'comedor',
    number: 2,
    name: 'Comedor',
    description:
        'Comedor universitario oficial, destinado al servicio de comidas de la comunidad universitaria. '
        'Para acceder es necesario presentar la Tarjeta Universitaria Inteligente (TUI).',
    color: Color(0xFF2988B8),
    marker: Offset(512 / 1024, 425 / 768),
    polygons: [
      [
        Offset(400 / 1024, 486 / 768),
        Offset(433 / 1024, 457 / 768),
        Offset(451 / 1024, 431 / 768),
        Offset(470 / 1024, 417 / 768),
        Offset(476 / 1024, 398 / 768),
        Offset(484 / 1024, 381 / 768),
        Offset(506 / 1024, 373 / 768),
        Offset(529 / 1024, 368 / 768),
        Offset(549 / 1024, 394 / 768),
        Offset(566 / 1024, 423 / 768),
        Offset(582 / 1024, 434 / 768),
        Offset(556 / 1024, 451 / 768),
        Offset(524 / 1024, 467 / 768),
        Offset(487 / 1024, 481 / 768),
        Offset(454 / 1024, 492 / 768),
        Offset(416 / 1024, 503 / 768),
      ],
    ],
  ),
  MapZone(
    id: 'salon-de-actos',
    number: 3,
    name: 'Salón de actos',
    description:
        'Espacio para presentaciones, conferencias y actos de mayor tamaño. '
        'Acoge encuentros y actividades colectivas de la escuela.',
    color: Color(0xFFAD6BBA),
    marker: Offset(399 / 1024, 378 / 768),
    polygons: [
      [
        Offset(337 / 1024, 389 / 768),
        Offset(354 / 1024, 370 / 768),
        Offset(379 / 1024, 355 / 768),
        Offset(399 / 1024, 349 / 768),
        Offset(415 / 1024, 347 / 768),
        Offset(430 / 1024, 340 / 768),
        Offset(445 / 1024, 345 / 768),
        Offset(459 / 1024, 351 / 768),
        Offset(462 / 1024, 360 / 768),
        Offset(465 / 1024, 374 / 768),
        Offset(464 / 1024, 392 / 768),
        Offset(453 / 1024, 412 / 768),
        Offset(435 / 1024, 427 / 768),
        Offset(417 / 1024, 442 / 768),
        Offset(381 / 1024, 445 / 768),
        Offset(357 / 1024, 430 / 768),
        Offset(344 / 1024, 408 / 768),
      ],
    ],
  ),
];
