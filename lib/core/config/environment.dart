class Environment {
  Environment._();

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  // Google's demo map ID enables advanced markers during development.
  static const String googleMapsWebMapId = String.fromEnvironment(
    'GOOGLE_MAPS_WEB_MAP_ID',
    defaultValue: 'DEMO_MAP_ID',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is not configured. '
        'Run with --dart-define-from-file=config/dev.json',
      );
    }

    return _apiBaseUrl.endsWith('/') ? _apiBaseUrl : '$_apiBaseUrl/';
  }
}
