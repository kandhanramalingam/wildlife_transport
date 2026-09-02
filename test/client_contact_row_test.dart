import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/widgets/client_contact_row.dart';

void main() {
  test('builds OpenStreetMap driving directions from current location', () {
    final uri = buildOpenStreetMapDirectionsUri(
      originLatitude: 13.0827,
      originLongitude: 80.2707,
      destinationLatitude: 13.1067,
      destinationLongitude: 80.097,
    );

    expect(uri.host, 'www.openstreetmap.org');
    expect(uri.path, '/directions');
    expect(uri.queryParameters, {
      'engine': 'fossgis_osrm_car',
      'route': '13.0827,80.2707;13.1067,80.097',
    });
  });
}
