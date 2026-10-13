import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/core/config/app_version.dart';
import 'package:wildlife_transport/core/network/dio_failure_mapper.dart';
import 'package:wildlife_transport/features/auth/data/auth_remote_data_source.dart';

void main() {
  test(
    'login sends the installed release version and exposes update rejection',
    () async {
      final dio = Dio();
      RequestOptions? request;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 426,
                  data: {
                    'message':
                        'Please install app version 1.5 or later to continue.',
                  },
                ),
              ),
            );
          },
        ),
      );
      try {
        await DioAuthRemoteDataSource(
          dio,
        ).login(phone: '0714147808', password: 'secret123');
        fail('Outdated login must be rejected');
      } on DioException catch (error) {
        expect(
          mapDioException(error).message,
          contains('install app version 1.5'),
        );
      }
      expect(request!.data['appVersion'], appVersion);
    },
  );
}
