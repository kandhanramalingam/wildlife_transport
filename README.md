# AWA Transport

## Development

Run the app with the development API configuration:

```sh
flutter run --dart-define-from-file=config/dev.json
```
flutter run -d chrome \
  --dart-define-from-file=config/dev.json \
  --dart-define-from-file=config/maps.local.json
  


Build a development APK with the same configuration:

```sh
flutter build apk --debug --dart-define-from-file=config/dev.json \
--dart-define-from-file=config/maps.local.json
```

The configured base URL is `http://transport.wildlifeauctions.co.za:8081`.
Environment URLs live in configuration files and are supplied as compile-time
defines rather than being hardcoded in Dart source.

## Embedded Google Maps

Customer directions and customer-pin confirmation use Google Maps inside the app.
Directions include a persistent distance/ETA panel and a Start navigation button.
Starting obtains a fresh GPS fix, follows the driver on the map, updates estimated
remaining road distance and written instructions, and refreshes the route at most
once every 30 seconds while moving. Route overview and all instructions remain
available. Arrival is detected within 35 metres with GPS accuracy of 30 metres or
better; delivery status still requires the driver's normal confirmation.
Keep the screen open for live navigation, especially in a browser. This flow uses
GPS and Routes API estimates; it does not provide voice guidance or Google
Navigation SDK lane guidance. A network failure retains the last route and shows
a retry message.

Enable Maps SDK for Android, Maps SDK for iOS and Maps JavaScript API for the
platforms you use. Create a separate restricted key per platform. Put the appropriate
key in a local ignored file `config/maps.local.json`:

```json
{"GOOGLE_MAPS_API_KEY": "your-platform-specific-key"}
```

```sh
flutter run --dart-define-from-file=config/dev.json --dart-define-from-file=config/maps.local.json
```

The same Dart define configures Android's manifest, iOS SDK initialization and
web JavaScript loading. Rebuild native apps when changing keys; hot reload is not
enough. Minimum platform versions: Android API 24, iOS 14.

On the backend enable Google Routes API and set `GOOGLE_ROUTES_API_KEY` in the
server environment, then restart the backend. This server key must never be put
in the Flutter configuration. Restrict it to Routes API and the server's IPs.
The authenticated `POST /driver-auth/directions` endpoint computes the route.
Google Cloud billing must be enabled for the selected Maps APIs.

Without the Maps key, the app displays a configuration message instead of creating
a native map. GPS, network or routing failures show a retry option. The pin can
still be saved from its captured GPS coordinates.

References: [Flutter Google Maps](https://pub.dev/packages/google_maps_flutter),
[Google Routes API](https://developers.google.com/maps/documentation/routes/compute_route_directions).

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

### Web Maps loading and markers

The web map loads asynchronously using Google's readiness callback and uses
advanced markers. `GOOGLE_MAPS_WEB_MAP_ID` selects your Google Cloud JavaScript
map ID. It defaults to Google's `DEMO_MAP_ID` for development; configure your own
map ID in `config/maps.local.json` for production.

If the API responds with `Cannot POST /driver-auth/directions`, deploy the updated
backend (including `GoogleDirectionsController` in `DriverAuthModule`) and restart
its process. Changing a Flutter Maps key cannot add a missing server endpoint.
