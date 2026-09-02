import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/dio_failure_mapper.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/driver.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  const AuthRepositoryImpl(this._remoteDataSource, this._tokenStorage);

  @override
  Future<LoginResult> login({
    required String phone,
    required String password,
    CancelToken? cancelToken,
  }) async {
    try {
      final dto = await _remoteDataSource.login(
        phone: phone,
        password: password,
        cancelToken: cancelToken,
      );
      await _tokenStorage.saveAccessToken(dto.accessToken);
      await _tokenStorage.saveDriverId(dto.driver.id);
      return LoginResult(
        driver: Driver(
          id: dto.driver.id,
          name: dto.driver.name,
          phone: dto.driver.phone,
        ),
      );
    } on DioException catch (exception) {
      throw mapDioException(exception);
    } on Failure {
      rethrow;
    } on FormatException {
      throw const UnknownFailure('Invalid response from server');
    } on TypeError {
      throw const UnknownFailure('Invalid response from server');
    }
  }
}
