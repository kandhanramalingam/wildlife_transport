import 'package:dio/dio.dart';

import 'delivery_customer_dto.dart';
import 'delivery_schedule_dto.dart';

abstract interface class DeliveryRemoteDataSource {
  Future<List<DeliveryScheduleDto>> getTodaySchedule({
    CancelToken? cancelToken,
  });
  Future<List<DeliveryScheduleDto>> getUpcomingSchedule({
    CancelToken? cancelToken,
  });
  Future<List<DeliveryCustomerDto>> getDeliveryCustomers(String deliveryId);
  Future<String> uploadImage(List<int> bytes, String filename);
  Future<String> uploadVideo(List<int> bytes, String filename);
  Future<void> startDelivery(String deliveryId, Map<String, dynamic> body);
}

class DioDeliveryRemoteDataSource implements DeliveryRemoteDataSource {
  final Dio _dio;

  const DioDeliveryRemoteDataSource(this._dio);

  @override
  Future<List<DeliveryScheduleDto>> getTodaySchedule({
    CancelToken? cancelToken,
  }) => _getSchedule('driver-auth/schedule/today', cancelToken);

  @override
  Future<List<DeliveryScheduleDto>> getUpcomingSchedule({
    CancelToken? cancelToken,
  }) => _getSchedule('driver-auth/schedule/upcoming', cancelToken);

  @override
  Future<List<DeliveryCustomerDto>> getDeliveryCustomers(
    String deliveryId,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      'buyer-delivery/customer/$deliveryId',
    );
    final data = response.data;
    if (data == null) throw const FormatException('Empty customer response');
    return data
        .map(
          (item) => DeliveryCustomerDto.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<String> uploadImage(List<int> bytes, String filename) =>
      _uploadFile('file/upload', bytes, filename);

  @override
  Future<String> uploadVideo(List<int> bytes, String filename) =>
      _uploadFile('file/upload-video', bytes, filename);

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
          (item) => DeliveryScheduleDto.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
