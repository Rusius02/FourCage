import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/game_palette.dart';
import '../application/match_controller.dart';
import '../application/tilt_movement_controller.dart';
import '../domain/match_simulation.dart';
import '../domain/vector2.dart';
import '../infrastructure/accelerometer_tilt_input_source.dart';
import 'pitch_painter.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key, this.tiltInputSource});

  final TiltInputSource? tiltInputSource;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  final MatchController _match = MatchController();
  late final TiltMovementController _tiltMovement;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _buttonInput = 0;

  @override
  void initState() {
    super.initState();
    _tiltMovement = TiltMovementController(
      (widget.tiltInputSource ?? const AccelerometerTiltInputSource())
          .horizontalTilt,
    )..addListener(_updateMovementInput);
    _ticker = createTicker((elapsed) {
      final delta = (elapsed - _lastTick).inMicroseconds / 1000000;
      _lastTick = elapsed;
      _match.update(delta);
    })..start();
  }

  void _setButtonInput(double input) {
    _buttonInput = input;
    _updateMovementInput();
  }

  void _updateMovementInput() {
    final tiltInput = _tiltMovement.horizontalInput;
    final direction = _buttonInput == 0 ? tiltInput : _buttonInput;
    final canAccelerate =
        _buttonInput == 0 || _buttonInput.sign == tiltInput.sign;
    final acceleration = canAccelerate ? tiltInput.abs() : 0.0;
    _match.setMoveInput(Vector2(direction, 0), acceleration: acceleration);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tiltMovement
      ..removeListener(_updateMovementInput)
      ..dispose();
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
                  child: _MovementButton(
                    label: 'GAUCHE',
                    icon: Icons.arrow_left_rounded,
                    onPressed: () => _setButtonInput(-1),
                    onReleased: () => _setButtonInput(0),
                    size: math.min(112, boardSize * .34),
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
                  child: _MovementButton(
                    label: 'DROITE',
                    icon: Icons.arrow_right_rounded,
                    onPressed: () => _setButtonInput(1),
                    onReleased: () => _setButtonInput(0),
                    size: math.min(112, boardSize * .34),
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

class _MovementButton extends StatelessWidget {
  const _MovementButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.onReleased,
    required this.size,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback onReleased;
  final double size;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTapDown: (_) => onPressed(),
        onTapUp: (_) => onReleased(),
        onTapCancel: onReleased,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF10211B),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: gameMint.withValues(alpha: .55),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(color: gameMint.withValues(alpha: .14), blurRadius: 22),
            ],
          ),
          child: Icon(icon, size: size * .72, color: gameMint),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'INCLINE POUR ACCÉLÉRER',
        style: TextStyle(
          color: gameMuted,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: .9,
        ),
      ),
    ],
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
