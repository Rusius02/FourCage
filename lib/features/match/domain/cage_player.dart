import 'vector2.dart';

enum CageSide {
  north('NOVA', Vector2(.5, .055), Vector2(0, 1)),
  east('ECHO', Vector2(.945, .5), Vector2(-1, 0)),
  south('TOI', Vector2(.5, .945), Vector2(0, -1)),
  west('PIXEL', Vector2(.055, .5), Vector2(1, 0));

  const CageSide(this.displayName, this.startPosition, this.inwardDirection);

  final String displayName;
  final Vector2 startPosition;
  final Vector2 inwardDirection;

  bool get movesHorizontally => this == north || this == south;
}

class CagePlayer {
  CagePlayer({required this.side, required this.isHuman})
    : position = side.startPosition,
      facing = side.inwardDirection;

  final CageSide side;
  final bool isHuman;
  Vector2 position;
  final Vector2 facing;
  int lives = 3;

  String get name => side.displayName;
  Vector2 get home => side.startPosition;
}
