import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/screens/start_delivery/steps/photos_step.dart';

void main() {
  testWidgets('shows a separate camera target for every assigned lot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotosStep(
            lotNumbers: const ['101', '102'],
            includeVehicleDetails: false,
            includeVehiclePhotos: false,
            requireLocation: false,
            onNext: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Lot 101'), findsOneWidget);
    expect(find.text('Lot 102'), findsOneWidget);
    expect(find.byKey(const ValueKey('lot-photo-101')), findsOneWidget);
    expect(find.byKey(const ValueKey('lot-photo-102')), findsOneWidget);
    expect(find.byKey(const ValueKey('lot-video-101')), findsOneWidget);
    expect(find.byKey(const ValueKey('lot-video-102')), findsOneWidget);
  });
}
