import 'package:flutter/material.dart';

class Waypoint {
  const Waypoint({
    required this.id,
    required this.name,
    required this.image,
    this.latitude,
    this.longitude,
    this.gpsRadiusMeters = 20,
    this.direction = Icons.arrow_upward,
  });

  final String id;
  final String name;
  final String image;
  final double? latitude;
  final double? longitude;
  final double gpsRadiusMeters;
  final IconData direction;

  bool get hasGpsCoordinates => latitude != null && longitude != null;
}
