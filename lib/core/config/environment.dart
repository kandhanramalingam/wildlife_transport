class Environment {
  Environment._();

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String osmTileUrl = String.fromEnvironment(
    'OSM_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
