import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_remote_data_source.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_repository_impl.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_schedule_dto.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/models/location_tracking.dart';
import 'package:wildlife_transport/features/delivery/models/start_delivery_submission.dart';

void main() {
  test('completing off-loading persists the completed status', () async {
    final dataSource = _RecordingDeliveryDataSource();
    final repository = DeliveryRepositoryImpl(dataSource);

    await repository.completeOffloading(
      'delivery-1',
      CompleteOffloadingSubmission(
        endAnimalPhotos: [
          XFile.fromData(Uint8List.fromList([1]), name: 'animal.jpg'),
        ],
        endAnimalVideos: XFile.fromData(
          Uint8List.fromList([2]),
          name: 'offloading.mp4',
        ),
        offLoadChecklist: const [
          DeliveryChecklistItem(item: 'Animals checked', checked: true),
        ],
        clientSignature: Uint8List.fromList([3]),
        endOdometerReading: 1200,
        buyerId: 'buyer-1',
      ),
      vehicleId: 'vehicle-1',
    );

    expect(dataSource.endedDeliveryId, 'delivery-1');
    expect(dataSource.statusUpdates, [
      ('delivery-1', DeliveryStatusUpdate.completed, 'vehicle-1'),
    ]);
  });
}

class _RecordingDeliveryDataSource implements DeliveryRemoteDataSource {
  String? endedDeliveryId;
  final statusUpdates = <(String, DeliveryStatusUpdate, String?)>[];

  @override
  Future<void> endDelivery(String deliveryId, Map<String, dynamic> body) async {
    endedDeliveryId = deliveryId;
  }

  @override
  Future<void> updateStatus(
    String deliveryId,
    DeliveryStatusUpdate status, {
    String? vehicleId,
  }) async {
    statusUpdates.add((deliveryId, status, vehicleId));
  }

  @override
  Future<String> uploadImage(List<int> bytes, String filename) async =>
      'uploads/$filename';

  @override
  Future<String> uploadVideo(List<int> bytes, String filename) async =>
      'uploads/$filename';

  @override
  Future<List<DeliveryScheduleDto>> getTodaySchedule({
    CancelToken? cancelToken,
  }) async => const [];

  @override
  Future<List<DeliveryScheduleDto>> getUpcomingSchedule({
    CancelToken? cancelToken,
  }) async => const [];

  @override
  Future<void> startDelivery(
    String deliveryId,
    Map<String, dynamic> body,
  ) async {}

  @override
  Future<void> submitDriverLocation(DriverLocationReading reading) async {}

  @override
  Future<Map<String, dynamic>> saveCustomerLocation(
    CustomerLocationCapture capture,
  ) async => {
    'clientId': 'client-1',
    'buyerId': capture.buyerId,
    'latitude': capture.latitude,
    'longitude': capture.longitude,
    'accuracyMetres': capture.accuracyMetres,
    'capturedAt': capture.capturedAt.toIso8601String(),
  };
}
