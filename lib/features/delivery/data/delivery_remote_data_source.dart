import 'package:dio/dio.dart';

import '../models/delivery_model.dart';
import '../models/location_tracking.dart';
import 'delivery_schedule_dto.dart';

abstract interface class DeliveryRemoteDataSource {
  Future<List<DeliveryScheduleDto>> getTodaySchedule({
    CancelToken? cancelToken,
  });
  Future<List<DeliveryScheduleDto>> getUpcomingSchedule({
    CancelToken? cancelToken,
  });
  Future<String> uploadImage(List<int> bytes, String filename);
  Future<String> uploadVideo(List<int> bytes, String filename);
  Future<void> updateStatus(
    String deliveryId,
    DeliveryStatusUpdate status, {
    String? vehicleId,
  });
  Future<void> startDelivery(String deliveryId, Map<String, dynamic> body);
  Future<void> endDelivery(String deliveryId, Map<String, dynamic> body);
  Future<void> submitDriverLocation(DriverLocationReading reading);
  Future<Map<String, dynamic>> saveCustomerLocation(
    CustomerLocationCapture capture,
  );
}

class DioDeliveryRemoteDataSource implements DeliveryRemoteDataSource {
  final Dio _dio;
  final String? Function()? _authenticatedDriverId;

  const DioDeliveryRemoteDataSource(this._dio, [this._authenticatedDriverId]);

  @override
  Future<List<DeliveryScheduleDto>> getTodaySchedule({
    CancelToken? cancelToken,
  }) => _getSchedule('driver-auth/schedule/today', cancelToken);

  @override
  Future<List<DeliveryScheduleDto>> getUpcomingSchedule({
    CancelToken? cancelToken,
  }) => _getSchedule('driver-auth/schedule/upcoming', cancelToken);

  @override
  Future<String> uploadImage(List<int> bytes, String filename) =>
      _uploadFile('file/upload', bytes, filename);

  @override
  Future<String> uploadVideo(List<int> bytes, String filename) =>
      _uploadFile('file/upload-video', bytes, filename);

  @override
  Future<void> updateStatus(
    String deliveryId,
    DeliveryStatusUpdate status, {
    String? vehicleId,
  }) async {
    final normalizedVehicleId = vehicleId?.trim() ?? '';
    await _dio.patch<void>(
      'driver-auth/delivery/$deliveryId/status',
      data: {
        'status': status.apiValue,
        if (normalizedVehicleId.isNotEmpty) 'vehicleId': normalizedVehicleId,
      },
    );
  }

  Future<String> _uploadFile(
    String path,
    List<int> bytes,
    String filename,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    final filePath = response.data?['filePath'];
    if (filePath is! String || filePath.isEmpty) {
      throw const FormatException('Upload response did not include filePath');
    }
    return filePath;
  }

  @override
  Future<void> startDelivery(
    String deliveryId,
    Map<String, dynamic> body,
  ) async {
    await _dio.post<void>('driver-auth/delivery/$deliveryId/start', data: body);
  }

  @override
  Future<void> endDelivery(String deliveryId, Map<String, dynamic> body) async {
    await _dio.post<void>('driver-auth/delivery/$deliveryId/end', data: body);
  }

  @override
  Future<void> submitDriverLocation(DriverLocationReading reading) async {
    await _dio.post<void>(
      'driver-auth/delivery/${reading.deliveryId}/location',
      data: reading.toApiJson(),
    );
  }

  @override
  Future<Map<String, dynamic>> saveCustomerLocation(
    CustomerLocationCapture capture,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      'driver-auth/delivery/${capture.deliveryId}/customer-location',
      data: capture.toApiJson(),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty customer location response');
    }
    return data;
  }

  Future<List<DeliveryScheduleDto>> _getSchedule(
    String path,
    CancelToken? cancelToken,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      path,
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data == null) throw const FormatException('Empty schedule response');
    return data
        .map(
          (item) => DeliveryScheduleDto.fromJson(
            item as Map<String, dynamic>,
            authenticatedDriverId: _authenticatedDriverId?.call(),
          ),
        )
        .toList(growable: false);
  }
}
