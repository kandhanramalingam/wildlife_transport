import 'package:wildlife_transport/features/delivery/models/photo_meta.dart';
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

PhotoMeta capture(String name, int minute) => PhotoMeta(
  photo: XFile.fromData(Uint8List.fromList([minute]), name: name, path: name),
  dateTime: DateTime.parse(
    '2026-09-05T12:${minute.toString().padLeft(2, '0')}:00+05:30',
  ),
  latitude: -25.0 - minute,
  longitude: 28.0 + minute,
);

void main() {
  test(
    'loading associates distinct capture metadata with every uploaded file',
    () async {
      final source = _RecordingDeliveryDataSource();
      await DeliveryRepositoryImpl(source).completeLoading(
        'delivery-1',
        StartDeliverySubmission(
          startOdometerReading: 100,
          startVehiclePhotos: [
            capture('vehicle1.jpg', 1),
            capture('vehicle2.jpg', 2),
          ],
          startAnimalPhotos: [capture('animal.jpg', 3)],
          onLoadAnimalsVideo: capture('animals.mp4', 4),
          startLatitude: '-29',
          startLongitude: '32',
          vehicleChecklist: [],
          gameLoadingChecklist: [],
          managerSignature: Uint8List.fromList([5]),
          otherSignature: Uint8List.fromList([6]),
        ),
      );
      final metadata = source.startBody!['startMediaMetadata'] as List;
      expect(metadata.map((m) => m['filePath']), [
        'uploads/vehicle1.jpg',
        'uploads/vehicle2.jpg',
        'uploads/animal.jpg',
        'uploads/animals.mp4',
      ]);
      expect(metadata.map((m) => m['kind']), [
        'vehicle_photo',
        'vehicle_photo',
        'animal_photo',
        'animal_video',
      ]);
      expect(metadata.map((m) => m['latitude']), [-26.0, -27.0, -28.0, -29.0]);
      expect(metadata.map((m) => m['capturedAt']), [
        for (var i = 1; i <= 4; i++) '2026-09-05T06:3$i:00.000Z',
      ]);
    },
  );
  test('completing off-loading persists the completed status', () async {
    final dataSource = _RecordingDeliveryDataSource();
    final repository = DeliveryRepositoryImpl(dataSource);

    await repository.completeOffloading(
      'delivery-1',
      CompleteOffloadingSubmission(
        endAnimalPhotos: [capture('animal.jpg', 1)],
        endAnimalVideos: capture('offloading.mp4', 2),
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
    expect(dataSource.endBody?['endMediaMetadata'], [
      {
        'filePath': 'uploads/animal.jpg',
        'kind': 'animal_photo',
        'capturedAt': '2026-09-05T06:31:00.000Z',
        'latitude': -26.0,
        'longitude': 29.0,
      },
      {
        'filePath': 'uploads/offloading.mp4',
        'kind': 'animal_video',
        'capturedAt': '2026-09-05T06:32:00.000Z',
        'latitude': -27.0,
        'longitude': 30.0,
      },
    ]);
    expect(dataSource.statusUpdates, [
      ('delivery-1', DeliveryStatusUpdate.completed, 'vehicle-1'),
    ]);
  });
}

class _RecordingDeliveryDataSource implements DeliveryRemoteDataSource {
  String? endedDeliveryId;
  Map<String, dynamic>? startBody;
  Map<String, dynamic>? endBody;
  final statusUpdates = <(String, DeliveryStatusUpdate, String?)>[];

  @override
  Future<void> endDelivery(String deliveryId, Map<String, dynamic> body) async {
    endedDeliveryId = deliveryId;
    endBody = body;
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
  ) async {
    startBody = body;
  }

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
