import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildlife_transport/features/delivery/screens/customer_directions_screen.dart';
import 'package:wildlife_transport/features/delivery/widgets/client_contact_row.dart';

void main() {
  final originalLocation = GeolocatorPlatform.instance;
  setUp(() => GeolocatorPlatform.instance = _UnavailableLocation());
  tearDown(() => GeolocatorPlatform.instance = originalLocation);
  testWidgets(
    'directions opens an embedded screen without an external launcher',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClientContactRow(
              contactNumber: '',
              showNavigation: true,
              destinationLatitude: '13.0836939',
              destinationLongitude: '80.270186',
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Open Google Maps directions'));
      await tester.pumpAndSettle();
      expect(find.byType(CustomerDirectionsScreen), findsOneWidget);
      expect(find.text('Google Maps is not configured yet.'), findsOneWidget);
      expect(find.text('Start navigation'), findsOneWidget);
      expect(
        find.text('Turn on location services, then retry.'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ClientContactRow), findsOneWidget);
    },
  );

  testWidgets('invalid coordinates do not open a route', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClientContactRow(
            contactNumber: '',
            showNavigation: true,
            destinationLatitude: 'NaN',
            destinationLongitude: '80',
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Open Google Maps directions'));
    await tester.pump();
    expect(find.byType(CustomerDirectionsScreen), findsNothing);
    expect(
      find.text('Customer latitude and longitude are unavailable.'),
      findsOneWidget,
    );
  });
}

class _UnavailableLocation extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => false;
}
