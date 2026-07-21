import 'package:dio/dio.dart';

import 'driver.dart';

abstract interface class AuthRepository {
  Future<LoginResult> login({
    required String phone,
    required String password,
    CancelToken? cancelToken,
  });
}
