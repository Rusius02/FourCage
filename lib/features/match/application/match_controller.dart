import 'package:flutter/foundation.dart';

import '../domain/cage_player.dart';
import '../domain/match_simulation.dart';
import '../domain/vector2.dart';

class MatchController extends ChangeNotifier {
  MatchController({MatchSimulation? simulation})
    : _simulation = simulation ?? MatchSimulation();

  final MatchSimulation _simulation;

  List<CagePlayer> get players => _simulation.players;
  Vector2 get ballPosition => _simulation.ballPosition;
  MatchResult get result => _simulation.result;
  double get elapsedSeconds => _simulation.elapsedSeconds;
  String? get announcement => _simulation.announcement;
  int get humanLives => _simulation.humanLives;
  Vector2 get moveInput => _simulation.moveInput;

  void setMoveInput(Vector2 input) {
    _simulation.setMoveInput(input);
    notifyListeners();
  }

  void shoot() {
    _simulation.shoot();
    notifyListeners();
  }

  void pause() {
    _simulation.pause();
    notifyListeners();
  }

  void resume() {
    _simulation.resume();
    notifyListeners();
  }

  void restart() {
    _simulation.restart();
    notifyListeners();
  }

  void update(double deltaSeconds) {
    if (_simulation.result != MatchResult.playing) return;
    _simulation.update(deltaSeconds);
    notifyListeners();
  }
}
