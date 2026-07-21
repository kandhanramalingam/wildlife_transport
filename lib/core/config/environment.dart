class Environment {
  Environment._();

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

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
