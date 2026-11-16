import 'dart:math' as math;

import 'cage_player.dart';
import 'vector2.dart';

enum MatchResult { playing, paused, won, lost }

class MatchSimulation {
  static const double ballRadius = .018;
  static const double _playerRadius = .034;
  static const double _goalHalfWidth = .19;
  static const double _goalLine = .043;
  static const double _goalkeeperMinimum = .5 - _goalHalfWidth + _playerRadius;
  static const double _goalkeeperMaximum = .5 + _goalHalfWidth - _playerRadius;
  static const double _humanSpeed = .42;
  static const double _botSpeed = .3;
  static const double _collisionAcceleration = 1.12;
  static const double _baseBallSpeed = .52;
  static const double _maximumTravelPerStep = .012;
  static const Vector2 _kickoffVelocity = Vector2(.34, .42);
  static const int startingLives = 3;

  final List<CagePlayer> players = [
    for (final side in CageSide.values)
      CagePlayer(side: side, isHuman: side == CageSide.south),
  ];

  Vector2 ballPosition = const Vector2(.5, .5);
  Vector2 _ballVelocity = _kickoffVelocity;
  Vector2 _moveInput = Vector2.zero;
  double _movementBoost = 0;
  MatchResult result = MatchResult.playing;
  double elapsedSeconds = 0;
  double _resetTimer = 0;
  String? announcement;
  double _announcementTimer = 0;
  int ballTouches = 0;

  int get humanLives => players[CageSide.south.index].lives;
  Vector2 get moveInput => _moveInput;
  double get ballSpeed => _ballVelocity.length;

  void setMoveInput(Vector2 input, {double acceleration = 0}) {
    final player = players[CageSide.south.index];
    _moveInput = player.side.movesHorizontally
        ? Vector2(input.x.clamp(-1, 1).toDouble(), 0)
        : Vector2(0, input.y.clamp(-1, 1).toDouble());
    _movementBoost = acceleration.clamp(0, 1).toDouble();
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
    }
    ballPosition = const Vector2(.5, .5);
    _ballVelocity = _kickoffVelocity;
    _moveInput = Vector2.zero;
    _movementBoost = 0;
    elapsedSeconds = 0;
    _resetTimer = 0;
    _announcementTimer = 0;
    announcement = null;
    ballTouches = 0;
    result = MatchResult.playing;
  }

  void update(double deltaSeconds) {
    if (result != MatchResult.playing) return;
    final delta = deltaSeconds.clamp(0, .05).toDouble();
    elapsedSeconds += delta;
    _announcementTimer = math.max(0, _announcementTimer - delta);
    if (_announcementTimer == 0) announcement = null;

    if (_resetTimer > 0) {
      _resetTimer = math.max(0, _resetTimer - delta);
      if (_resetTimer == 0) _resetPositions();
      return;
    }

    final fastestSpeed = math.max(
      _ballVelocity.length,
      _humanSpeed * (1 + .75 * _movementBoost),
    );
    final steps = math.max(
      1,
      (fastestSpeed * delta / _maximumTravelPerStep).ceil(),
    );
    final stepDuration = delta / steps;

    for (var step = 0; step < steps; step++) {
      _movePlayers(stepDuration);
      _moveBall(stepDuration);
      if (result != MatchResult.playing || _resetTimer > 0) break;
    }
  }

  void _movePlayers(double delta) {
    for (var index = 0; index < players.length; index++) {
      final player = players[index];
      if (player.lives <= 0) continue;

      final input = player.isHuman ? _moveInput : _botInput(player);
      final speed = player.isHuman
          ? _humanSpeed * (1 + .75 * _movementBoost)
          : _botSpeed;
      if (player.side.movesHorizontally) {
        player.position = Vector2(
          (player.position.x + input.x * speed * delta)
              .clamp(_goalkeeperMinimum, _goalkeeperMaximum)
              .toDouble(),
          player.home.y,
        );
      } else {
        player.position = Vector2(
          player.home.x,
          (player.position.y + input.y * speed * delta)
              .clamp(_goalkeeperMinimum, _goalkeeperMaximum)
              .toDouble(),
        );
      }
    }
  }

  Vector2 _botInput(CagePlayer player) {
    if (player.side.movesHorizontally) {
      final difference = ballPosition.x - player.position.x;
      return Vector2(difference.abs() < .01 ? 0 : difference.sign, 0);
    }
    final difference = ballPosition.y - player.position.y;
    return Vector2(0, difference.abs() < .01 ? 0 : difference.sign);
  }

  void _moveBall(double delta) {
    ballPosition += _ballVelocity * delta;

    for (final player in players) {
      if (player.lives <= 0) continue;
      final offset = ballPosition - player.position;
      final distance = offset.length;
      final minimumDistance = _playerRadius + ballRadius;
      if (distance >= minimumDistance) continue;

      final normal = distance > 0 ? offset / distance : player.facing;
      ballPosition = player.position + normal * minimumDistance;
      _onPlayerCollision(player, normal);
    }

    if (ballPosition.y < _goalLine && _isGoalOpening(ballPosition.x)) {
      _score(CageSide.north.index);
      return;
    }
    if (ballPosition.x > 1 - _goalLine && _isGoalOpening(ballPosition.y)) {
      _score(CageSide.east.index);
      return;
    }
    if (ballPosition.y > 1 - _goalLine && _isGoalOpening(ballPosition.x)) {
      _score(CageSide.south.index);
      return;
    }
    if (ballPosition.x < _goalLine && _isGoalOpening(ballPosition.y)) {
      _score(CageSide.west.index);
      return;
    }

    _bounceOffWalls();
  }

  void _onPlayerCollision(CagePlayer player, Vector2 normal) {
    final incomingSpeed = _ballVelocity.length;
    final approachSpeed = _ballVelocity.dot(normal);
    var outgoing = approachSpeed < 0
        ? _ballVelocity - normal * (2 * approachSpeed)
        : _ballVelocity;

    final input = player.isHuman ? _moveInput : _botInput(player);
    outgoing += input * .16;
    if (outgoing.lengthSquared < .0001) outgoing = normal;

    final acceleratedSpeed =
        math.max(incomingSpeed, _baseBallSpeed) * _collisionAcceleration;
    _ballVelocity = outgoing.normalized() * acceleratedSpeed;
    ballTouches++;
  }

  void _bounceOffWalls() {
    if (ballPosition.x < _goalLine || ballPosition.x > 1 - _goalLine) {
      _ballVelocity = Vector2(-_ballVelocity.x, _ballVelocity.y);
      ballPosition = Vector2(
        ballPosition.x.clamp(_goalLine, 1 - _goalLine).toDouble(),
        ballPosition.y,
      );
    }
    if (ballPosition.y < _goalLine || ballPosition.y > 1 - _goalLine) {
      _ballVelocity = Vector2(_ballVelocity.x, -_ballVelocity.y);
      ballPosition = Vector2(
        ballPosition.x,
        ballPosition.y.clamp(_goalLine, 1 - _goalLine).toDouble(),
      );
    }
  }

  bool _isGoalOpening(double position) =>
      (position - .5).abs() < _goalHalfWidth;

  void _score(int targetIndex) {
    final target = players[targetIndex];
    if (target.lives <= 0) {
      switch (target.side) {
        case CageSide.north:
          _ballVelocity = Vector2(_ballVelocity.x, _ballVelocity.y.abs());
          ballPosition = Vector2(
            ballPosition.x,
            ballPosition.y.clamp(_goalLine, 1 - _goalLine).toDouble(),
          );
          break;
        case CageSide.east:
          _ballVelocity = Vector2(-_ballVelocity.x.abs(), _ballVelocity.y);
          ballPosition = Vector2(
            ballPosition.x.clamp(_goalLine, 1 - _goalLine).toDouble(),
            ballPosition.y,
          );
          break;
        case CageSide.south:
          _ballVelocity = Vector2(_ballVelocity.x, -_ballVelocity.y.abs());
          ballPosition = Vector2(
            ballPosition.x,
            ballPosition.y.clamp(_goalLine, 1 - _goalLine).toDouble(),
          );
          break;
        case CageSide.west:
          _ballVelocity = Vector2(_ballVelocity.x.abs(), _ballVelocity.y);
          ballPosition = Vector2(
            ballPosition.x.clamp(_goalLine, 1 - _goalLine).toDouble(),
            ballPosition.y,
          );
          break;
      }
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
    _ballVelocity = _kickoffVelocity;
    ballTouches = 0;
  }
}
