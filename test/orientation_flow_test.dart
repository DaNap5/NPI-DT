import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:npi/orientation/directions_flow_view_model.dart';
import 'package:npi/orientation/location_client.dart';
import 'package:npi/orientation/data/routes.dart';

void main() {
  test('late location reply is ignored after back or disposal', () async {
    final reply = Completer<LocationFix?>();
    final vm = DirectionsFlowViewModel(
      locationClient: LocationClient(locate: () => reply.future),
    );
    vm.chooseDestinationArea(inside: true);
    vm.chooseFacultyEntrance();
    final check = vm.checkLocation();
    vm.goBack();
    expect(vm.stage, DirectionsStage.insideDestinations);
    reply.complete((
      latitude: LocationClient.facultyLatitude,
      longitude: LocationClient.facultyLongitude,
      accuracy: 5.0,
      hasAccuracy: true,
    ));
    await check;
    expect(vm.stage, DirectionsStage.insideDestinations);
    vm.dispose();

    final late = Completer<LocationFix?>();
    final disposed = DirectionsFlowViewModel(
      locationClient: LocationClient(locate: () => late.future),
      initialDestination: DirectionsDestination.facultyEntrance,
    );
    final load = disposed.checkLocation();
    disposed.dispose();
    late.complete(null);
    await load;
  });

  test(
    'unavailable location keeps manual and combined-route progression',
    () async {
      final vm = DirectionsFlowViewModel(
        locationClient: LocationClient(locate: () async => null),
      );
      addTearDown(vm.dispose);
      vm.chooseDestinationArea(inside: false);
      vm.chooseAuxiliaryBuilding();
      await vm.checkLocation();
      expect(vm.stage, DirectionsStage.locationUnavailable);
      vm.chooseManualLocation(near: true);
      vm.startGuideFromClassroom();
      expect(vm.route, DirectionsRoute.combined);
      expect(vm.waypoints, hasLength(5));
      expect(
        vm.waypoints.where((point) => point.id == 'faculty_door'),
        hasLength(1),
      );
      vm.nextWaypoint();
      vm.nextWaypoint();
      expect(vm.waypoints[vm.waypointIndex].id, 'faculty_door');
      vm.nextWaypoint();
      expect(vm.waypoints[vm.waypointIndex].id, outdoorWaypoints[1].id);
      vm.previousWaypoint();
      expect(vm.waypoints[vm.waypointIndex].id, 'faculty_door');
    },
  );

  testWidgets('GPS arrival prompts once and never blocks manual navigation', (
    tester,
  ) async {
    var location = outdoorWaypoints[1];
    final vm = DirectionsFlowViewModel(
      locationClient: LocationClient(
        locate: () async => (
          latitude: location.latitude!,
          longitude: location.longitude!,
          accuracy: 5.0,
          hasAccuracy: true,
        ),
      ),
    );
    vm.chooseAuxiliaryBuilding();
    vm.startGuideFromEntrance();
    await tester.pump();
    final target = vm.takePendingArrivalPrompt();
    expect(target, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(vm.takePendingArrivalPrompt(), isNull);
    expect(vm.waypointIndex, 0);
    expect(vm.confirmArrival(target!), isFalse);
    expect(vm.waypointIndex, 1);
    location = outdoorWaypoints.last;
    await tester.pump(const Duration(seconds: 3));
    final last = vm.takePendingArrivalPrompt();
    expect(last, 2);
    vm.confirmArrival(last!);
    expect(vm.waypointIndex, 2);
    await tester.pump(const Duration(seconds: 3));
    expect(vm.takePendingArrivalPrompt(), isNull);
    vm.dispose();
  });

  test(
    'accuracy overlapping near/far boundary requires manual selection',
    () async {
      final client = LocationClient(
        locate: () async => (
          latitude: LocationClient.facultyLatitude,
          longitude: LocationClient.facultyLongitude,
          accuracy: 800.0,
          hasAccuracy: true,
        ),
      );
      expect(
        await client.checkFacultyProximity(),
        FacultyProximity.unavailable,
      );
      final invalid = LocationClient(
        locate: () async =>
            (latitude: 200.0, longitude: 0.0, accuracy: 1.0, hasAccuracy: true),
      );
      expect(
        await invalid.checkFacultyProximity(),
        FacultyProximity.unavailable,
      );
      final unavailable = LocationClient(
        locate: () async => throw StateError('Location disabled'),
      );
      expect(
        await unavailable.checkFacultyProximity(),
        FacultyProximity.unavailable,
      );
    },
  );
}
