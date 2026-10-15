import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/screens/start_delivery/steps/photos_step.dart';

void main() {
  testWidgets('shows trip photo and video capture without lot selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotosStep(
            includeVehicleDetails: false,
            includeVehiclePhotos: false,
            requireLocation: false,
            onNext: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Animal Photos'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-trip-video')), findsOneWidget);
    expect(find.textContaining('Lot '), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });
  for (final offloading in [false, true]) {
    testWidgets(
      offloading
          ? 'offloading keeps one video'
          : 'loading retains multiple videos and supports remove, replace and cancel',
      (tester) async {
        var sequence = 0;
        var cancel = false;
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        const picker = MethodChannel('plugins.flutter.io/image_picker');
        const location = MethodChannel('flutter.baseflow.com/geolocator');
        messenger.setMockMethodCallHandler(picker, (call) async {
          if (call.method == 'pickVideo') {
            return cancel ? null : '/tmp/clip-${++sequence}.mp4';
          }
          return null;
        });
        messenger.setMockMethodCallHandler(location, (call) async {
          switch (call.method) {
            case 'isLocationServiceEnabled':
              return true;
            case 'checkPermission':
              return 3;
            case 'getCurrentPosition':
              return {
                'latitude': -25.0,
                'longitude': 28.0,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'accuracy': 1.0,
                'altitude': 0.0,
                'heading': 0.0,
                'speed': 0.0,
                'speed_accuracy': 0.0,
              };
          }
          return null;
        });
        addTearDown(() {
          messenger.setMockMethodCallHandler(picker, null);
          messenger.setMockMethodCallHandler(location, null);
        });
        PhotosStepData? submitted;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotosStep(
                includeVehicleDetails: false,
                includeVehiclePhotos: false,
                includeAnimalPhotos: false,
                requireLocation: false,
                isOffLoading: offloading,
                onNext: (data) => submitted = data,
              ),
            ),
          ),
        );
        Future<void> record(Finder target) async {
          await tester.ensureVisible(target);
          await tester.tap(target);
          await tester.pumpAndSettle();
        }

        final add = find.byKey(const ValueKey('add-trip-video'));
        await record(add);
        expect(find.textContaining('clip-1.mp4'), findsOneWidget);
        if (offloading) {
          expect(add, findsNothing);
          await record(find.byTooltip('Record again'));
          expect(find.textContaining('clip-1.mp4'), findsNothing);
        } else {
          await record(add);
          expect(find.textContaining('clip-1.mp4'), findsOneWidget);
          expect(find.textContaining('clip-2.mp4'), findsOneWidget);
          await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
          await tester.pump();
          expect(submitted!.animalVideos.map((video) => video.photo.name), [
            'clip-1.mp4',
            'clip-2.mp4',
          ]);
          expect(
            submitted!.animalVideos.every((video) => video.lotNumber == null),
            isTrue,
          );
          cancel = true;
          await record(add);
          expect(find.byTooltip('Remove video'), findsNWidgets(2));
          cancel = false;
          await record(find.byTooltip('Record again').first);
          expect(find.textContaining('clip-3.mp4'), findsOneWidget);
          expect(find.textContaining('clip-2.mp4'), findsOneWidget);
          await record(find.byTooltip('Remove video').last);
        }
        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await tester.pump();
        expect(submitted!.animalVideos, hasLength(1));
        expect(submitted!.animalVideos.single.lotNumber, isNull);
        expect(submitted!.animalVideos.single.latitude, -25.0);
        expect(submitted!.animalVideos.single.longitude, 28.0);
      },
    );
  }
}
