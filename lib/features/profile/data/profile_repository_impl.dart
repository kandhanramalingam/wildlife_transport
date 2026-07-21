import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/dio_failure_mapper.dart';
import '../domain/profile_repository.dart';
import '../models/driver_profile.dart';
import 'profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  const ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<DriverProfile> getProfile({CancelToken? cancelToken}) async {
    try {
      final dto = await _remoteDataSource.getProfile(cancelToken: cancelToken);
      return dto.toModel();
    } on DioException catch (exception) {
      throw mapDioException(exception);
    } on FormatException {
      throw const UnknownFailure('Invalid profile response from server');
    } on TypeError {
      throw const UnknownFailure('Invalid profile response from server');
    }
  }
}
