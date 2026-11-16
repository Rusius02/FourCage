import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:four_cage/features/match/application/tilt_movement_controller.dart';
import 'package:four_cage/features/match/infrastructure/accelerometer_tilt_input_source.dart';

void main() {
  test('accelerometer input uses the horizontal axis while in landscape', () async {
    final events = StreamController<AccelerometerEvent>();
    final source = AccelerometerTiltInputSource(events: events.stream);
    final nextTilt = source.horizontalTilt.first;

    events.add(
      AccelerometerEvent(1, -3, 9, DateTime.fromMillisecondsSinceEpoch(0)),
    );

    expect(await nextTilt, -3);
    await events.close();
  });

  test('tilt is calibrated, smoothed, and mapped to horizontal movement', () async {
    final samples = StreamController<double>();
    final movement = TiltMovementController(samples.stream);

    samples.add(2);
    await Future<void>.delayed(Duration.zero);
    expect(movement.horizontalInput, 0);

    samples.add(5);
    await Future<void>.delayed(Duration.zero);
    expect(movement.horizontalInput, greaterThan(0));
    expect(movement.horizontalInput, lessThanOrEqualTo(1));

    samples.add(-2);
    await Future<void>.delayed(Duration.zero);
    expect(movement.horizontalInput, lessThan(0));

    movement.dispose();
    await samples.close();
  });
}
