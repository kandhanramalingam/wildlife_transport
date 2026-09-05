import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildlife_transport/core/location/home_permissions.dart';

void main() {
  late _PermissionsGeolocator location;
  final platform = TargetPlatformVariant.only(TargetPlatform.iOS);

  setUp(() {
    final original = GeolocatorPlatform.instance;
    location = _PermissionsGeolocator();
    GeolocatorPlatform.instance = location;
    addTearDown(() {
      GeolocatorPlatform.instance = original;
    });
  });

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => checkHomePermissions(context),
                child: const Text('Check'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
  }

  testWidgets('does not prompt when location is already allowed', (
    tester,
  ) async {
    location.permission = LocationPermission.whileInUse;
    await openPage(tester);
    expect(find.text('Delivery permissions'), findsNothing);
    expect(location.requests, 0);
  }, variant: platform);

  testWidgets('requests missing location only after Continue', (tester) async {
    await openPage(tester);
    expect(find.text('Delivery permissions'), findsOneWidget);
    expect(location.requests, 0);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(location.requests, 1);
  }, variant: platform);

  testWidgets('Not now leaves permissions unchanged', (tester) async {
    await openPage(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(location.requests, 0);
    expect(find.text('Delivery permissions'), findsNothing);
  }, variant: platform);

  testWidgets('blocked permission opens app settings', (tester) async {
    location.permission = LocationPermission.deniedForever;
    await openPage(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(location.settingsOpened, isTrue);
    expect(location.requests, 0);
  }, variant: platform);
}

class _PermissionsGeolocator extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  int requests = 0;
  bool settingsOpened = false;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return LocationPermission.whileInUse;
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpened = true;
    return true;
  }
}
