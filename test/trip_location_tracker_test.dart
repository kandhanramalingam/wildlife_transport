import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/core/error/failure.dart';
import 'package:wildlife_transport/core/location/location_queue_store.dart';
import 'package:wildlife_transport/core/location/trip_location_tracker.dart';
import 'package:wildlife_transport/core/location/trip_position_source.dart';
import 'package:wildlife_transport/features/delivery/domain/delivery_repository.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/models/location_tracking.dart';
import 'package:wildlife_transport/features/delivery/models/start_delivery_submission.dart';

void main() {
  test(
    'queues an offline reading from immutable storage and flushes on retry',
    () async {
      final repository = _LocationRepository()..offline = true;
      final store = _MemoryQueueStore();
      final source = _PositionSource(
        TripPosition(
          latitude: -25.7461,
          longitude: 28.1881,
          accuracyMetres: 9,
          recordedAt: DateTime.utc(2026, 8, 30, 10),
        ),
      );
      final tracker = TripLocationTracker(
        repository,
        store,
        positionSource: source,
      );

      await tracker.start('delivery-1');

      expect(tracker.isActive, isTrue);
      expect(tracker.pendingCount, 1);
      expect(store.readings, hasLength(1));

      repository.offline = false;
      await tracker.flushPending();

      expect(repository.uploaded, hasLength(1));
      expect(repository.uploaded.single.deliveryId, 'delivery-1');
      expect(tracker.pendingCount, 0);
      expect(tracker.warningMessage, isNull);
      expect(store.readings, isEmpty);
      await tracker.stop();
      await source.close();
    },
  );

  test(
    'throttles streamed locations to approximately thirty minutes',
    () async {
      final repository = _LocationRepository();
      final store = _MemoryQueueStore();
      final start = DateTime.utc(2026, 8, 30, 10);
      final source = _PositionSource(
        TripPosition(
          latitude: -25.7461,
          longitude: 28.1881,
          accuracyMetres: 9,
          recordedAt: start,
        ),
      );
      final tracker = TripLocationTracker(
        repository,
        store,
        positionSource: source,
      );

      await tracker.start('delivery-1');
      source.add(
        TripPosition(
          latitude: -25.75,
          longitude: 28.19,
          accuracyMetres: 8,
          recordedAt: start.add(const Duration(minutes: 10)),
        ),
      );
      source.add(
        TripPosition(
          latitude: -25.8,
          longitude: 28.2,
          accuracyMetres: 7,
          recordedAt: start.add(const Duration(minutes: 31)),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repository.uploaded, hasLength(2));
      expect(repository.uploaded.last.latitude, -25.8);
      await tracker.stop();
      await source.close();
    },
  );
}

class _MemoryQueueStore implements LocationQueueStore {
  List<DriverLocationReading> readings = [];

  @override
  Future<List<DriverLocationReading>> load() async => List.unmodifiable(readings);

  @override
  Future<void> replace(List<DriverLocationReading> readings) async {
    this.readings = List.of(readings);
  }
}

class _PositionSource implements TripPositionSource {
  final TripPosition initial;
  final _controller = StreamController<TripPosition>.broadcast();

  _PositionSource(this.initial);

  @override
  Future<bool> prepare() async => true;

  @override
  Future<TripPosition> current() async => initial;

  @override
  Stream<TripPosition> watch() => _controller.stream;

  void add(TripPosition position) => _controller.add(position);

  Future<void> close() => _controller.close();
}

class _LocationRepository implements DeliveryRepository {
  bool offline = false;
  final uploaded = <DriverLocationReading>[];

  @override
  Future<void> submitDriverLocation(DriverLocationReading reading) async {
    if (offline) throw const NetworkFailure();
    uploaded.add(reading);
  }

  @override
  Future<SavedCustomerLocation> saveCustomerLocation(
    CustomerLocationCapture capture,
  ) => throw UnimplementedError();

  @override
  Future<List<DeliveryModel>> getTodaySchedule({
    CancelToken? cancelToken,
  }) async => const [];

  @override
  Future<List<DeliveryModel>> getUpcomingSchedule({
    CancelToken? cancelToken,
  }) async => const [];

  @override
  Future<DeliveryModel?> updateStatus(
    String deliveryId,
    DeliveryStatusUpdate status, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> startLoading(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> completeLoading(
    String deliveryId,
    StartDeliverySubmission submission, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> startTrip(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> atDeliveryLocation(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> startOffloading(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> completeOffloading(
    String deliveryId,
    CompleteOffloadingSubmission submission, {
    String? vehicleId,
  }) async => null;
}
