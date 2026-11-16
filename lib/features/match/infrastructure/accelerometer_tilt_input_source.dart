import 'package:sensors_plus/sensors_plus.dart';

import '../application/tilt_movement_controller.dart';

class AccelerometerTiltInputSource implements TiltInputSource {
  const AccelerometerTiltInputSource({Stream<AccelerometerEvent>? events})
    : _events = events;

  final Stream<AccelerometerEvent>? _events;

  @override
  Stream<double> get horizontalTilt =>
      (_events ??
              accelerometerEventStream(
                samplingPeriod: const Duration(milliseconds: 20),
              ))
          .map((event) => event.y);
}
