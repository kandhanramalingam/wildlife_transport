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
