import 'dart:async';

import 'package:flutter/foundation.dart';

abstract interface class TiltInputSource {
  Stream<double> get horizontalTilt;
}

class TiltMovementController extends ChangeNotifier {
  TiltMovementController(Stream<double> tiltSamples) {
    _subscription = tiltSamples.listen(
      _updateTilt,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Accelerometer input is unavailable: $error');
      },
    );
  }

  static const double _deadZone = .8;
  static const double _fullTilt = 4.5;
  static const double _smoothing = .35;

  late final StreamSubscription<double> _subscription;
  double? _neutralPosition;
  double _horizontalInput = 0;

  double get horizontalInput => _horizontalInput;

  void _updateTilt(double sample) {
    if (!sample.isFinite) return;
    _neutralPosition ??= sample;

    final displacement = sample - _neutralPosition!;
    final magnitude = displacement.abs();
    final target = magnitude <= _deadZone
        ? 0.0
        : ((magnitude - _deadZone) / (_fullTilt - _deadZone))
                  .clamp(0, 1)
                  .toDouble() *
              displacement.sign;

    _horizontalInput += (target - _horizontalInput) * _smoothing;
    if (_horizontalInput.abs() < .015) _horizontalInput = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
