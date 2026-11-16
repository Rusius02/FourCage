import 'package:flutter/material.dart';

import '../../../app/game_palette.dart';
import '../../match/presentation/match_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 380;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gameBackground, Color(0xFF10261D), gameBackground],
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
                    Expanded(child: _GameIntroduction(compact: compact)),
                    const SizedBox(width: 26),
                    Expanded(child: _ModeSelection(compact: compact)),
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

class _GameIntroduction extends StatelessWidget {
  const _GameIntroduction({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
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
              style: TextStyle(color: gameMint),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'QUATRE CAGES. TROIS VIES.\nDERNIER JOUEUR DEBOUT.',
        style: TextStyle(
          color: gameMuted,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w700,
          height: 1.6,
          letterSpacing: 1.3,
        ),
      ),
    ],
  );
}

class _ModeSelection extends StatelessWidget {
  const _ModeSelection({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _FeaturePill(compact: compact),
      SizedBox(height: compact ? 12 : 20),
      _ModeCard(
        title: 'SOLO',
        subtitle: 'Affronte trois bots',
        icon: Icons.smart_toy_rounded,
        compact: compact,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MatchScreen()),
        ),
      ),
      SizedBox(height: compact ? 9 : 12),
      _ModeCard(
        title: 'MULTIJOUEUR',
        subtitle: 'En ligne • bientôt disponible',
        icon: Icons.public_rounded,
        compact: compact,
        isSecondary: true,
        onPressed: () => _showMultiplayerInfo(context),
      ),
      SizedBox(height: compact ? 8 : 12),
      Text(
        'Glisse pour bouger  ·  Tire pour frapper',
        textAlign: TextAlign.center,
        style: TextStyle(color: gameMuted, fontSize: compact ? 9 : 11),
      ),
    ],
  );

  void _showMultiplayerInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.public_rounded, color: gameMint),
        title: const Text('Multijoueur bientôt disponible'),
        content: const Text(
          'Le mode solo contre les bots est disponible. Le multijoueur '
          'en ligne arrivera dans une prochaine version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('COMPRIS'),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.compact,
    required this.onPressed,
    this.isSecondary = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool compact;
  final bool isSecondary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: isSecondary ? Colors.white.withValues(alpha: .045) : gameMint,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 53 : 66),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSecondary
                ? Colors.white.withValues(alpha: .1)
                : gameMint,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: compact ? 23 : 27,
              color: isSecondary ? gameMint : const Color(0xFF06140F),
            ),
            SizedBox(width: compact ? 10 : 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSecondary ? Colors.white : gameBackground,
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSecondary ? gameMuted : const Color(0xFF21483C),
                      fontSize: compact ? 9 : 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSecondary
                  ? Icons.lock_outline_rounded
                  : Icons.arrow_forward_rounded,
              size: 18,
              color: isSecondary ? gameMuted : gameBackground,
            ),
          ],
        ),
      ),
    ),
  );
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
        _FeatureDivider(compact: compact),
        _FeatureItem(value: '3', label: 'VIES', compact: compact),
        _FeatureDivider(compact: compact),
        _FeatureItem(value: '3', label: 'BOTS', compact: compact),
      ],
    ),
  );
}

class _FeatureDivider extends StatelessWidget {
  const _FeatureDivider({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: compact ? 28 : 36, color: Colors.white12);
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
          color: gameMint,
          fontWeight: FontWeight.w900,
          fontSize: compact ? 15 : 19,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: gameMuted,
          fontSize: compact ? 7 : 9,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _GameLogo extends StatelessWidget {
  const _GameLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: gameMint.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(size * .28),
      border: Border.all(color: gameMint.withValues(alpha: .45)),
      boxShadow: [
        BoxShadow(color: gameMint.withValues(alpha: .12), blurRadius: 24),
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
      ..color = gameMint
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
      ..color = gameBackground
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
