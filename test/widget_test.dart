import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:four_cage/main.dart';

void main() {
  testWidgets('the home screen presents a way to start a match', (
    tester,
  ) async {
    await tester.pumpWidget(const FourCageApp());

    expect(find.text('JOUER'), findsOneWidget);
    expect(find.text('CAGES'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
  });

  testWidgets('a match opens with shooting controls and can be paused', (
    tester,
  ) async {
    await tester.pumpWidget(const FourCageApp());
    await tester.tap(find.text('JOUER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('TIRER'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('REPRENDRE'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
