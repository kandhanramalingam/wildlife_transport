import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/core/error/failure.dart';
import 'package:wildlife_transport/features/delivery/domain/delivery_repository.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/models/location_tracking.dart';
import 'package:wildlife_transport/features/delivery/models/start_delivery_submission.dart';
import 'package:wildlife_transport/features/delivery/presentation/today_deliveries_controller.dart';

void main() {
  test(
    'keeps uploaded photos and videos through loading and trip start',
    () async {
      final controller = TodayDeliveriesController(_ScheduleRepository([]));
      controller.deliveries = [
        _completedDelivery.copyWith(status: DeliveryStatus.loading),
      ];
      final uploaded = _completedDelivery.copyWith(
        startVehiclePhotos: ['uploads/vehicle.jpg'],
        startAnimalPhotos: ['uploads/animals.jpg'],
        onLoadAnimalsVideos: ['uploads/animals.mp4'],
        startMediaMetadata: const [
          DeliveryLoadingMedia(
            filePath: 'uploads/animals.mp4',
            kind: 'animal_video',
            lotNumber: '101',
          ),
        ],
      );
      controller.mergeLoadingMedia(_completedDelivery.id, uploaded);
      controller.markTripStarted(_completedDelivery.id);
      // A status-only reply must not wipe the evidence saved after loading.
      controller.mergeLoadingMedia(_completedDelivery.id, _completedDelivery);
      final active = controller.deliveries.single;
      expect(active.status, DeliveryStatus.inProgress);
      expect(active.startVehiclePhotos, ['uploads/vehicle.jpg']);
      expect(active.startAnimalPhotos, ['uploads/animals.jpg']);
      expect(active.onLoadAnimalsVideos, ['uploads/animals.mp4']);
      expect(active.startMediaMetadata.single.lotNumber, '101');
      expect(active.lots, _completedDelivery.lots);
      controller.dispose();
    },
  );

  test('a superseded request cannot show a cancellation error', () async {
    final repository = _OverlappingScheduleRepository();
    final controller = TodayDeliveriesController(repository);

    final firstLoad = controller.load();
    await Future<void>.delayed(Duration.zero);
    final secondLoad = controller.load();
    await Future<void>.delayed(Duration.zero);

    expect(controller.isLoading, isTrue);
    expect(controller.errorMessage, isNull);

    repository.latestRequest.complete([_completedDelivery]);
    await Future.wait([firstLoad, secondLoad]);

    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
    expect(controller.deliveries, [_completedDelivery]);
    controller.dispose();
  });

  test(
    'queued offloading stays awaiting sync instead of server-completed after reload',
    () async {
      final repository = _ScheduleRepository([
        DeliveryModel(
          id: 'trip-1',
          dateTime: DateTime(2026, 9, 30),
          clientName: 'Buyer',
          clientAddress: 'Farm',
          status: DeliveryStatus.offloading,
          lots: const [
            DeliveryLot(
              clientName: 'Buyer',
              buyerId: 'buyer-1',
              mainBuyer: true,
              deliveryId: 'delivery-queued',
              address: 'Farm',
              status: DeliveryStatus.offloading,
            ),
          ],
        ),
      ]);
      final controller = TodayDeliveriesController(
        repository,
        pendingOffloadingIds: () => {'delivery-queued'},
      );

      await controller.load();

      expect(controller.deliveries.single.deliveryCompleted, isTrue);
      expect(controller.deliveries.single.status, DeliveryStatus.offloading);
      expect(controller.deliveries.single.completedDeliveryCount, 0);
      expect(
        controller.deliveries.single.deliveryProgressLabel,
        contains('Awaiting sync'),
      );
      expect(
        controller.deliveries.single.lots.single.offloadingSyncPending,
        isTrue,
      );
      controller.applyPendingOffloading({});
      expect(controller.deliveries.single.hasPendingOffloading, isFalse);
      controller.dispose();
    },
  );

  test('a queued single delivery keeps its server status', () async {
    final repository = _ScheduleRepository([
      _completedDelivery.copyWith(status: DeliveryStatus.offloading),
    ]);
    final controller = TodayDeliveriesController(
      repository,
      pendingOffloadingIds: () => {'delivery-1'},
    );
    await controller.load();
    expect(controller.deliveries.single.status, DeliveryStatus.offloading);
    expect(controller.deliveries.single.offloadingSyncPending, isTrue);
    expect(controller.deliveries.single.completedDeliveryCount, 0);
    controller.applyPendingOffloading({});
    expect(controller.deliveries.single.offloadingSyncPending, isFalse);
    controller.dispose();
  });
}

final _completedDelivery = DeliveryModel(
  id: 'delivery-1',
  dateTime: DateTime(2026, 8, 19),
  clientName: 'Buyer',
  clientAddress: 'Address',
  status: DeliveryStatus.completed,
);

class _OverlappingScheduleRepository implements DeliveryRepository {
  var requestCount = 0;
  late Completer<List<DeliveryModel>> latestRequest;

  @override
  Future<List<DeliveryModel>> getTodaySchedule({CancelToken? cancelToken}) {
    requestCount++;
    if (requestCount == 1) {
      return cancelToken!.whenCancel.then<List<DeliveryModel>>(
        (_) => throw const UnknownFailure('Request cancelled'),
      );
    }
    latestRequest = Completer<List<DeliveryModel>>();
    return latestRequest.future;
  }

  @override
  Future<List<DeliveryModel>> getUpcomingSchedule({
    CancelToken? cancelToken,
  }) async => const [];

  @override
  Future<DeliveryModel?> atDeliveryLocation(
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
  Future<DeliveryModel?> completeOffloading(
    String deliveryId,
    CompleteOffloadingSubmission submission, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> startLoading(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> startOffloading(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> startTrip(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> updateStatus(
    String deliveryId,
    DeliveryStatusUpdate status, {
    String? vehicleId,
  }) async => null;

  @override
  Future<void> submitDriverLocation(DriverLocationReading reading) async {}

  @override
  Future<SavedCustomerLocation> saveCustomerLocation(
    CustomerLocationCapture capture,
  ) async => SavedCustomerLocation(
    clientId: 'client-1',
    buyerId: capture.buyerId,
    latitude: capture.latitude,
    longitude: capture.longitude,
    accuracyMetres: capture.accuracyMetres,
    capturedAt: capture.capturedAt,
  );
}

class _ScheduleRepository extends _OverlappingScheduleRepository {
  final List<DeliveryModel> result;

  _ScheduleRepository(this.result);

  @override
  Future<List<DeliveryModel>> getTodaySchedule({
    CancelToken? cancelToken,
  }) async => result;
}
