import 'dart:math' as math;

class Vector2 {
  const Vector2(this.x, this.y);

  static const zero = Vector2(0, 0);

  final double x;
  final double y;

  double get length => math.sqrt(lengthSquared);
  double get lengthSquared => x * x + y * y;

  Vector2 normalized() {
    final magnitude = length;
    return magnitude == 0 ? zero : this / magnitude;
  }

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);

  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);

  Vector2 operator *(double factor) => Vector2(x * factor, y * factor);

  Vector2 operator /(double divisor) => Vector2(x / divisor, y / divisor);

  double distanceTo(Vector2 other) => (this - other).length;

  double distanceSquaredTo(Vector2 other) => (this - other).lengthSquared;

  double dot(Vector2 other) => x * other.x + y * other.y;
}
