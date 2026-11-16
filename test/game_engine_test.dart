import 'package:flutter_test/flutter_test.dart';
import 'package:four_cage/game_engine.dart';

void main() {
  group('GameEngine', () {
    test('a goal removes a life and starts a kickoff reset', () {
      final game = GameEngine()..ballPosition = const Offset(.5, .03);

      game.update(.016);

      expect(game.players[0].lives, 2);
      expect(game.announcement, 'BUT CONTRE NOVA');
      expect(game.result, MatchResult.playing);

      game.dispose();
    });

    test('an eliminated cage is closed and cannot lose another life', () {
      final game = GameEngine()
        ..players[0].lives = 0
        ..ballPosition = const Offset(.5, .03);

      game.update(.016);

      expect(game.players[0].lives, 0);
      expect(game.ballPosition.dy, greaterThanOrEqualTo(.043));
      expect(game.result, MatchResult.playing);

      game.dispose();
    });

    test('eliminating the last bot wins the match', () {
      final game = GameEngine()
        ..players[0].lives = 1
        ..players[1].lives = 0
        ..players[3].lives = 0
        ..ballPosition = const Offset(.5, .03);

      game.update(.016);

      expect(game.players[0].lives, 0);
      expect(game.result, MatchResult.won);

      game.dispose();
    });

    test('losing the final life ends the match', () {
      final game = GameEngine()
        ..players[2].lives = 1
        ..ballPosition = const Offset(.5, .97);

      game.update(.016);

      expect(game.humanLives, 0);
      expect(game.result, MatchResult.lost);

      game.dispose();
    });

    test('pause freezes play and restart restores the match', () {
      final game = GameEngine();

      game.pause();
      game.setMoveInput(const Offset(1, 0));
      game.update(.5);

      expect(game.result, MatchResult.paused);
      expect(game.elapsedSeconds, 0);

      game.restart();

      expect(game.result, MatchResult.playing);
      expect(game.humanLives, 3);
      expect(game.moveInput, Offset.zero);

      game.dispose();
    });
  });
}
