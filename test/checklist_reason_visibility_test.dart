import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/screens/start_delivery/steps/checklist_step.dart';
import 'package:wildlife_transport/features/delivery/screens/start_delivery/steps/game_loading_checklist_step.dart';

void main() {
  testWidgets('vehicle reasons are hidden until Next is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChecklistStep(onNext: (_) {})),
      ),
    );

    expect(find.text('Reason for skipping this item *'), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.pump();

    expect(find.text('Reason for skipping this item *'), findsWidgets);
    expect(
      find.text(
        'Please check all items or provide reasons for unchecked items',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'loading and offloading reasons are hidden until Next is tapped',
    (tester) async {
      for (final isOffLoading in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameLoadingChecklistStep(
                onNext: (_) {},
                isOffLoading: isOffLoading,
              ),
            ),
          ),
        );

        expect(find.text('Reason for skipping this item *'), findsNothing);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await tester.pump();
        expect(find.text('Reason for skipping this item *'), findsWidgets);
      }
    },
  );
}
