import 'dart:math' as math;

import 'cage_player.dart';
import 'vector2.dart';

enum MatchResult { playing, paused, won, lost }

class MatchSimulation {
  static const double ballRadius = .018;
  static const double _playerRadius = .034;
  static const double _goalHalfWidth = .105;
  static const int startingLives = 3;

  final List<CagePlayer> players = [
    for (final side in CageSide.values)
      CagePlayer(side: side, isHuman: side == CageSide.south),
  ];

  Vector2 ballPosition = const Vector2(.5, .5);
  Vector2 _ballVelocity = Vector2.zero;
  Vector2 _moveInput = Vector2.zero;
  MatchResult result = MatchResult.playing;
  double elapsedSeconds = 0;
  double _resetTimer = 0;
  String? announcement;
  double _announcementTimer = 0;

  int get humanLives => players[CageSide.south.index].lives;
  Vector2 get moveInput => _moveInput;

  void setMoveInput(Vector2 input) {
    _moveInput = input.length > 1 ? input.normalized() : input;
    if (_moveInput.lengthSquared > .01) {
      players[CageSide.south.index].facing = _moveInput.normalized();
    }
  }

  void shoot() {
    if (result != MatchResult.playing) return;
    final player = players[CageSide.south.index];
    if (player.lives <= 0 ||
        player.kickCooldown > 0 ||
        (ballPosition - player.position).length > .24) {
      return;
    }
    _kickTowardGoal(player);
    player.kickCooldown = .38;
  }

  void pause() {
    if (result != MatchResult.playing) return;
    result = MatchResult.paused;
    _moveInput = Vector2.zero;
  }

  void resume() {
    if (result == MatchResult.paused) result = MatchResult.playing;
  }

  void restart() {
    for (final player in players) {
      player.position = player.home;
      player.lives = startingLives;
      player.kickCooldown = 0;
    }
    ballPosition = const Vector2(.5, .5);
    _ballVelocity = Vector2.zero;
    _moveInput = Vector2.zero;
    elapsedSeconds = 0;
    _resetTimer = 0;
    _announcementTimer = 0;
    announcement = null;
    result = MatchResult.playing;
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
      return;
    }

    for (var index = 0; index < players.length; index++) {
      final player = players[index];
      if (player.lives <= 0) continue;

      final input = player.isHuman ? _moveInput : _botInput(index);
      if (input.lengthSquared > .01) player.facing = input.normalized();
      final speed = player.isHuman ? .36 : .29;
      player.position += input * (speed * delta);
      player.position = Vector2(
        player.position.x.clamp(.065, .935).toDouble(),
        player.position.y.clamp(.065, .935).toDouble(),
      );

      if (!player.isHuman &&
          (ballPosition - player.position).length < .16 &&
          player.kickCooldown == 0) {
        _kickTowardGoal(player);
        player.kickCooldown = 1.15;
      }
    }

    _moveBall(delta);
  }

  Vector2 _botInput(int playerIndex) {
    final player = players[playerIndex];
    if (player.kickCooldown > .7) return Vector2.zero;
    final direction = ballPosition - player.position;
    if (direction.length < .11) return Vector2.zero;
    return direction.normalized();
  }

  void _kickTowardGoal(CagePlayer player) {
    final targetIndex = _nearestOpponent(player);
    if (targetIndex == null) return;
    final direction = players[targetIndex].side.goalCenter - ballPosition;
    if (direction.length == 0) return;
    _ballVelocity = direction.normalized() * .78;
  }

  int? _nearestOpponent(CagePlayer player) {
    final playerIndex = players.indexOf(player);
    int? nearest;
    var bestDistance = double.infinity;
    for (var index = 0; index < players.length; index++) {
      if (index == playerIndex || players[index].lives <= 0) continue;
      final distance = players[index].side.goalCenter.distanceSquaredTo(
        ballPosition,
      );
      if (distance < bestDistance) {
        nearest = index;
        bestDistance = distance;
      }
    }
    return nearest;
  }

  void _moveBall(double delta) {
    ballPosition += _ballVelocity * delta;
    _ballVelocity = _ballVelocity * math.max(0, 1 - 1.25 * delta);

    for (final player in players) {
      if (player.lives <= 0) continue;
      final offset = ballPosition - player.position;
      final distance = offset.length;
      final minDistance = _playerRadius + ballRadius;
      if (distance >= minDistance) continue;
      final direction = distance > 0 ? offset.normalized() : player.facing;
      ballPosition = player.position + direction * minDistance;
      _ballVelocity += direction * .16;
    }

    if (ballPosition.y < ballRadius + .025 &&
        _isGoalOpening(ballPosition.x)) {
      _score(CageSide.north.index);
    } else if (ballPosition.x > 1 - ballRadius - .025 &&
        _isGoalOpening(ballPosition.y)) {
      _score(CageSide.east.index);
    } else if (ballPosition.y > 1 - ballRadius - .025 &&
        _isGoalOpening(ballPosition.x)) {
      _score(CageSide.south.index);
    } else if (ballPosition.x < ballRadius + .025 &&
        _isGoalOpening(ballPosition.y)) {
      _score(CageSide.west.index);
    } else {
      if (ballPosition.x < ballRadius + .025 ||
          ballPosition.x > 1 - ballRadius - .025) {
        _ballVelocity = Vector2(-_ballVelocity.x * .76, _ballVelocity.y);
      }
      if (ballPosition.y < ballRadius + .025 ||
          ballPosition.y > 1 - ballRadius - .025) {
        _ballVelocity = Vector2(_ballVelocity.x, -_ballVelocity.y * .76);
      }
      ballPosition = Vector2(
        ballPosition.x
            .clamp(ballRadius + .025, 1 - ballRadius - .025)
            .toDouble(),
        ballPosition.y
            .clamp(ballRadius + .025, 1 - ballRadius - .025)
            .toDouble(),
      );
    }
  }

  bool _isGoalOpening(double position) =>
      (position - .5).abs() < _goalHalfWidth;

  void _score(int targetIndex) {
    final target = players[targetIndex];
    if (target.lives <= 0) {
      _ballVelocity = Vector2(-_ballVelocity.x, -_ballVelocity.y);
      ballPosition = Vector2(
        ballPosition.x
            .clamp(ballRadius + .025, 1 - ballRadius - .025)
            .toDouble(),
        ballPosition.y
            .clamp(ballRadius + .025, 1 - ballRadius - .025)
            .toDouble(),
      );
      return;
    }

    target.lives--;
    announcement = target.lives == 0
        ? '${target.name} ÉLIMINÉ'
        : 'BUT CONTRE ${target.name}';
    _announcementTimer = 1.5;
    _ballVelocity = Vector2.zero;
    ballPosition = const Vector2(.5, .5);
    _resetTimer = 1.1;

    if (humanLives == 0) {
      result = MatchResult.lost;
    } else if (players
        .where((player) => !player.isHuman && player.lives > 0)
        .isEmpty) {
      result = MatchResult.won;
    }
  }

  void _resetPositions() {
    for (final player in players) {
      if (player.lives > 0) player.position = player.home;
    }
    ballPosition = const Vector2(.5, .5);
    _ballVelocity = Vector2.zero;
  }
}
