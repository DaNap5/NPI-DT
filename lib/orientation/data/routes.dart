import 'package:flutter/material.dart';

import '../waypoint.dart';

const indoorWaypoints = <Waypoint>[
  Waypoint(
    id: 'door_2_7',
    name: 'Puerta 2.7',
    image: 'assets/orientation/waypoints/indoor_door_2_7.jpg',
    latitude: 37.197386,
    longitude: -3.624223,
    gpsRadiusMeters: 20,
    direction: Icons.arrow_left,
  ),
  Waypoint(
    id: 'between_2_7_faculty',
    name: 'Lugar entre el Aula 2.7 y puerta facultad',
    image: 'assets/orientation/waypoints/indoor_corridor_faculty.jpg',
    latitude: 37.197386,
    longitude: -3.624223,
    gpsRadiusMeters: 20,
    direction: Icons.turn_left,
  ),
  Waypoint(
    id: 'faculty_door',
    name: 'Puerta facultad',
    image: 'assets/orientation/waypoints/indoor_faculty_door.jpg',
    latitude: 37.196972,
    longitude: -3.624286,
    gpsRadiusMeters: 20,
    direction: Icons.turn_slight_right,
  ),
];
const outdoorWaypoints = <Waypoint>[
  Waypoint(
    id: 'faculty_door',
    name: 'Puerta facultad',
    image: 'assets/orientation/waypoints/outdoor_faculty_door.jpg',
    latitude: 37.196972,
    longitude: -3.624286,
    gpsRadiusMeters: 35,
    direction: Icons.turn_slight_right,
  ),
  Waypoint(
    id: 'between_faculty_auxiliary',
    name: 'Lugar entre la puerta de la facultad y el edificio auxiliar',
    image: 'assets/orientation/waypoints/between_faculty_auxiliary.jpg',
    latitude: 37.197418,
    longitude: -3.626194,
    gpsRadiusMeters: 35,
    direction: Icons.arrow_forward,
  ),
  Waypoint(
    id: 'auxiliary_door',
    name: 'Puerta edificio Auxiliar',
    image: 'assets/orientation/waypoints/outdoor_auxiliary_door.jpg',
    latitude: 37.197788,
    longitude: -3.630030,
    gpsRadiusMeters: 35,
    direction: Icons.turn_slight_right,
  ),
];
