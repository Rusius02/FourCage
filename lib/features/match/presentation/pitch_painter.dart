import 'package:flutter/material.dart';

import '../../../app/game_palette.dart';
import '../application/match_controller.dart';
import '../domain/vector2.dart';

class PitchPainter extends CustomPainter {
  PitchPainter(this.match) : super(repaint: match);

  final MatchController match;

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

    _drawFieldMarkings(canvas);
    for (var index = 0; index < match.players.length; index++) {
      _drawGoal(canvas, index);
      _drawPlayer(canvas, index);
    }
    _drawBall(canvas);
    canvas.restore();
  }

  void _drawFieldMarkings(Canvas canvas) {
    final markings = Paint()
      ..color = const Color(0xFFB6E9CB).withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .002;
    const lines = [
      [Offset(.045, .045), Offset(.395, .045)],
      [Offset(.605, .045), Offset(.955, .045)],
      [Offset(.045, .955), Offset(.395, .955)],
      [Offset(.605, .955), Offset(.955, .955)],
      [Offset(.045, .045), Offset(.045, .395)],
      [Offset(.045, .605), Offset(.045, .955)],
      [Offset(.955, .045), Offset(.955, .395)],
      [Offset(.955, .605), Offset(.955, .955)],
      [Offset(.045, .5), Offset(.955, .5)],
    ];
    for (final line in lines) {
      canvas.drawLine(line[0], line[1], markings);
    }
    canvas.drawCircle(const Offset(.5, .5), .13, markings);
    canvas.drawCircle(
      const Offset(.5, .5),
      .008,
      Paint()..color = Colors.white.withValues(alpha: .5),
    );
  }

  void _drawGoal(Canvas canvas, int index) {
    final player = match.players[index];
    final color = playerColorForIndex(
      index,
    ).withValues(alpha: player.lives == 0 ? .25 : .9);
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
    final player = match.players[index];
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

  void _drawPlayer(Canvas canvas, int index) {
    final player = match.players[index];
    if (player.lives <= 0) return;
    final center = _toOffset(player.position);
    final facing = _toOffset(player.facing);
    final color = playerColorForIndex(index);
    const radius = .033;
    canvas.drawCircle(
      center,
      radius * 1.45,
      Paint()
        ..color = color.withValues(alpha: .16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .012),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: .95), color],
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
      center + facing * .022,
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
    final center = _toOffset(match.ballPosition);
    canvas.drawCircle(
      center,
      .035,
      Paint()
        ..color = gameMint.withValues(alpha: .32)
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

  Offset _toOffset(Vector2 vector) => Offset(vector.x, vector.y);

  @override
  bool shouldRepaint(covariant PitchPainter oldDelegate) =>
      oldDelegate.match != match;
}
