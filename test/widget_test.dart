import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:four_cage/app/four_cage_app.dart';

void main() {
  testWidgets('the home screen offers solo and multiplayer modes', (
    tester,
  ) async {
    await tester.pumpWidget(const FourCageApp());

    expect(find.text('SOLO'), findsOneWidget);
    expect(find.text('MULTIJOUEUR'), findsOneWidget);
    expect(find.text('CAGES'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
  });

  testWidgets('multiplayer clearly explains that it is not available yet', (
    tester,
  ) async {
    await tester.pumpWidget(const FourCageApp());
    await tester.tap(find.text('MULTIJOUEUR'));
    await tester.pumpAndSettle();

    expect(find.text('Multijoueur bientôt disponible'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a match has large movement buttons and no speed statistics', (
    tester,
  ) async {
    await tester.pumpWidget(const FourCageApp());
    await tester.tap(find.text('SOLO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('GAUCHE'), findsOneWidget);
    expect(find.text('DROITE'), findsOneWidget);
    expect(find.text('INCLINE POUR ACCÉLÉRER'), findsNWidgets(2));
    expect(find.textContaining('CONTACT'), findsNothing);
    expect(find.text('VITESSE'), findsNothing);
    expect(find.text('TIRER'), findsNothing);
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('REPRENDRE'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
