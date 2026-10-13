import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_remote_data_source.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/models/location_tracking.dart';

void main() {
  test(
    'saved status replay acknowledges a legacy response without parsing it',
    () async {
      RequestOptions? request;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {'deliveryStatus': 'arrived_at_location'},
              ),
            );
          },
        ),
      );
      final result = await DioDeliveryRemoteDataSource(dio).updateStatus(
        'delivery-1',
        DeliveryStatusUpdate.arrivedAtLocation,
        vehicleId: 'vehicle-1',
        offlineReplay: true,
      );
      expect(result, isNull);
      expect(request!.data, {
        'status': 'arrived_at_location',
        'vehicleId': 'vehicle-1',
        'offlineReplay': true,
      });
    },
  );

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
        vehicleId: 'vehicle-1',
      );
      await dataSource.startDelivery('delivery-1', {'loading': true});
      await dataSource.endDelivery('delivery-1', {'offloading': true});
      await dataSource.completeOffloading('delivery-1', {'completed': true});

      expect(requests.map((request) => request.path), [
        'driver-auth/delivery/delivery-1/status',
        'driver-auth/delivery/delivery-1/start',
        'driver-auth/delivery/delivery-1/end',
        'driver-auth/delivery/delivery-1/complete-offloading',
      ]);
      expect(requests[0].method, 'PATCH');
      expect(requests[0].data, {
        'status': 'loading_in_progress',
        'vehicleId': 'vehicle-1',
      });
      expect(requests[1].data, {'loading': true});
      expect(requests[2].data, {'offloading': true});
      expect(requests[3].data, {'completed': true});
    },
  );

  test('uses the tracking and customer-location endpoint contracts', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'clientId': 'client-1',
                'buyerId': 'buyer-1',
                'latitude': -25.7512,
                'longitude': 28.1934,
                'accuracyMetres': 8.2,
                'capturedAt': '2026-08-30T14:05:00.000Z',
              },
            ),
          );
        },
      ),
    );
    final dataSource = DioDeliveryRemoteDataSource(dio);
    final recordedAt = DateTime.utc(2026, 8, 30, 13, 30);

    await dataSource.submitDriverLocation(
      DriverLocationReading(
        localId: 'reading-1',
        deliveryId: 'delivery-1',
        latitude: -25.7461,
        longitude: 28.1881,
        accuracyMetres: 12.4,
        recordedAt: recordedAt,
      ),
    );
    await dataSource.saveCustomerLocation(
      CustomerLocationCapture(
        deliveryId: 'delivery-1',
        buyerId: 'buyer-1',
        latitude: -25.7512,
        longitude: 28.1934,
        accuracyMetres: 8.2,
        capturedAt: DateTime.utc(2026, 8, 30, 14, 5),
      ),
    );

    expect(requests[0].path, 'driver-auth/delivery/delivery-1/location');
    expect(requests[0].method, 'POST');
    expect(requests[0].data, {
      'latitude': -25.7461,
      'longitude': 28.1881,
      'accuracyMetres': 12.4,
      'recordedAt': '2026-08-30T13:30:00.000Z',
    });
    expect(
      requests[1].path,
      'driver-auth/delivery/delivery-1/customer-location',
    );
    expect(requests[1].method, 'PUT');
    expect(requests[1].data['buyerId'], 'buyer-1');
  });

  test(
    'treats an accepted end request with a legacy response as successful',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {'deliveryStatus': 'completed'},
            ),
          ),
        ),
      );

      final result = await DioDeliveryRemoteDataSource(
        dio,
      ).endDelivery('delivery-1', {'offloading': true});

      expect(result, isNull);
    },
  );
}
