import 'package:flutter_test/flutter_test.dart';
import 'package:four_cage/features/match/domain/match_simulation.dart';
import 'package:four_cage/features/match/domain/vector2.dart';

void main() {
  group('MatchSimulation rules', () {
    test('a goal removes a life and starts a kickoff reset', () {
      final game = MatchSimulation()..ballPosition = const Vector2(.5, .03);

      game.update(.016);

      expect(game.players[0].lives, 2);
      expect(game.announcement, 'BUT CONTRE NOVA');
      expect(game.result, MatchResult.playing);
    });

    test('an eliminated cage is closed and cannot lose another life', () {
      final game = MatchSimulation()
        ..players[0].lives = 0
        ..ballPosition = const Vector2(.5, .03);

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
        ..ballPosition = const Vector2(.5, .03);

      game.update(.016);

      expect(game.players[0].lives, 0);
      expect(game.result, MatchResult.won);
    });

    test('losing the final life ends the match', () {
      final game = MatchSimulation()
        ..players[2].lives = 1
        ..ballPosition = const Vector2(.5, .97);

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
  });
}
