import 'package:dio/dio.dart';

import 'login_response_dto.dart';

abstract interface class AuthRemoteDataSource {
  Future<LoginResponseDto> login({
    required String phone,
    required String password,
    CancelToken? cancelToken,
  });
}

class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  final Dio _dio;

  const DioAuthRemoteDataSource(this._dio);

  @override
  Future<LoginResponseDto> login({
    required String phone,
    required String password,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'driver-auth/login',
      data: {'phone': phone, 'password': password},
      cancelToken: cancelToken,
    );
    final data = response.data;
    if (data == null) throw const FormatException('Empty login response');
    return LoginResponseDto.fromJson(data);
  }
}
