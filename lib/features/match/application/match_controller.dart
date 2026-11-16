import 'package:flutter/foundation.dart';

import '../domain/cage_player.dart';
import '../domain/match_simulation.dart';
import '../domain/vector2.dart';
import 'match_view_state.dart';

class MatchController extends ChangeNotifier implements MatchViewState {
  MatchController({MatchSimulation? simulation})
    : _simulation = simulation ?? MatchSimulation();

  final MatchSimulation _simulation;

  @override
  List<CagePlayer> get players => _simulation.players;
  @override
  Vector2 get ballPosition => _simulation.ballPosition;
  @override
  MatchResult get result => _simulation.result;
  double get elapsedSeconds => _simulation.elapsedSeconds;
  @override
  String? get announcement => _simulation.announcement;
  int get humanLives => _simulation.humanLives;
  Vector2 get moveInput => _simulation.moveInput;
  double get ballSpeed => _simulation.ballSpeed;
  int get ballTouches => _simulation.ballTouches;
  @override
  int get localSlot => CageSide.south.index;
  @override
  CageSide get viewSide => CageSide.south;
  @override
  bool get canPause => true;
  @override
  bool get canRestart => true;

  @override
  void setMoveInput(Vector2 input, {double acceleration = 0}) {
    _simulation.setMoveInput(input, acceleration: acceleration);
    notifyListeners();
  }

  @override
  void pause() {
    _simulation.pause();
    notifyListeners();
  }

  @override
  void resume() {
    _simulation.resume();
    notifyListeners();
  }

  @override
  void restart() {
    _simulation.restart();
    notifyListeners();
  }

  @override
  void update(double deltaSeconds) {
    if (_simulation.result != MatchResult.playing) return;
    _simulation.update(deltaSeconds);
    notifyListeners();
  }
}
