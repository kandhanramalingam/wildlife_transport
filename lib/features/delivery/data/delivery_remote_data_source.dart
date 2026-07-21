import 'package:dio/dio.dart';

import 'delivery_schedule_dto.dart';

abstract interface class DeliveryRemoteDataSource {
  Future<List<DeliveryScheduleDto>> getTodaySchedule({
    CancelToken? cancelToken,
  });
  Future<List<DeliveryScheduleDto>> getUpcomingSchedule({
    CancelToken? cancelToken,
  });
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
