import '../map_zone.dart';
import 'ground_floor_zones.dart';
import 'basement_zones.dart';
import 'fifth_floor_zones.dart';
import 'first_floor_zones.dart';
import 'fourth_floor_zones.dart';
import 'second_floor_zones.dart';
import 'third_floor_zones.dart';

/// Ordered levels share the same framing, so the viewport can remain fixed.
const orientationFloors = <({String name, String asset, List<MapZone> zones})>[
  (name: 'Sótano', asset: 'SotanoSola.jpg', zones: basementZones),
  (name: 'Baja', asset: 'BajaSola.jpg', zones: groundFloorZones),
  (name: 'Primera', asset: 'PrimeraSola.jpg', zones: firstFloorZones),
  (name: 'Segunda', asset: 'SegundaSola.jpg', zones: secondFloorZones),
  (name: 'Tercera', asset: 'TerceraSola.jpg', zones: thirdFloorZones),
  (name: 'Cuarta', asset: 'CuartaSola.jpg', zones: fourthFloorZones),
  (name: 'Quinta', asset: 'QuintaSola.jpg', zones: fifthFloorZones),
];
