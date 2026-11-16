import 'package:flutter_test/flutter_test.dart';
import 'package:four_cage/features/match/domain/match_simulation.dart';
import 'package:four_cage/features/match/domain/vector2.dart';

void main() {
  group('MatchSimulation rules', () {
    test('a goal removes a life and starts a kickoff reset', () {
      final game = MatchSimulation()..ballPosition = const Vector2(.67, .03);

      game.update(.016);

      expect(game.players[0].lives, 2);
      expect(game.announcement, 'BUT CONTRE NOVA');
      expect(game.result, MatchResult.playing);
    });

    test('an eliminated cage is closed and cannot lose another life', () {
      final game = MatchSimulation()
        ..players[0].lives = 0
        ..ballPosition = const Vector2(.67, .03);

      game.update(.016);

      expect(game.players[0].lives, 0);
      expect(game.ballPosition.y, greaterThanOrEqualTo(.043));
      expect(game.result, MatchResult.playing);
    });

    test('eliminating the last bot wins the match', () {
      final game = MatchSimulation()
        ..players[0].lives = 1
        ..players[1].lives = 0
        ..players[3].lives = 0
        ..ballPosition = const Vector2(.67, .03);

      game.update(.016);

      expect(game.players[0].lives, 0);
      expect(game.result, MatchResult.won);
    });

    test('losing the final life ends the match', () {
      final game = MatchSimulation()
        ..players[2].lives = 1
        ..ballPosition = const Vector2(.67, .97);

      game.update(.016);

      expect(game.humanLives, 0);
      expect(game.result, MatchResult.lost);
    });

    test('pause freezes play and restart restores the match', () {
      final game = MatchSimulation();

      game.pause();
      game.setMoveInput(const Vector2(1, 0));
      game.update(.5);

      expect(game.result, MatchResult.paused);
      expect(game.elapsedSeconds, 0);

      game.restart();

      expect(game.result, MatchResult.playing);
      expect(game.humanLives, 3);
      expect(game.moveInput, Vector2.zero);
    });

    test('the human goalkeeper moves only along its own goal line', () {
      final game = MatchSimulation();
      final goalkeeper = game.players[2];

      game.setMoveInput(const Vector2(0, 1));
      game.update(.05);
      expect(goalkeeper.position.x, .5);
      expect(goalkeeper.position.y, .945);

      game.setMoveInput(const Vector2(1, 1));
      game.update(.05);
      expect(goalkeeper.position.x, greaterThan(.5));
      expect(goalkeeper.position.y, .945);
    });

    test('tilt acceleration increases the goalkeeper movement speed', () {
      final normal = MatchSimulation();
      final accelerated = MatchSimulation();

      for (var tick = 0; tick < 3; tick++) {
        normal
          ..setMoveInput(const Vector2(1, 0))
          ..ballPosition = const Vector2(.5, .5)
          ..update(.05);
        accelerated
          ..setMoveInput(const Vector2(1, 0), acceleration: 1)
          ..ballPosition = const Vector2(.5, .5)
          ..update(.05);
      }

      expect(
        accelerated.players[2].position.x,
        greaterThan(normal.players[2].position.x),
      );
    });

    test('every goalkeeper remains on its assigned goal line', () {
      final game = MatchSimulation()..ballPosition = const Vector2(.76, .68);

      game.update(.05);

      for (final player in game.players) {
        if (player.side.movesHorizontally) {
          expect(player.position.y, player.home.y);
        } else {
          expect(player.position.x, player.home.x);
        }
      }
    });

    test('goalkeepers cannot leave the width of their goal', () {
      final game = MatchSimulation();
      final goalkeeper = game.players[2];

      for (var tick = 0; tick < 20; tick++) {
        game.setMoveInput(const Vector2(1, 0));
        game.ballPosition = const Vector2(.5, .5);
        game.update(.05);
      }

      expect(goalkeeper.position.x, closeTo(.656, .000001));

      for (var tick = 0; tick < 20; tick++) {
        game.setMoveInput(const Vector2(-1, 0));
        game.ballPosition = const Vector2(.5, .5);
        game.update(.05);
      }

      expect(goalkeeper.position.x, closeTo(.344, .000001));
    });

    test('the ball keeps its speed between collisions and at a wall', () {
      final game = MatchSimulation();
      final initialSpeed = game.ballSpeed;

      game.update(.05);

      expect(game.ballSpeed, closeTo(initialSpeed, .000001));

      game.ballPosition = const Vector2(.75, .95);
      game.update(.05);

      expect(game.ballSpeed, closeTo(initialSpeed, .000001));
    });

    test('a goalkeeper collision returns the ball with increased speed', () {
      final game = MatchSimulation()..ballPosition = const Vector2(.5, .89);
      final initialSpeed = game.ballSpeed;

      game.update(.05);

      expect(game.ballTouches, 1);
      expect(game.ballSpeed, greaterThan(initialSpeed));

      final firstTouchSpeed = game.ballSpeed;
      game.ballPosition = const Vector2(.5, .93);
      game.update(.01);

      expect(game.ballTouches, 2);
      expect(game.ballSpeed, greaterThan(firstTouchSpeed));
    });
  });
}
