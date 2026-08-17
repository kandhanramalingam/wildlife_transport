import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/widgets/client_contact_row.dart';

void main() {
  test('builds Google Maps driving directions from current location', () {
    final uri = buildGoogleMapsDirectionsUri(
      originLatitude: 13.0827,
      originLongitude: 80.2707,
      destinationLatitude: 13.1067,
      destinationLongitude: 80.097,
    );

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters, {
      'api': '1',
      'origin': '13.0827,80.2707',
      'destination': '13.1067,80.097',
      'travelmode': 'driving',
    });
  });
}
