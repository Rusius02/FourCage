import 'package:flutter/material.dart';

const gameBackground = Color(0xFF07120F);
const gameSurface = Color(0xFF10211B);
const gameMint = Color(0xFF51E6C2);
const gameMuted = Color(0xFF91A9A1);

Color playerColorForIndex(int index) => switch (index) {
  0 => const Color(0xFFFF6B6B),
  1 => const Color(0xFFB88CFF),
  2 => gameMint,
  _ => const Color(0xFFFFD166),
};
