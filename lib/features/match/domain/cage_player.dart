import 'vector2.dart';

enum CageSide {
  north('NOVA', Vector2(.5, .23), Vector2(.5, .035)),
  east('ECHO', Vector2(.77, .5), Vector2(.965, .5)),
  south('TOI', Vector2(.5, .77), Vector2(.5, .965)),
  west('PIXEL', Vector2(.23, .5), Vector2(.035, .5));

  const CageSide(this.displayName, this.startPosition, this.goalCenter);

  final String displayName;
  final Vector2 startPosition;
  final Vector2 goalCenter;
}

class CagePlayer {
  CagePlayer({required this.side, required this.isHuman})
    : position = side.startPosition;

  final CageSide side;
  final bool isHuman;
  Vector2 position;
  Vector2 facing = const Vector2(0, -1);
  int lives = 3;
  double kickCooldown = 0;

  String get name => side.displayName;
  Vector2 get home => side.startPosition;
}
