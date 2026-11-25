import 'package:flutter/material.dart';

/// Coordinates are normalized against the full, uncropped source image.
@immutable
class MapZone {
  const MapZone({
    required this.id,
    required this.number,
    required this.name,
    required this.description,
    required this.color,
    required this.polygons,
    required this.marker,
    this.holes = const [],
  });

  final String id;
  final int number;
  final String name;

  /// Provisional Spanish copy bundled with the floor catalogue.
  final String description;
  final Color color;
  final List<List<Offset>> polygons;

  /// Interior contours excluded from the fill (e.g. the library atrium).
  final List<List<Offset>> holes;
  final Offset marker;
}
