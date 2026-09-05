import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildlife_transport/features/delivery/models/driving_route.dart';

void main() {
  test('converts Google GeoJSON longitude/latitude into map coordinates', () {
    final route = DrivingRoute.fromJson({
      'coordinates': [
        [80.27, 13.08],
        [80.28, 13.09],
      ],
      'distanceMetres': 1500,
      'durationSeconds': 180,
      'instructions': ['Turn left'],
      'warnings': [],
    });
    expect(route.points, [
      const LatLng(13.08, 80.27),
      const LatLng(13.09, 80.28),
    ]);
    expect(route.durationSeconds, 180);
    expect(route.instructions, ['Turn left']);
  });
  test('rejects empty routes', () {
    expect(
      () => DrivingRoute.fromJson({'coordinates': []}),
      throwsFormatException,
    );
  });
}
