import 'dart:async';

import 'package:flutter/foundation.dart';

import '../error/failure.dart';
import '../../features/delivery/domain/delivery_repository.dart';
import '../../features/delivery/models/location_tracking.dart';
import 'location_queue_store.dart';
import 'trip_position_source.dart';

class TripLocationTracker extends ChangeNotifier {
  static const trackingInterval = Duration(minutes: 30);
  static const maxQueuedReadings = 500;
  static const webTrackingNotice =
      'Keep this browser tab open and your screen awake during delivery. '
      'Tracking may pause when the browser is in the background.';

  final DeliveryRepository _repository;
  final LocationQueueStore _queueStore;
  final TripPositionSource _positionSource;

  StreamSubscription<TripPosition>? _positionSubscription;
  List<DriverLocationReading>? _queue;
  DateTime? _lastRecordedAt;
  bool _flushing = false;
  int _generation = 0;

  String? activeDeliveryId;
  DateTime? lastUploadedAt;
  int pendingCount = 0;
  String? warningMessage;
  bool backgroundPermissionGranted = false;

  TripLocationTracker(
    this._repository,
    this._queueStore, {
    TripPositionSource? positionSource,
  }) : _positionSource = positionSource ?? GeolocatorTripPositionSource();

  bool get isActive => activeDeliveryId != null;

  Future<void> start(String deliveryId) async {
    final normalizedId = deliveryId.trim();
    if (normalizedId.isEmpty) return;
    if (activeDeliveryId == normalizedId && _positionSubscription != null) {
      await flushPending();
      return;
    }

    await stop();
    activeDeliveryId = normalizedId;
    final generation = ++_generation;
    warningMessage = null;
    notifyListeners();

    try {
      await _ensureQueue();
      backgroundPermissionGranted = await _positionSource.prepare();
      if (!backgroundPermissionGranted) {
        warningMessage = kIsWeb
            ? webTrackingNotice
            : defaultTargetPlatform == TargetPlatform.iOS
            ? 'Background location is limited. Keep the app open or choose '
                  '“Always” for Location in the app’s device settings.'
            : 'Background location is limited. Keep the app open or enable '
                  '“Allow all the time” in device settings.';
      }
      if (generation != _generation || activeDeliveryId != normalizedId) return;
      await flushPending();
      try {
        await _record(await _positionSource.current(), normalizedId);
      } catch (error) {
        warningMessage = _messageOf(error);
        notifyListeners();
      }
      if (generation != _generation || activeDeliveryId != normalizedId) return;
      _positionSubscription = _positionSource.watch().listen(
        (position) => _record(position, normalizedId),
        onError: (Object error) {
          warningMessage = _messageOf(error);
          notifyListeners();
        },
      );
    } catch (error) {
      warningMessage = _messageOf(error);
      notifyListeners();
    }
  }

  Future<void> stop({String? deliveryId}) async {
    if (deliveryId != null && activeDeliveryId != deliveryId) return;
    _generation++;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    activeDeliveryId = null;
    _lastRecordedAt = null;
    backgroundPermissionGranted = false;
    warningMessage = null;
    notifyListeners();
  }

  Future<void> flushPending() async {
    await _ensureQueue();
    if (_flushing) return;
    _flushing = true;
    try {
      while (_queue!.isNotEmpty) {
        final reading = _queue!.first;
        try {
          await _repository.submitDriverLocation(reading);
        } catch (error) {
          warningMessage = _messageOf(error);
          notifyListeners();
          break;
        }
        _queue!.removeAt(0);
        await _queueStore.replace(_queue!);
        pendingCount = _queue!.length;
        lastUploadedAt = DateTime.now().toUtc();
        warningMessage = null;
        notifyListeners();
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _record(TripPosition position, String deliveryId) async {
    if (activeDeliveryId != deliveryId) return;
    final lastRecordedAt = _lastRecordedAt;
    if (lastRecordedAt != null &&
        position.recordedAt.difference(lastRecordedAt) < trackingInterval) {
      return;
    }
    if (!_valid(position)) return;
    _lastRecordedAt = position.recordedAt;
    await _ensureQueue();
    _queue!.add(
      DriverLocationReading(
        localId: '$deliveryId-${position.recordedAt.microsecondsSinceEpoch}',
        deliveryId: deliveryId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracyMetres,
        recordedAt: position.recordedAt,
      ),
    );
    _queue!.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (_queue!.length > maxQueuedReadings) {
      _queue!.removeRange(0, _queue!.length - maxQueuedReadings);
    }
    await _queueStore.replace(_queue!);
    pendingCount = _queue!.length;
    notifyListeners();
    await flushPending();
  }

  Future<void> _ensureQueue() async {
    if (_queue != null) return;
    // Storage may return an immutable list, including an empty const list.
    _queue = List<DriverLocationReading>.of(await _queueStore.load());
    pendingCount = _queue!.length;
    notifyListeners();
  }

  bool _valid(TripPosition position) =>
      position.latitude.isFinite &&
      position.longitude.isFinite &&
      position.accuracyMetres.isFinite &&
      position.latitude >= -90 &&
      position.latitude <= 90 &&
      position.longitude >= -180 &&
      position.longitude <= 180 &&
      position.accuracyMetres >= 0;

  String _messageOf(Object error) {
    if (error is Failure) return error.message;
    final value = error.toString().trim();
    return value.isEmpty
        ? 'Location tracking is temporarily unavailable.'
        : value;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
