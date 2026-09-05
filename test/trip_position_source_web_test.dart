import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildlife_transport/core/location/trip_position_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'browser tracking skips native permissions even on Android browsers',
    () async {
      final original = GeolocatorPlatform.instance;
      final fake = _BrowserGeolocator();
      GeolocatorPlatform.instance = fake;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() {
        GeolocatorPlatform.instance = original;
        debugDefaultTargetPlatformOverride = null;
      });

      final source = GeolocatorTripPositionSource();
      expect(await source.prepare(), isFalse);
      await source.watch().drain<void>();
      expect(fake.settings, isA<WebSettings>());
      expect(fake.settings, isNot(isA<AndroidSettings>()));
    },
    skip: !kIsWeb,
  );
}

class _BrowserGeolocator extends GeolocatorPlatform {
  LocationSettings? settings;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    settings = locationSettings;
    return const Stream.empty();
  }
}
