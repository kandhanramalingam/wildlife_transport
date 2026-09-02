import 'package:geolocator/geolocator.dart';

class CurrentCoordinates {
  final String latitude;
  final String longitude;
  final double accuracyMetres;
  final DateTime recordedAt;

  const CurrentCoordinates({
    required this.latitude,
    required this.longitude,
    this.accuracyMetres = 0,
    required this.recordedAt,
  });
}

class CurrentLocationException implements Exception {
  final String message;

  const CurrentLocationException(this.message);

  @override
  String toString() => message;
}

Future<CurrentCoordinates> getCurrentCoordinates() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const CurrentLocationException(
      'Turn on location services to start the trip.',
    );
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw const CurrentLocationException(
      'Location permission is required to start the trip.',
    );
  }
  if (permission == LocationPermission.deniedForever) {
    throw const CurrentLocationException(
      'Enable location permission in device settings to start the trip.',
    );
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return CurrentCoordinates(
      latitude: position.latitude.toStringAsFixed(6),
      longitude: position.longitude.toStringAsFixed(6),
      accuracyMetres: position.accuracy,
      recordedAt: position.timestamp.toUtc(),
    );
  } catch (_) {
    throw const CurrentLocationException(
      'Could not get the current location. Please try again.',
    );
  }
}
