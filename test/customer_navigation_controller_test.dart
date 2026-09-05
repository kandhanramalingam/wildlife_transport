import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:wildlife_transport/features/delivery/screens/customer_directions_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildlife_transport/features/delivery/models/driving_route.dart';
import 'package:wildlife_transport/features/delivery/presentation/customer_navigation_controller.dart';

void main() {
  final start = DateTime.utc(2026, 9, 5, 12);
  const destination = LatLng(0, .01);
  Position fix(double longitude, DateTime time, {double accuracy = 5}) =>
      Position(
        latitude: 0,
        longitude: longitude,
        timestamp: time,
        accuracy: accuracy,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 90,
        headingAccuracy: 0,
        speed: 10,
        speedAccuracy: 0,
      );
  DrivingRoute route(LatLng origin) => DrivingRoute(
    points: [origin, destination],
    distanceMetres: 1000,
    durationSeconds: 600,
    instructions: ['Go straight', 'Turn left'],
    warnings: [],
    steps: const [
      DrivingStep(instruction: 'Go straight', distanceMetres: 400),
      DrivingStep(instruction: 'Turn left', distanceMetres: 600),
    ],
  );

  test(
    'location timeout tells the driver to check location and does not call routes',
    () async {
      var routeCalls = 0;
      final controller = CustomerNavigationController(
        destination: destination,
        currentPosition: () async => throw TimeoutException('GPS timeout'),
        loadRoute: (_, _) async {
          routeCalls++;
          return route(const LatLng(0, 0));
        },
      );
      await controller.refresh();
      expect(routeCalls, 0);
      expect(controller.error, contains('location could not be found in time'));
      controller.dispose();
    },
  );

  test(
    'missing route endpoint is reported separately after successful GPS',
    () async {
      final request = RequestOptions(path: 'driver-auth/directions');
      final controller = CustomerNavigationController(
        destination: destination,
        now: () => start,
        currentPosition: () async => fix(0, start),
        loadRoute: (_, _) async => throw DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: request,
            statusCode: 404,
            data: {'message': 'Cannot POST /driver-auth/directions'},
          ),
        ),
      );
      await controller.refresh();
      expect(controller.position, const LatLng(0, 0));
      expect(
        controller.error,
        contains('server needs the latest navigation update'),
      );
      expect(controller.navigating, isFalse);
      controller.dispose();
    },
  );

  testWidgets('shows kilometres, ETA and Start/Stop controls inside the app', (
    tester,
  ) async {
    final stream = StreamController<Position>.broadcast();
    final controller = CustomerNavigationController(
      destination: destination,
      now: () => start,
      currentPosition: () async => fix(0, start),
      watchPosition: () => stream.stream,
      loadRoute: (origin, _) async => route(origin),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDirectionsScreen(
          latitude: 0,
          longitude: .01,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1.0 km • 10 min'), findsOneWidget);
    expect(find.textContaining('Estimated arrival'), findsOneWidget);
    await tester.tap(find.text('Start navigation'));
    await tester.pumpAndSettle();
    expect(find.text('Stop navigation'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    unawaited(stream.close());
    await tester.pump();
  });

  test(
    'starts from fresh GPS, updates distance and steps, then stops on arrival',
    () async {
      var clock = start;
      var currentLongitude = 0.0;
      final stream = StreamController<Position>();
      final origins = <LatLng>[];
      final controller = CustomerNavigationController(
        destination: destination,
        now: () => clock,
        currentPosition: () async => fix(currentLongitude, clock),
        watchPosition: () => stream.stream,
        loadRoute: (origin, destination) async {
          origins.add(origin);
          return route(origin);
        },
      );
      await controller.refresh();
      currentLongitude = .001;
      await controller.start();
      expect(origins.last, const LatLng(0, .001));
      expect(controller.navigating, isTrue);
      clock = start.add(const Duration(seconds: 5));
      stream.add(fix(.006, clock));
      await Future<void>.delayed(Duration.zero);
      expect(controller.remainingMetres, lessThan(500));
      expect(controller.remainingSeconds, lessThan(300));
      expect(controller.instruction, 'Turn left');
      expect(origins.length, 2); // No route API call for every GPS fix.
      stream.add(fix(.0099, clock.add(const Duration(seconds: 1))));
      await Future<void>.delayed(Duration.zero);
      expect(controller.arrived, isTrue);
      expect(controller.navigating, isFalse);
      expect(controller.remainingMetres, 0);
      controller.dispose();
      await stream.close();
    },
  );

  test(
    'refreshes moving driver route after interval and cancels pending results on stop',
    () async {
      var clock = start;
      final stream = StreamController<Position>();
      final pending = Completer<DrivingRoute>();
      var calls = 0;
      final controller = CustomerNavigationController(
        destination: destination,
        now: () => clock,
        currentPosition: () async => fix(0, clock),
        watchPosition: () => stream.stream,
        loadRoute: (origin, destination) {
          calls++;
          return calls == 1 ? Future.value(route(origin)) : pending.future;
        },
      );
      await controller.start();
      clock = start.add(const Duration(seconds: 31));
      stream.add(fix(.004, clock));
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      final originalRoute = controller.route;
      controller.stop();
      pending.complete(route(const LatLng(0, .004)));
      await Future<void>.delayed(Duration.zero);
      expect(controller.route, same(originalRoute));
      expect(controller.loading, isFalse);
      controller.dispose();
      await stream.close();
    },
  );

  test(
    'rejects stale GPS and does not start navigation after route failure',
    () async {
      final controller = CustomerNavigationController(
        destination: destination,
        now: () => start,
        currentPosition: () async =>
            fix(0, start.subtract(const Duration(minutes: 5))),
        loadRoute: (_, _) async =>
            throw StateError('Route service unavailable'),
      );
      await controller.start();
      expect(controller.navigating, isFalse);
      expect(controller.error, contains('accurate GPS'));
      expect(controller.route, isNull);
      controller.dispose();
    },
  );
}
