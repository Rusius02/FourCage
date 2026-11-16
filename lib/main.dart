import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import 'game_engine.dart';

const _background = Color(0xFF07120F);
const _surface = Color(0xFF10211B);
const _mint = Color(0xFF51E6C2);
const _muted = Color(0xFF91A9A1);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FourCageApp());
}

class FourCageApp extends StatelessWidget {
  const FourCageApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FourCage',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _mint,
        brightness: Brightness.dark,
        surface: _surface,
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
    ),
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 380;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_background, Color(0xFF10261D), _background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 22 : 36,
                  vertical: compact ? 10 : 24,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GameLogo(size: compact ? 50 : 68),
                          SizedBox(height: compact ? 9 : 16),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: compact ? 31 : 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                height: 1,
                                color: Colors.white,
                              ),
                              children: const [
                                TextSpan(text: 'FOUR'),
                                TextSpan(
                                  text: 'CAGE',
                                  style: TextStyle(color: _mint),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'QUATRE CAGES. TROIS VIES.\nDERNIER JOUEUR DEBOUT.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: compact ? 9 : 11,
                              fontWeight: FontWeight.w700,
                              height: 1.6,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 26),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FeaturePill(compact: compact),
                          SizedBox(height: compact ? 12 : 20),
                          FilledButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const GameScreen(),
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _mint,
                              foregroundColor: const Color(0xFF06140F),
                              minimumSize: Size.fromHeight(compact ? 47 : 58),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sports_soccer_rounded),
                                const SizedBox(width: 10),
                                Text(
                                  'JOUER',
                                  style: TextStyle(
                                    fontSize: compact ? 15 : 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: compact ? 9 : 14),
                          Text(
                            'Glisse pour bouger  ·  Tire pour frapper',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: compact ? 9 : 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameLogo extends StatelessWidget {
  const _GameLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: _mint.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(size * .28),
      border: Border.all(color: _mint.withValues(alpha: .45)),
      boxShadow: [
        BoxShadow(color: _mint.withValues(alpha: .12), blurRadius: 24),
      ],
    ),
    child: CustomPaint(painter: _LogoPainter()),
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final field = Rect.fromLTWH(
      size.width * .23,
      size.height * .23,
      size.width * .54,
      size.height * .54,
    );
    final line = Paint()
      ..color = _mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .055
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(field, Radius.circular(size.width * .06)),
      line,
    );
    canvas.drawLine(
      Offset(size.width * .5, field.top),
      Offset(size.width * .5, field.bottom),
      line,
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.width * .07,
      Paint()..color = Colors.white,
    );
    final goal = Paint()
      ..color = const Color(0xFF07120F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .045;
    canvas.drawLine(
      Offset(field.center.dx, field.top),
      Offset(field.center.dx, field.top - size.height * .07),
      goal,
    );
    canvas.drawLine(
      Offset(field.center.dx, field.bottom),
      Offset(field.center.dx, field.bottom + size.height * .07),
      goal,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 10 : 14,
      vertical: compact ? 8 : 12,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _FeatureItem(value: '4', label: 'CAGES', compact: compact),
        Container(width: 1, height: compact ? 28 : 36, color: Colors.white12),
        _FeatureItem(value: '3', label: 'VIES', compact: compact),
        Container(width: 1, height: compact ? 28 : 36, color: Colors.white12),
        _FeatureItem(value: '3', label: 'BOTS', compact: compact),
      ],
    ),
  );
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.value,
    required this.label,
    required this.compact,
  });

  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: _mint,
          fontWeight: FontWeight.w900,
          fontSize: compact ? 15 : 19,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: _muted,
          fontSize: compact ? 7 : 9,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameEngine _game = GameEngine();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((elapsed) {
      final delta = (elapsed - _lastTick).inMicroseconds / 1000000;
      _lastTick = elapsed;
      _game.update(delta);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _game.dispose();
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
                    game: _game,
                    size: math.min(126, boardSize * .36),
                  ),
                ),
              ),
              SizedBox(
                width: boardSize,
                height: boardSize,
                child: _GameBoard(
                  game: _game,
                  onPause: () => _game.pause(),
                  onResume: () => _game.resume(),
                  onRestart: () => _game.restart(),
                  onExit: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: _KickButton(
                    game: _game,
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
  const _Joystick({required this.game, required this.size});

  final GameEngine game;
  final double size;

  void _updateInput(Offset position) {
    final center = Offset(size / 2, size / 2);
    final offset = position - center;
    final radius = size * .34;
    final length = offset.distance;
    game.setMoveInput(length > radius ? offset / length : offset / radius);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Listener(
      onPointerDown: (event) => _updateInput(event.localPosition),
      onPointerMove: (event) => _updateInput(event.localPosition),
      onPointerUp: (_) => game.setMoveInput(Offset.zero),
      onPointerCancel: (_) => game.setMoveInput(Offset.zero),
      child: AnimatedBuilder(
        animation: game,
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
              offset: game.moveInput * size * .28,
              child: Container(
                width: size * .31,
                height: size * .31,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7AF2D4), _mint],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _mint.withValues(alpha: .3),
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
  const _KickButton({required this.game, required this.size});

  final GameEngine game;
  final double size;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: game.shoot,
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
    required this.game,
    required this.onPause,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final GameEngine game;
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
          CustomPaint(painter: _PitchPainter(game)),
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
              animation: game,
              builder: (context, _) => IconButton(
                onPressed: game.result == MatchResult.playing ? onPause : null,
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
            animation: game,
            builder: (context, _) {
              if (game.announcement == null ||
                  game.result != MatchResult.playing) {
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
                    border: Border.all(color: _mint.withValues(alpha: .4)),
                  ),
                  child: Text(
                    game.announcement!,
                    style: const TextStyle(
                      color: _mint,
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
            animation: game,
            builder: (context, _) {
              if (game.result == MatchResult.playing) {
                return const SizedBox.shrink();
              }
              final paused = game.result == MatchResult.paused;
              final won = game.result == MatchResult.won;
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
                            color: won ? _mint : Colors.white,
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
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: paused ? onResume : onRestart,
                          style: FilledButton.styleFrom(
                            backgroundColor: _mint,
                            foregroundColor: _background,
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _PitchPainter extends CustomPainter {
  _PitchPainter(this.game) : super(repaint: game);

  final GameEngine game;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()..color = const Color(0xFF123629),
    );
    final field = Paint()..color = const Color(0xFF174633);
    const tile = .09;
    for (var row = 0; row < 10; row++) {
      for (var column = 0; column < 10; column++) {
        if ((row + column).isOdd) {
          canvas.drawRect(
            Rect.fromLTWH(.045 + column * tile, .045 + row * tile, tile, tile),
            field,
          );
        }
      }
    }

    final markings = Paint()
      ..color = const Color(0xFFB6E9CB).withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .002;
    canvas.drawLine(
      const Offset(.045, .045),
      const Offset(.395, .045),
      markings,
    );
    canvas.drawLine(
      const Offset(.605, .045),
      const Offset(.955, .045),
      markings,
    );
    canvas.drawLine(
      const Offset(.045, .955),
      const Offset(.395, .955),
      markings,
    );
    canvas.drawLine(
      const Offset(.605, .955),
      const Offset(.955, .955),
      markings,
    );
    canvas.drawLine(
      const Offset(.045, .045),
      const Offset(.045, .395),
      markings,
    );
    canvas.drawLine(
      const Offset(.045, .605),
      const Offset(.045, .955),
      markings,
    );
    canvas.drawLine(
      const Offset(.955, .045),
      const Offset(.955, .395),
      markings,
    );
    canvas.drawLine(
      const Offset(.955, .605),
      const Offset(.955, .955),
      markings,
    );
    canvas.drawLine(const Offset(.045, .5), const Offset(.955, .5), markings);
    canvas.drawCircle(const Offset(.5, .5), .13, markings);
    canvas.drawCircle(
      const Offset(.5, .5),
      .008,
      Paint()..color = Colors.white.withValues(alpha: .5),
    );

    _drawGoal(canvas, 0);
    _drawGoal(canvas, 1);
    _drawGoal(canvas, 2);
    _drawGoal(canvas, 3);

    for (var index = 0; index < game.players.length; index++) {
      _drawTeam(canvas, index);
    }
    _drawBall(canvas);
    canvas.restore();
  }

  void _drawGoal(Canvas canvas, int index) {
    final player = game.players[index];
    final color = player.color.withValues(alpha: player.lives == 0 ? .25 : .9);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = .009
      ..strokeCap = StrokeCap.round;
    final net = Paint()
      ..color = color.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .002;
    final Rect goal;
    switch (index) {
      case 0:
        goal = const Rect.fromLTRB(.405, .025, .595, .09);
      case 1:
        goal = const Rect.fromLTRB(.91, .405, .975, .595);
      case 2:
        goal = const Rect.fromLTRB(.405, .91, .595, .975);
      default:
        goal = const Rect.fromLTRB(.025, .405, .09, .595);
    }
    canvas.drawRect(goal, net);
    canvas.drawRRect(
      RRect.fromRectAndRadius(goal, const Radius.circular(.009)),
      paint,
    );
    for (var line = 1; line < 4; line++) {
      final t = line / 4;
      if (index.isEven) {
        final x = goal.left + goal.width * t;
        canvas.drawLine(Offset(x, goal.top), Offset(x, goal.bottom), net);
      } else {
        final y = goal.top + goal.height * t;
        canvas.drawLine(Offset(goal.left, y), Offset(goal.right, y), net);
      }
    }
    _drawLives(canvas, index, color);
  }

  void _drawLives(Canvas canvas, int index, Color color) {
    final center = switch (index) {
      0 => const Offset(.5, .145),
      1 => const Offset(.855, .5),
      2 => const Offset(.5, .855),
      _ => const Offset(.145, .5),
    };
    final player = game.players[index];
    final label = TextPainter(
      text: TextSpan(
        text: player.name,
        style: TextStyle(
          color: color,
          fontSize: .022,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    label.paint(
      canvas,
      Offset(center.dx - label.width / 2, center.dy - label.height * .6),
    );
    const spacing = .021;
    for (var life = 0; life < 3; life++) {
      canvas.drawCircle(
        Offset(center.dx + (life - 1) * spacing, center.dy + .032),
        .006,
        Paint()
          ..color = life < player.lives
              ? color
              : Colors.black.withValues(alpha: .45),
      );
    }
  }

  void _drawTeam(Canvas canvas, int index) {
    final player = game.players[index];
    if (player.lives <= 0) return;
    final center = player.position;
    const radius = .033;
    canvas.drawCircle(
      center,
      radius * 1.45,
      Paint()
        ..color = player.color.withValues(alpha: .16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .012),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [player.color.withValues(alpha: .95), player.color],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = player.isHuman ? Colors.white : Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = player.isHuman ? .004 : .002,
    );
    canvas.drawCircle(
      center + player.facing * .022,
      .006,
      Paint()..color = const Color(0xFF10201A),
    );
    if (player.isHuman) {
      canvas.drawCircle(
        center,
        radius + .008,
        Paint()
          ..color = Colors.white.withValues(alpha: .75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .002,
      );
    }
  }

  void _drawBall(Canvas canvas) {
    final center = game.ballPosition;
    canvas.drawCircle(
      center,
      .035,
      Paint()
        ..color = _mint.withValues(alpha: .32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .016),
    );
    canvas.drawCircle(
      center + const Offset(.004, .005),
      .018,
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawCircle(
      center,
      .015,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.4),
          colors: [Colors.white, Color(0xFFDCE8E0), Color(0xFF82988B)],
        ).createShader(Rect.fromCircle(center: center, radius: .015)),
    );
    canvas.drawCircle(
      center,
      .015,
      Paint()
        ..color = const Color(0xFF31493D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .002,
    );
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) =>
      oldDelegate.game != game;
}
