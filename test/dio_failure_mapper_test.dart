import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/core/error/failure.dart';
import 'package:wildlife_transport/core/network/dio_failure_mapper.dart';

void main() {
  test(
    'identifies a missing completion record without treating other 404s as missing deliveries',
    () {
      DioException missing(String path) {
        final request = RequestOptions(path: path);
        return DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: request,
            statusCode: 404,
            data: {'message': 'Delivery not found'},
          ),
        );
      }

      expect(
        mapDioException(
          missing('driver-auth/delivery/deleted-id/complete-offloading'),
        ),
        isA<DeliveryNotFoundFailure>(),
      );
      expect(
        mapDioException(missing('file/upload-video')),
        isA<UnknownFailure>(),
      );
    },
  );

  test('maps an inactive trip conflict to its terminal failure type', () {
    final request = RequestOptions(path: '/driver-auth/delivery/id/location');
    final exception = DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response<Map<String, dynamic>>(
        requestOptions: request,
        statusCode: 409,
        data: {'message': 'Delivery is not in an active trip state'},
      ),
    );

    expect(mapDioException(exception), isA<InactiveTripFailure>());
  });
}
