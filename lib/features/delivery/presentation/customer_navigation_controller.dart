import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/driving_route.dart';

typedef RouteLoader =
    Future<DrivingRoute> Function(LatLng origin, LatLng destination);

class CustomerNavigationController extends ChangeNotifier {
  final LatLng destination;
  final RouteLoader loadRoute;
  final Future<Position> Function() currentPosition;
  final Stream<Position> Function() watchPosition;
  final DateTime Function() now;
  StreamSubscription<Position>? _subscription;
  bool _disposed = false;
  int _generation = 0;
  DateTime? _lastRequest;
  LatLng? _routeOrigin;
  DateTime? _lastFix;
  double _progress = 0;
  bool loading = false;
  bool navigating = false;
  bool arrived = false;
  String? error;
  LatLng? position;
  double heading = 0;
  DrivingRoute? route;

  CustomerNavigationController({
    required this.destination,
    required this.loadRoute,
    Future<Position> Function()? currentPosition,
    Stream<Position> Function()? watchPosition,
    DateTime Function()? now,
  }) : currentPosition = currentPosition ?? _current,
       watchPosition = watchPosition ?? _watch,
       now = now ?? DateTime.now;

  static Future<Position> _current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Turn on location services, then retry.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Allow location access in your browser or device settings, then retry.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  static Stream<Position> _watch() => Geolocator.getPositionStream(
    locationSettings: kIsWeb
        ? WebSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
  );

  double get remainingMetres =>
      arrived ? 0 : math.max(0, (route?.distanceMetres ?? 0) - _progress);
  double get remainingSeconds => arrived
      ? 0
      : (route?.durationSeconds ?? 0) *
            (route == null || route!.distanceMetres == 0
                ? 1
                : remainingMetres / route!.distanceMetres);
  int get stepIndex {
    var covered = 0.0;
    final steps = route?.steps ?? [];
    for (var i = 0; i < steps.length; i++) {
      covered += steps[i].distanceMetres;
      if (_progress < covered || i == steps.length - 1) return i;
    }
    return 0;
  }

  String get instruction => arrived
      ? 'You are at the customer location'
      : route == null
      ? 'Finding a driving route from your location'
      : route!.steps.isNotEmpty
      ? route!.steps[stepIndex].instruction
      : route!.instructions.isNotEmpty
      ? route!.instructions.first
      : 'Continue to the customer location';
  double get stepRemainingMetres => route == null || route!.steps.isEmpty
      ? remainingMetres
      : math.max(
          0,
          route!.steps
                  .take(stepIndex + 1)
                  .fold<double>(0, (sum, s) => sum + s.distanceMetres) -
              _progress,
        );

  Future<void> refresh() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    notifyListeners();
    final generation = _generation;
    var locating = true;
    try {
      final fix = await currentPosition().timeout(const Duration(seconds: 25));
      if (_disposed || generation != _generation) return;
      if (!_acceptPosition(fix)) {
        throw StateError('Waiting for an accurate GPS location. Please retry.');
      }
      locating = false;
      notifyListeners();
      await _requestRoute(generation);
    } catch (e) {
      if (!_disposed && generation == _generation) {
        error = _message(e, locating: locating);
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> start() async {
    if (navigating || loading || _disposed) return;
    await refresh(); // Always start from a fresh GPS fix, not the preview's origin.
    if (_disposed || error != null || route == null) return;
    arrived = false;
    navigating = true;
    try {
      _subscription = watchPosition().listen(
        _onPosition,
        onError: (Object e) {
          if (!_disposed) {
            error =
                'GPS updates interrupted. Stop and restart navigation to retry.';
            notifyListeners();
          }
        },
        onDone: () {
          if (!_disposed && navigating) {
            navigating = false;
            error = 'Location updates stopped. Start navigation again.';
            notifyListeners();
          }
        },
      );
    } catch (e) {
      navigating = false;
      error = _message(e);
    }
    notifyListeners();
  }

  void stop() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
    navigating = false;
    loading = false;
    notifyListeners();
  }

  bool _acceptPosition(Position fix) {
    if (!fix.latitude.isFinite ||
        !fix.longitude.isFinite ||
        fix.latitude.abs() > 90 ||
        fix.longitude.abs() > 180 ||
        !fix.accuracy.isFinite ||
        fix.accuracy > 100 ||
        fix.accuracy < 0 ||
        now().difference(fix.timestamp) > const Duration(minutes: 1) ||
        (_lastFix != null && fix.timestamp.isBefore(_lastFix!))) {
      return false;
    }
    _lastFix = fix.timestamp;
    position = LatLng(fix.latitude, fix.longitude);
    if (fix.heading.isFinite && fix.heading >= 0) heading = fix.heading;
    return true;
  }

  Future<void> _onPosition(Position fix) async {
    if (_disposed || !navigating || !_acceptPosition(fix)) return;
    final point = position!;
    if (fix.accuracy <= 30 && _distance(point, destination) <= 35) {
      arrived = true;
      stop();
      return;
    }
    final match = route == null ? null : _match(point, route!.points);
    if (match != null && match.total > 0 && match.offset < 60) {
      _progress = math.max(
        _progress,
        route!.distanceMetres * match.along / match.total,
      );
    }
    notifyListeners();
    // Bound API usage while keeping a moving driver's route and ETA fresh.
    if (!loading &&
        (_lastRequest == null ||
            now().difference(_lastRequest!) >= const Duration(seconds: 30)) &&
        (_routeOrigin == null || _distance(point, _routeOrigin!) >= 25)) {
      loading = true;
      notifyListeners();
      final generation = _generation;
      try {
        await _requestRoute(generation);
      } catch (e) {
        if (!_disposed && generation == _generation) error = _message(e);
      } finally {
        if (!_disposed && generation == _generation) {
          loading = false;
          notifyListeners();
        }
      }
    }
  }

  Future<void> _requestRoute(int generation) async {
    final origin = position;
    if (origin == null) {
      throw StateError('Waiting for an accurate GPS location. Please retry.');
    }
    _lastRequest = now();
    final result = await loadRoute(origin, destination);
    if (_disposed || generation != _generation) return;
    route = result;
    _routeOrigin = origin;
    _progress = 0;
    error = null;
    if (position != null) {
      final match = _match(position!, result.points);
      if (match.total > 0 && match.offset < 60) {
        _progress = result.distanceMetres * match.along / match.total;
      }
    }
  }

  static String _message(Object error, {bool locating = false}) {
    if (error is PermissionDeniedException) {
      return 'Location access is blocked. Allow location for this site and for your browser in device settings, then retry.';
    }
    if (error is LocationServiceDisabledException) {
      return 'Location services are off. Turn them on in device settings, then retry.';
    }
    if (error is TimeoutException && locating) {
      return 'Your current location could not be found in time. Check browser and device location permissions, keep this page open, then retry.';
    }
    if (error is PositionUpdateException) {
      return 'Your device could not determine its location. Enable location services and try again where GPS or Wi-Fi is available.';
    }
    if (error is StateError) return error.message.toString();
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'In-app directions took too long to respond. Retry, or open Google Maps to continue.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.response == null) {
        return 'In-app directions could not connect. Check your internet connection and retry, or open Google Maps to continue.';
      }
      final status = error.response?.statusCode;
      if (status == 503) {
        return 'In-app directions are temporarily unavailable. You can still open Google Maps to navigate to this customer.';
      }
      if (status == 404) {
        final data = error.response?.data;
        final message = data is Map ? data['message']?.toString() ?? '' : '';
        if (message.contains('Cannot POST')) {
          return 'In-app directions are temporarily unavailable. You can still open Google Maps to navigate to this customer.';
        }
        return 'No driving route was found to this customer pin. Check the saved location and retry.';
      }
      if (status == 401) {
        return 'Your session expired. Sign in again to load directions.';
      }
      if (status == 502) {
        return 'Google Maps could not calculate the in-app route. Retry, or open Google Maps to continue.';
      }
    }
    if (error is FormatException || error is TypeError) {
      return 'In-app directions returned an invalid route. Retry, or open Google Maps to continue.';
    }
    return locating
        ? 'Could not obtain your current location. Allow browser and device location access, then retry.'
        : 'The driving route could not be loaded. Retry, or open Google Maps to continue.';
  }

  static double _distance(LatLng a, LatLng b) => Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );

  // Project the GPS point onto each route segment to measure travelled road distance.
  static ({double along, double total, double offset}) _match(
    LatLng point,
    List<LatLng> points,
  ) {
    var total = 0.0, along = 0.0, closest = double.infinity;
    final scale = math.cos(point.latitude * math.pi / 180);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final dx = (b.longitude - a.longitude) * scale,
          dy = b.latitude - a.latitude;
      final px = (point.longitude - a.longitude) * scale,
          py = point.latitude - a.latitude;
      final length = _distance(a, b);
      final denominator = dx * dx + dy * dy;
      final t = denominator == 0
          ? 0.0
          : ((px * dx + py * dy) / denominator).clamp(0.0, 1.0);
      final projected = LatLng(
        a.latitude + dy * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      final offset = _distance(point, projected);
      if (offset < closest) {
        closest = offset;
        along = total + length * t;
      }
      total += length;
    }
    return (along: along, total: total, offset: closest);
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }
}
