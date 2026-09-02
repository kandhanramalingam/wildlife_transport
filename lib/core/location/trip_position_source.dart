import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'current_location.dart';

class TripPosition {
  final double latitude;
  final double longitude;
  final double accuracyMetres;
  final DateTime recordedAt;

  const TripPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    required this.recordedAt,
  });

  factory TripPosition.fromGeolocator(Position position) => TripPosition(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracyMetres: position.accuracy,
    recordedAt: position.timestamp.toUtc(),
  );
}

abstract interface class TripPositionSource {
  Future<bool> prepare();
  Future<TripPosition> current();
  Stream<TripPosition> watch();
}

class GeolocatorTripPositionSource implements TripPositionSource {
  static const trackingInterval = Duration(minutes: 30);

  @override
  Future<bool> prepare() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const CurrentLocationException(
        'Turn on location services to track the active delivery.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const CurrentLocationException(
        'Location permission is required to track the active delivery.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const CurrentLocationException(
        'Enable location permission in device settings to track deliveries.',
      );
    }
    if (Platform.isAndroid) {
      final notificationPermission = await Permission.notification.status;
      if (notificationPermission.isDenied) {
        await Permission.notification.request();
      }
    }
    return permission == LocationPermission.always;
  }

  @override
  Future<TripPosition> current() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return TripPosition.fromGeolocator(position);
  }

  @override
  Stream<TripPosition> watch() {
    return Geolocator.getPositionStream(
      locationSettings: _settings(),
    ).map(TripPosition.fromGeolocator);
  }

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
        intervalDuration: trackingInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Active delivery tracking',
          notificationText:
              'AWA Transport is sharing your location for the active delivery.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
  }
}
