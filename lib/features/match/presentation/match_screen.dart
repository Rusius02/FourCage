import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/game_palette.dart';
import '../application/match_controller.dart';
import '../domain/match_simulation.dart';
import '../domain/vector2.dart';
import 'pitch_painter.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  final MatchController _match = MatchController();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final delta = (elapsed - _lastTick).inMicroseconds / 1000000;
      _lastTick = elapsed;
      _match.update(delta);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _match.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boardSize = math.min(
            constraints.maxHeight,
            constraints.maxWidth * .72,
          );
          return Row(
            children: [
              Expanded(
                child: Center(
                  child: _Joystick(
                    match: _match,
                    size: math.min(126, boardSize * .36),
                  ),
                ),
              ),
              SizedBox(
                width: boardSize,
                height: boardSize,
                child: _GameBoard(
                  match: _match,
                  onPause: _match.pause,
                  onResume: _match.resume,
                  onRestart: _match.restart,
                  onExit: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: _KickButton(
                    onPressed: _match.shoot,
                    size: math.min(104, boardSize * .3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _Joystick extends StatelessWidget {
  const _Joystick({required this.match, required this.size});

  final MatchController match;
  final double size;

  void _updateInput(Offset position) {
    final center = Offset(size / 2, size / 2);
    final offset = position - center;
    final radius = size * .34;
    final length = offset.distance;
    final input = length > radius ? offset / length : offset / radius;
    match.setMoveInput(Vector2(input.dx, input.dy));
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Listener(
      onPointerDown: (event) => _updateInput(event.localPosition),
      onPointerMove: (event) => _updateInput(event.localPosition),
      onPointerUp: (_) => match.setMoveInput(Vector2.zero),
      onPointerCancel: (_) => match.setMoveInput(Vector2.zero),
      child: AnimatedBuilder(
        animation: match,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * .9,
              height: size * .9,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .045),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .12)),
              ),
            ),
            Container(
              width: size * .57,
              height: size * .57,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .1)),
              ),
            ),
            Transform.translate(
              offset: Offset(match.moveInput.x, match.moveInput.y) * size * .28,
              child: Container(
                width: size * .31,
                height: size * .31,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7AF2D4), gameMint],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gameMint.withValues(alpha: .3),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.control_camera_rounded,
                  color: const Color(0xFF072019),
                  size: size * .18,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _KickButton extends StatelessWidget {
  const _KickButton({required this.onPressed, required this.size});

  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE08A), Color(0xFFFFB84D)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC45C).withValues(alpha: .2),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.sports_soccer_rounded,
            size: size * .47,
            color: const Color(0xFF26190B),
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'TIRER',
          style: TextStyle(
            color: Color(0xFFFFD166),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _GameBoard extends StatelessWidget {
  const _GameBoard({
    required this.match,
    required this.onPause,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final MatchController match;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: PitchPainter(match)),
          Positioned(
            top: 8,
            left: 10,
            child: IconButton(
              onPressed: onExit,
              visualDensity: VisualDensity.compact,
              tooltip: 'Quitter le match',
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: .3),
                foregroundColor: Colors.white70,
              ),
            ),
          ),
          Positioned(
            top: 11,
            right: 10,
            child: AnimatedBuilder(
              animation: match,
              builder: (context, _) => IconButton(
                onPressed: match.result == MatchResult.playing ? onPause : null,
                visualDensity: VisualDensity.compact,
                tooltip: 'Pause',
                icon: const Icon(Icons.pause_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: .3),
                  foregroundColor: Colors.white70,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: match,
            builder: (context, _) {
              if (match.announcement == null ||
                  match.result != MatchResult.playing) {
                return const SizedBox.shrink();
              }
              return Align(
                alignment: const Alignment(0, -.68),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE60B1914),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gameMint.withValues(alpha: .4)),
                  ),
                  child: Text(
                    match.announcement!,
                    style: const TextStyle(
                      color: gameMint,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: match,
            builder: (context, _) => _MatchOverlay(
              result: match.result,
              onResume: onResume,
              onRestart: onRestart,
              onExit: onExit,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MatchOverlay extends StatelessWidget {
  const _MatchOverlay({
    required this.result,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final MatchResult result;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    if (result == MatchResult.playing) return const SizedBox.shrink();
    final paused = result == MatchResult.paused;
    final won = result == MatchResult.won;
    return ColoredBox(
      color: Colors.black.withValues(alpha: .72),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                paused
                    ? 'PAUSE'
                    : won
                    ? 'CHAMPION !'
                    : 'MATCH TERMINÉ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: won ? gameMint : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                paused
                    ? 'Reprends quand tu es prêt.'
                    : won
                    ? 'Les quatre cages sont à toi.'
                    : 'Tes trois vies sont épuisées.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: paused ? onResume : onRestart,
                style: FilledButton.styleFrom(
                  backgroundColor: gameMint,
                  foregroundColor: gameBackground,
                  minimumSize: const Size(140, 38),
                ),
                child: Text(
                  paused ? 'REPRENDRE' : 'REJOUER',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (!paused)
                TextButton(
                  onPressed: onExit,
                  child: const Text(
                    'MENU PRINCIPAL',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
