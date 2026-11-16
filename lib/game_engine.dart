import 'dart:math' as math;

import 'package:flutter/material.dart';

enum MatchResult { playing, paused, won, lost }

class CagePlayer {
  CagePlayer({
    required this.name,
    required this.color,
    required this.position,
    required this.home,
    required this.isHuman,
  });

  final String name;
  final Color color;
  final Offset home;
  final bool isHuman;
  Offset position;
  Offset facing = const Offset(0, -1);
  int lives = 3;
  double kickCooldown = 0;
}

class GameEngine extends ChangeNotifier {
  static const double _ballRadius = .018;
  static const double _playerRadius = .034;
  static const double _goalHalfWidth = .105;

  final List<CagePlayer> players = [
    CagePlayer(
      name: 'NOVA',
      color: const Color(0xFFFF6B6B),
      position: const Offset(.5, .23),
      home: const Offset(.5, .23),
      isHuman: false,
    ),
    CagePlayer(
      name: 'ECHO',
      color: const Color(0xFFB88CFF),
      position: const Offset(.77, .5),
      home: const Offset(.77, .5),
      isHuman: false,
    ),
    CagePlayer(
      name: 'TOI',
      color: const Color(0xFF51E6C2),
      position: const Offset(.5, .77),
      home: const Offset(.5, .77),
      isHuman: true,
    ),
    CagePlayer(
      name: 'PIXEL',
      color: const Color(0xFFFFD166),
      position: const Offset(.23, .5),
      home: const Offset(.23, .5),
      isHuman: false,
    ),
  ];

  Offset ballPosition = const Offset(.5, .5);
  Offset _ballVelocity = Offset.zero;
  Offset _moveInput = Offset.zero;
  MatchResult result = MatchResult.playing;
  double elapsedSeconds = 0;
  double _resetTimer = 0;
  String? announcement;
  double _announcementTimer = 0;

  int get humanLives => players[2].lives;
  Offset get moveInput => _moveInput;

  void setMoveInput(Offset input) {
    final length = input.distance;
    _moveInput = length > 1 ? input / length : input;
    if (_moveInput.distanceSquared > .01) {
      players[2].facing = _moveInput / _moveInput.distance;
    }
    notifyListeners();
  }

  void shoot() {
    if (result != MatchResult.playing) return;
    final player = players[2];
    if (player.lives <= 0 ||
        player.kickCooldown > 0 ||
        (ballPosition - player.position).distance > .24) {
      return;
    }
    _kickTowardGoal(player);
    player.kickCooldown = .38;
    notifyListeners();
  }

  void pause() {
    if (result == MatchResult.playing) {
      result = MatchResult.paused;
      _moveInput = Offset.zero;
      notifyListeners();
    }
  }

  void resume() {
    if (result == MatchResult.paused) {
      result = MatchResult.playing;
      notifyListeners();
    }
  }

  void restart() {
    for (final player in players) {
      player.position = player.home;
      player.lives = 3;
      player.kickCooldown = 0;
    }
    ballPosition = const Offset(.5, .5);
    _ballVelocity = Offset.zero;
    _moveInput = Offset.zero;
    elapsedSeconds = 0;
    _resetTimer = 0;
    _announcementTimer = 0;
    announcement = null;
    result = MatchResult.playing;
    notifyListeners();
  }

  void update(double deltaSeconds) {
    if (result != MatchResult.playing) return;
    final delta = deltaSeconds.clamp(0, .05).toDouble();
    elapsedSeconds += delta;
    _announcementTimer = math.max(0, _announcementTimer - delta);
    if (_announcementTimer == 0) announcement = null;

    for (final player in players) {
      player.kickCooldown = math.max(0, player.kickCooldown - delta);
    }

    if (_resetTimer > 0) {
      _resetTimer = math.max(0, _resetTimer - delta);
      if (_resetTimer == 0) _resetPositions();
      notifyListeners();
      return;
    }

    for (var index = 0; index < players.length; index++) {
      final player = players[index];
      if (player.lives <= 0) continue;

      final input = player.isHuman ? _moveInput : _botInput(index);
      if (input.distanceSquared > .01) {
        player.facing = input / input.distance;
      }
      final speed = player.isHuman ? .36 : .29;
      player.position += input * (speed * delta);
      player.position = Offset(
        player.position.dx.clamp(.065, .935).toDouble(),
        player.position.dy.clamp(.065, .935).toDouble(),
      );

      if (!player.isHuman &&
          (ballPosition - player.position).distance < .16 &&
          player.kickCooldown == 0) {
        _kickTowardGoal(player);
        player.kickCooldown = 1.15;
      }
    }

    _moveBall(delta);
    notifyListeners();
  }

  Offset _botInput(int playerIndex) {
    final player = players[playerIndex];
    if (player.kickCooldown > .7) return Offset.zero;
    final direction = ballPosition - player.position;
    if (direction.distance < .11) return Offset.zero;
    return direction / direction.distance;
  }

  void _kickTowardGoal(CagePlayer player) {
    final targetIndex = _nearestOpponent(player);
    if (targetIndex == null) return;
    final goal = _goalCenter(targetIndex);
    final direction = goal - ballPosition;
    if (direction.distance == 0) return;
    _ballVelocity = direction / direction.distance * .78;
  }

  int? _nearestOpponent(CagePlayer player) {
    final playerIndex = players.indexOf(player);
    int? nearest;
    var bestDistance = double.infinity;
    for (var index = 0; index < players.length; index++) {
      if (index == playerIndex || players[index].lives <= 0) continue;
      final distance = (_goalCenter(index) - ballPosition).distanceSquared;
      if (distance < bestDistance) {
        nearest = index;
        bestDistance = distance;
      }
    }
    return nearest;
  }

  Offset _goalCenter(int index) => switch (index) {
    0 => const Offset(.5, .035),
    1 => const Offset(.965, .5),
    2 => const Offset(.5, .965),
    _ => const Offset(.035, .5),
  };

  void _moveBall(double delta) {
    ballPosition += _ballVelocity * delta;
    _ballVelocity *= math.max(0, 1 - 1.25 * delta);

    for (final player in players) {
      if (player.lives <= 0) continue;
      final offset = ballPosition - player.position;
      final distance = offset.distance;
      final minDistance = _playerRadius + _ballRadius;
      if (distance >= minDistance) continue;
      final direction = distance > 0 ? offset / distance : player.facing;
      ballPosition = player.position + direction * minDistance;
      _ballVelocity += direction * .16;
    }

    if (ballPosition.dy < _ballRadius + .025 &&
        _isGoalOpening(ballPosition.dx)) {
      _score(0);
    } else if (ballPosition.dx > 1 - _ballRadius - .025 &&
        _isGoalOpening(ballPosition.dy)) {
      _score(1);
    } else if (ballPosition.dy > 1 - _ballRadius - .025 &&
        _isGoalOpening(ballPosition.dx)) {
      _score(2);
    } else if (ballPosition.dx < _ballRadius + .025 &&
        _isGoalOpening(ballPosition.dy)) {
      _score(3);
    } else {
      if (ballPosition.dx < _ballRadius + .025 ||
          ballPosition.dx > 1 - _ballRadius - .025) {
        _ballVelocity = Offset(-_ballVelocity.dx * .76, _ballVelocity.dy);
      }
      if (ballPosition.dy < _ballRadius + .025 ||
          ballPosition.dy > 1 - _ballRadius - .025) {
        _ballVelocity = Offset(_ballVelocity.dx, -_ballVelocity.dy * .76);
      }
      ballPosition = Offset(
        ballPosition.dx.clamp(_ballRadius + .025, 1 - _ballRadius - .025),
        ballPosition.dy.clamp(_ballRadius + .025, 1 - _ballRadius - .025),
      );
    }
  }

  bool _isGoalOpening(double position) =>
      (position - .5).abs() < _goalHalfWidth;

  void _score(int targetIndex) {
    final target = players[targetIndex];
    if (target.lives <= 0) {
      _ballVelocity = Offset(-_ballVelocity.dx, -_ballVelocity.dy);
      ballPosition = Offset(
        ballPosition.dx
            .clamp(_ballRadius + .025, 1 - _ballRadius - .025)
            .toDouble(),
        ballPosition.dy
            .clamp(_ballRadius + .025, 1 - _ballRadius - .025)
            .toDouble(),
      );
      return;
    }
    target.lives--;
    announcement = target.lives == 0
        ? '${target.name} ÉLIMINÉ'
        : 'BUT CONTRE ${target.name}';
    _announcementTimer = 1.5;
    _ballVelocity = Offset.zero;
    ballPosition = const Offset(.5, .5);
    _resetTimer = 1.1;

    if (players[2].lives == 0) {
      result = MatchResult.lost;
    } else if (players
        .asMap()
        .entries
        .where((entry) => entry.key != 2 && entry.value.lives > 0)
        .isEmpty) {
      result = MatchResult.won;
    }
  }

  void _resetPositions() {
    for (final player in players) {
      if (player.lives > 0) player.position = player.home;
    }
    ballPosition = const Offset(.5, .5);
    _ballVelocity = Offset.zero;
  }
}
