import 'package:dio/dio.dart';

import 'driver_profile_dto.dart';

abstract interface class ProfileRemoteDataSource {
  Future<DriverProfileDto> getProfile({CancelToken? cancelToken});
}

class DioProfileRemoteDataSource implements ProfileRemoteDataSource {
  final Dio _dio;

  const DioProfileRemoteDataSource(this._dio);

  @override
  Future<DriverProfileDto> getProfile({CancelToken? cancelToken}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'driver-auth/profile',
      cancelToken: cancelToken,
    );
    final data = response.data;
    if (data == null) throw const FormatException('Empty profile response');
    return DriverProfileDto.fromJson(data);
  }
}
