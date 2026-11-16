import 'package:flutter/material.dart';

import '../features/home/presentation/home_screen.dart';
import 'game_palette.dart';

class FourCageApp extends StatelessWidget {
  const FourCageApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FourCage',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: gameBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gameMint,
        brightness: Brightness.dark,
        surface: gameSurface,
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
    ),
    home: const HomeScreen(),
  );
}
