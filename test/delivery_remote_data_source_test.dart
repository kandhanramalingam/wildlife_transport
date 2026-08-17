import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_remote_data_source.dart';

void main() {
  test(
    'uses the delivery lifecycle endpoint paths and request bodies',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<void>(requestOptions: options, statusCode: 200),
            );
          },
        ),
      );
      final dataSource = DioDeliveryRemoteDataSource(dio);

      await dataSource.startLoading('delivery-1');
      await dataSource.completeLoading('delivery-1', {'loading': true});
      await dataSource.startTrip('delivery-1', {
        'startLatitude': '-25.7',
        'startLongitude': '28.1',
      });
      await dataSource.startOffloading('delivery-1');
      await dataSource.completeOffloading('delivery-1', {'offloading': true});

      expect(requests.map((request) => request.path), [
        'driver-auth/delivery/delivery-1/start-loading',
        'driver-auth/delivery/delivery-1/complete-loading',
        'driver-auth/delivery/delivery-1/start-trip',
        'driver-auth/delivery/delivery-1/start-offloading',
        'driver-auth/delivery/delivery-1/complete-offloading',
      ]);
      expect(requests[0].data, isNull);
      expect(requests[1].data, {'loading': true});
      expect(requests[2].data, {
        'startLatitude': '-25.7',
        'startLongitude': '28.1',
      });
      expect(requests[3].data, isNull);
      expect(requests[4].data, {'offloading': true});
    },
  );
}
