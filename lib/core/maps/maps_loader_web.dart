import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('awaGoogleMapsReady')
external set _mapsReady(JSFunction callback);

Future<void>? _loading;
Future<void> loadGoogleMaps(String key) => _loading ??= _load(key);

Future<void> _load(String key) async {
  final ready = Completer<void>();
  _mapsReady = (() {
    if (!ready.isCompleted) ready.complete();
  }).toJS;
  final script = web.HTMLScriptElement()
    ..src = Uri.https('maps.googleapis.com', '/maps/api/js', {
      'key': key,
      'loading': 'async',
      'callback': 'awaGoogleMapsReady',
      'libraries': 'marker',
    }).toString()
    ..async = true;
  script.onerror = ((web.Event event) {
    if (!ready.isCompleted) {
      ready.completeError(StateError('Could not load Google Maps'));
    }
  }).toJS;
  web.document.head!.append(script);
  try {
    // The Google callback, not the script load event, signals API readiness.
    await ready.future.timeout(const Duration(seconds: 20));
  } catch (_) {
    script.remove();
    _loading = null;
    rethrow;
  } finally {
    _mapsReady = (() {}).toJS;
  }
}
