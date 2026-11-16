import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/cage_player.dart';
import '../domain/match_simulation.dart';
import '../domain/vector2.dart';
import '../infrastructure/online_match_session.dart';
import 'match_view_state.dart';

class OnlineMatchController extends ChangeNotifier implements MatchViewState {
  OnlineMatchController(this._session) {
    _session.addListener(_syncFromServer);
    _syncFromServer();
  }

  final OnlineMatchSession _session;
  final Stopwatch _interpolationClock = Stopwatch()..start();
  static const _interpolationDuration = Duration(milliseconds: 34);

  List<CagePlayer> _players = [];
  List<Vector2> _fromPlayerPositions = [];
  List<Vector2> _targetPlayerPositions = [];
  Vector2 _ballPosition = const Vector2(.5, .5);
  Vector2 _fromBallPosition = const Vector2(.5, .5);
  Vector2 _targetBallPosition = const Vector2(.5, .5);
  String? _announcement;
  MatchResult _result = MatchResult.playing;

  @override
  List<CagePlayer> get players => _players;
  @override
  Vector2 get ballPosition => _ballPosition;
  @override
  MatchResult get result => _result;
  @override
  String? get announcement => _announcement;
  @override
  int get localSlot => _session.localSlot ?? CageSide.south.index;
  @override
  CageSide get viewSide => CageSide.values[localSlot];
  @override
  bool get canPause => false;
  @override
  bool get canRestart => false;

  @override
  void setMoveInput(Vector2 input, {double acceleration = 0}) {
    _session.sendInput(input.x, acceleration);
  }

  @override
  void pause() {}

  @override
  void resume() {}

  @override
  void restart() {}

  @override
  void update(double deltaSeconds) {
    if (_players.isEmpty) return;
    final alpha = math.min(
      1.0,
      _interpolationClock.elapsedMicroseconds /
          _interpolationDuration.inMicroseconds,
    );
    for (var index = 0; index < _players.length; index++) {
      final from = _fromPlayerPositions[index];
      final target = _targetPlayerPositions[index];
      _players[index].position = Vector2(
        from.x + (target.x - from.x) * alpha,
        from.y + (target.y - from.y) * alpha,
      );
    }
    _ballPosition = Vector2(
      _fromBallPosition.x +
          (_targetBallPosition.x - _fromBallPosition.x) * alpha,
      _fromBallPosition.y +
          (_targetBallPosition.y - _fromBallPosition.y) * alpha,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _session.removeListener(_syncFromServer);
    super.dispose();
  }

  void _syncFromServer() {
    if (_session.localSlot == null || _session.players.isEmpty) return;
    if (_players.isEmpty) {
      _players = [
        for (final side in CageSide.values)
          CagePlayer(
            side: side,
            isHuman: side.index == _session.localSlot,
            isBot: true,
          ),
      ];
      _fromPlayerPositions = [for (final player in _players) player.position];
      _targetPlayerPositions = List<Vector2>.from(_fromPlayerPositions);
    }

    _fromBallPosition = _ballPosition;
    _targetBallPosition = Vector2(_session.ballX, _session.ballY);
    _fromPlayerPositions = [
      for (final player in _players) player.position,
    ];
    final playerTargets = List<Vector2>.from(_fromPlayerPositions);

    for (final snapshot in _session.players) {
      if (snapshot.slot < 0 || snapshot.slot >= _players.length) continue;
      final player = _players[snapshot.slot];
      player
        ..lives = snapshot.lives
        ..isBot = snapshot.isBot;
      playerTargets[snapshot.slot] = Vector2(snapshot.x, snapshot.y);
    }

    _targetPlayerPositions = playerTargets;
    _announcement = _session.announcement.isEmpty
        ? null
        : _session.announcement;
    _result = switch (_session.phase) {
      'finished' =>
        _session.winnerSlot == _session.localSlot
            ? MatchResult.won
            : MatchResult.lost,
      _ => MatchResult.playing,
    };
    _interpolationClock
      ..reset()
      ..start();
    notifyListeners();
  }
}
