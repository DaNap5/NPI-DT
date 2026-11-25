import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:npi/input/floor_motion_input.dart';
import 'package:npi/input/process_floor_motion.dart';
import 'package:npi/input/floor_motion.dart';
import 'package:npi/input/calibrate_floor_motion.dart';
import 'package:npi/input/tilt_gesture.dart';
import 'package:npi/orientation/faculty_map_view_model.dart';

void main() {
  test('tilt quick return commits; slow return cancels', () {
    final gesture = TiltGesture();
    gesture.update(0.8, 0.016);
    expect(gesture.progress, 1);
    gesture.update(0.5, 0.05);
    gesture.update(0.1, 0.05);
    expect(gesture.action, TiltAction.save);
    gesture.reset();
    gesture.update(-0.8, 0.016);
    gesture.update(-0.5, 0.15);
    gesture.update(-0.1, 0.15);
    expect(gesture.action, TiltAction.none);
    gesture.reset();
    gesture.update(-0.8, 0.016);
    gesture.update(0, 0.05);
    expect(gesture.action, TiltAction.discard);
  });

  test('floor detection retains direction and excessive-motion rejection', () {
    final detector = ProcessFloorMotion();
    expect(detector.execute(accelerationZ: 5, gyroX: 3).$1, FloorMotion.up);
    expect(detector.execute(accelerationZ: 5, gyroX: -3).$1, FloorMotion.down);
    expect(
      detector.execute(accelerationZ: 20, gyroX: 3).$2,
      FloorMotionError.excessiveMotion,
    );
    expect(
      CalibrateFloorMotion().execute(
        restGyroSamples: [],
        restAccelSamples: [],
        upGyroPeaks: [],
        downGyroPeaks: [],
        accelPeaks: [],
      ),
      isNull,
    );
  });

  testWidgets('floor capture only starts explicitly and stops all callbacks', (
    tester,
  ) async {
    final acceleration = StreamController<double>.broadcast(sync: true);
    final gyro = StreamController<double>.broadcast(sync: true);
    var up = 0;
    final input = FloorMotionInput(
      onUp: () => up++,
      onDown: () {},
      accelerationValues: acceleration.stream,
      gyroValues: gyro.stream,
    );
    expect(acceleration.hasListener, isFalse);
    input.start();
    acceleration.add(0);
    gyro.add(0);
    await tester.pump(const Duration(milliseconds: 150));
    acceleration.add(5);
    gyro.add(3);
    expect(up, 1);
    input.stop();
    acceleration.add(5);
    gyro.add(3);
    await tester.pump(const Duration(seconds: 3));
    expect(up, 1);
    expect(acceleration.hasListener, isFalse);
    input.dispose();
    await acceleration.close();
    await gyro.close();
  });

  testWidgets(
    'map can change floors without creating a sensor and respects bounds',
    (tester) async {
      final vm = FacultyMapViewModel(initialFloorIndex: 6);
      vm.nextFloor();
      expect(vm.floorIndex, 6);
      expect(vm.feedbackMessage, 'Ya estás en la última planta.');
      vm.setFloor(0);
      vm.previousFloor();
      expect(vm.floorIndex, 0);
      vm.nextFloor();
      expect(vm.floorIndex, 1);
      vm.dispose();
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
