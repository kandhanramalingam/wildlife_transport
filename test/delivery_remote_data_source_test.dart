import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_remote_data_source.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';

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

      await dataSource.updateStatus(
        'delivery-1',
        DeliveryStatusUpdate.loadingInProgress,
      );
      await dataSource.startDelivery('delivery-1', {'loading': true});
      await dataSource.endDelivery('delivery-1', {'offloading': true});

      expect(requests.map((request) => request.path), [
        'driver-auth/delivery/delivery-1/status',
        'driver-auth/delivery/delivery-1/start',
        'driver-auth/delivery/delivery-1/end',
      ]);
      expect(requests[0].method, 'PATCH');
      expect(requests[0].data, {'status': 'loading_in_progress'});
      expect(requests[1].data, {'loading': true});
      expect(requests[2].data, {'offloading': true});
    },
  );
}
