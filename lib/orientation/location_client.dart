import 'package:geolocator/geolocator.dart';

enum FacultyProximity { near, far, unavailable }

typedef LocationFix = ({
  double latitude,
  double longitude,
  double accuracy,
  bool hasAccuracy,
});

class WaypointProximity {
  const WaypointProximity({
    required this.distanceMeters,
    required this.accuracyMeters,
    required this.reached,
  });
  const WaypointProximity.unavailable()
    : distanceMeters = null,
      accuracyMeters = null,
      reached = false;
  final double? distanceMeters;
  final double? accuracyMeters;
  final bool reached;
  bool get isAvailable => distanceMeters != null;
}

class LocationClient {
  LocationClient({Future<LocationFix?> Function()? locate})
    : _locate = locate ?? _deviceLocation;
  final Future<LocationFix?> Function() _locate;
  static const facultyLatitude = 37.197067;
  static const facultyLongitude = -3.624149;
  static const nearThresholdMeters = 750.0;

  static Future<LocationFix?> _deviceLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      hasAccuracy: position.hasAccuracy || position.accuracy > 0,
    );
  }

  bool _valid(LocationFix fix) =>
      fix.latitude.isFinite &&
      fix.longitude.isFinite &&
      fix.latitude >= -90 &&
      fix.latitude <= 90 &&
      fix.longitude >= -180 &&
      fix.longitude <= 180 &&
      fix.hasAccuracy &&
      fix.accuracy.isFinite &&
      fix.accuracy >= 0;

  Future<FacultyProximity> checkFacultyProximity() async {
    try {
      final fix = await _locate();
      if (fix == null || !_valid(fix)) return FacultyProximity.unavailable;
      final distance = Geolocator.distanceBetween(
        fix.latitude,
        fix.longitude,
        facultyLatitude,
        facultyLongitude,
      );
      if (!distance.isFinite) return FacultyProximity.unavailable;
      if (distance + fix.accuracy <= nearThresholdMeters) {
        return FacultyProximity.near;
      }
      if (distance - fix.accuracy > nearThresholdMeters) {
        return FacultyProximity.far;
      }
      return FacultyProximity.unavailable;
    } catch (_) {
      return FacultyProximity.unavailable;
    }
  }

  Future<WaypointProximity> checkWaypointProximity({
    required double? latitude,
    required double? longitude,
    required double radiusMeters,
  }) async {
    if (latitude == null || longitude == null) {
      return const WaypointProximity.unavailable();
    }
    try {
      final fix = await _locate();
      if (fix == null || !_valid(fix)) {
        return const WaypointProximity.unavailable();
      }
      final distance = Geolocator.distanceBetween(
        fix.latitude,
        fix.longitude,
        latitude,
        longitude,
      );
      if (!distance.isFinite) return const WaypointProximity.unavailable();
      return WaypointProximity(
        distanceMeters: distance,
        accuracyMeters: fix.accuracy,
        reached: distance <= radiusMeters,
      );
    } catch (_) {
      return const WaypointProximity.unavailable();
    }
  }
}
