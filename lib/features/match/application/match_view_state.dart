import 'package:flutter/foundation.dart';

import '../domain/cage_player.dart';
import '../domain/match_simulation.dart';
import '../domain/vector2.dart';

abstract class MatchViewState extends ChangeNotifier {
  List<CagePlayer> get players;
  Vector2 get ballPosition;
  MatchResult get result;
  String? get announcement;
  int get localSlot;
  CageSide get viewSide;
  bool get canPause;
  bool get canRestart;

  void setMoveInput(Vector2 input, {double acceleration = 0});
  void pause();
  void resume();
  void restart();
  void update(double deltaSeconds);
}
