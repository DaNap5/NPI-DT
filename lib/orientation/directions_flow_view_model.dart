import 'data/routes.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:npi/orientation/location_client.dart';
import 'package:npi/orientation/waypoint.dart';

enum DirectionsStage {
  destinationArea,
  insideDestinations,
  outsideDestinations,
  entranceChoice,
  checkingLocation,
  locationUnavailable,
  farFromFaculty,
  suggestedOrigin,
  originMethod,
  waypointGuide,
}

enum DirectionsDestination { facultyEntrance, auxiliaryBuilding }

enum DirectionsRoute { indoor, outdoor, combined }

class DirectionsFlowViewModel extends ChangeNotifier {
  DirectionsFlowViewModel({
    required this._locationClient,
    DirectionsDestination? initialDestination,
  }) : _destination = initialDestination;

  final LocationClient _locationClient;
  int _locationRequestId = 0;
  bool _disposed = false;
  DirectionsStage _stage = DirectionsStage.destinationArea;
  DirectionsDestination? _destination;
  DirectionsRoute? _route;
  int _waypointIndex = 0;
  final List<DirectionsStage> _history = [];
  Timer? _waypointTimer;
  int _waypointRequestId = 0;
  bool _waypointRequestInFlight = false;
  double? _waypointDistanceMeters;
  bool _waypointReached = false;
  bool _waypointLocationUnavailable = false;
  final Set<int> _promptedWaypointIndices = {};
  int? _pendingArrivalWaypointIndex;

  DirectionsStage get stage => _stage;
  DirectionsDestination? get destination => _destination;
  DirectionsRoute? get route => _route;
  int get waypointIndex => _waypointIndex;
  double? get waypointDistanceMeters => _waypointDistanceMeters;
  bool get waypointReached => _waypointReached;
  bool get waypointLocationUnavailable => _waypointLocationUnavailable;
  int? get pendingArrivalWaypointIndex => _pendingArrivalWaypointIndex;
  List<Waypoint> get waypoints => switch (_route) {
    DirectionsRoute.indoor => indoorWaypoints,
    DirectionsRoute.outdoor => outdoorWaypoints,
    DirectionsRoute.combined => [
      ...indoorWaypoints,
      ...outdoorWaypoints.skip(1),
    ],
    null => const [],
  };
  bool get canGoBack => _history.isNotEmpty;

  bool get usesAutomaticWaypointValidation =>
      _route == DirectionsRoute.outdoor ||
      (_route == DirectionsRoute.combined &&
          _waypointIndex >= indoorWaypoints.length);

  int get _trackedWaypointIndex {
    if (_waypointIndex < waypoints.length - 1) return _waypointIndex + 1;
    return _waypointIndex;
  }

  String? get trackedWaypointName =>
      usesAutomaticWaypointValidation && waypoints.isNotEmpty
      ? waypoints[_trackedWaypointIndex].name
      : null;

  void chooseDestinationArea({required bool inside}) {
    _destination = null;
    _advance(
      inside
          ? DirectionsStage.insideDestinations
          : DirectionsStage.outsideDestinations,
    );
  }

  void chooseFacultyEntrance() {
    _destination = DirectionsDestination.facultyEntrance;
  }

  void chooseAuxiliaryBuilding() {
    _destination = DirectionsDestination.auxiliaryBuilding;
    _advance(DirectionsStage.entranceChoice);
  }

  Future<void> checkLocation() async {
    if (_destination == null || _stage == DirectionsStage.checkingLocation) {
      return;
    }
    final requestId = ++_locationRequestId;
    _advance(DirectionsStage.checkingLocation);
    final proximity = await _locationClient.checkFacultyProximity();
    if (_disposed ||
        requestId != _locationRequestId ||
        _stage != DirectionsStage.checkingLocation) {
      return;
    }
    _advance(switch (proximity) {
      FacultyProximity.near => DirectionsStage.suggestedOrigin,
      FacultyProximity.far => DirectionsStage.farFromFaculty,
      FacultyProximity.unavailable => DirectionsStage.locationUnavailable,
    });
  }

  void chooseManualLocation({required bool near}) {
    _advance(
      near ? DirectionsStage.suggestedOrigin : DirectionsStage.farFromFaculty,
    );
  }

  void chooseOriginMethod() => _advance(DirectionsStage.originMethod);

  void startGuideFromClassroom() {
    final route = switch (_destination) {
      DirectionsDestination.facultyEntrance => DirectionsRoute.indoor,
      DirectionsDestination.auxiliaryBuilding => DirectionsRoute.combined,
      null => null,
    };
    if (route == null) return;
    _startGuide(route);
  }

  void startGuideFromEntrance() {
    if (_destination != DirectionsDestination.auxiliaryBuilding) return;
    _startGuide(DirectionsRoute.outdoor);
  }

  void nextWaypoint() {
    if (_stage != DirectionsStage.waypointGuide ||
        _waypointIndex >= waypoints.length - 1) {
      return;
    }
    _waypointIndex++;
    _startWaypointTracking();
    notifyListeners();
  }

  void previousWaypoint() {
    if (_stage != DirectionsStage.waypointGuide || _waypointIndex == 0) return;
    _waypointIndex--;
    _startWaypointTracking();
    notifyListeners();
  }

  int? takePendingArrivalPrompt() {
    final target = _pendingArrivalWaypointIndex;
    _pendingArrivalWaypointIndex = null;
    return target;
  }

  bool confirmArrival(int targetWaypointIndex) {
    if (_stage != DirectionsStage.waypointGuide ||
        !usesAutomaticWaypointValidation ||
        _trackedWaypointIndex != targetWaypointIndex) {
      return false;
    }
    if (_waypointIndex == waypoints.length - 1) return true;
    nextWaypoint();
    return false;
  }

  void goBack() {
    if (_history.isEmpty) return;
    if (_stage == DirectionsStage.checkingLocation) _locationRequestId++;
    if (_stage == DirectionsStage.waypointGuide) {
      _waypointTimer?.cancel();
      _waypointRequestId++;
      _pendingArrivalWaypointIndex = null;
      _route = null;
      _waypointIndex = 0;
    }
    _stage = _history.removeLast();
    if (_stage == DirectionsStage.checkingLocation && _history.isNotEmpty) {
      _locationRequestId++;
      _stage = _history.removeLast();
    }
    if (_stage == DirectionsStage.destinationArea) _destination = null;
    notifyListeners();
  }

  void _startGuide(DirectionsRoute route) {
    _route = route;
    _waypointIndex = 0;
    _promptedWaypointIndices.clear();
    _pendingArrivalWaypointIndex = null;
    _advance(DirectionsStage.waypointGuide);
    _startWaypointTracking();
  }

  void _startWaypointTracking() {
    _waypointTimer?.cancel();
    _waypointTimer = null;
    _waypointRequestId++;
    _waypointRequestInFlight = false;
    _pendingArrivalWaypointIndex = null;
    _waypointDistanceMeters = null;
    _waypointReached = false;
    _waypointLocationUnavailable = false;
    if (!usesAutomaticWaypointValidation) {
      notifyListeners();
      return;
    }
    _checkWaypointLocation();
    _waypointTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkWaypointLocation(),
    );
  }

  Future<void> _checkWaypointLocation() async {
    if (_disposed ||
        _stage != DirectionsStage.waypointGuide ||
        !usesAutomaticWaypointValidation ||
        _waypointRequestInFlight) {
      return;
    }
    final requestId = ++_waypointRequestId;
    _waypointRequestInFlight = true;
    WaypointProximity result;
    try {
      result = await _locationClient.checkWaypointProximity(
        latitude: waypoints[_trackedWaypointIndex].latitude,
        longitude: waypoints[_trackedWaypointIndex].longitude,
        radiusMeters: waypoints[_trackedWaypointIndex].gpsRadiusMeters,
      );
    } catch (_) {
      result = const WaypointProximity.unavailable();
    }
    if (requestId == _waypointRequestId) _waypointRequestInFlight = false;
    if (_disposed ||
        requestId != _waypointRequestId ||
        _stage != DirectionsStage.waypointGuide) {
      return;
    }
    _waypointDistanceMeters = result.distanceMeters;
    _waypointReached = result.reached;
    _waypointLocationUnavailable = !result.isAvailable;
    if (result.reached && _promptedWaypointIndices.add(_trackedWaypointIndex)) {
      _pendingArrivalWaypointIndex = _trackedWaypointIndex;
    }
    notifyListeners();
  }

  void _advance(DirectionsStage next) {
    _history.add(_stage);
    _stage = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _locationRequestId++;
    _waypointRequestId++;
    _waypointTimer?.cancel();
    super.dispose();
  }
}
