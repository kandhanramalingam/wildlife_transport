import 'package:dio/dio.dart';

import '../models/driver_profile.dart';

abstract interface class ProfileRepository {
  Future<DriverProfile> getProfile({CancelToken? cancelToken});
}
