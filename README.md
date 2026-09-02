# AWA Transport

## Development

Run the app with the development API configuration:

```sh
flutter run --dart-define-from-file=config/dev.json
```

Build a development APK with the same configuration:

```sh
flutter build apk --debug --dart-define-from-file=config/dev.json
```

The configured base URL is `http://transport.wildlifeauctions.co.za:8081`.
Environment URLs live in configuration files and are supplied as compile-time
defines rather than being hardcoded in Dart source.

`OSM_TILE_URL` configures the OpenStreetMap-compatible tile provider used by
the customer-pin preview. The default development value uses the standard OSM
tile endpoint. Production should use an approved OSM-derived provider or a
self-hosted tile service with appropriate availability terms.

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
