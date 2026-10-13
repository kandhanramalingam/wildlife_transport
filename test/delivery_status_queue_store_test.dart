import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/offline/delivery_status_queue_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  PendingDeliveryStatus job(String id) => PendingDeliveryStatus(
    id: id,
    deliveryId: 'delivery-$id',
    vehicleId: 'vehicle-1',
    status: DeliveryStatusUpdate.arrivedAtLocation,
  );

  test(
    'status queue survives relaunch and concurrent acknowledgement and save',
    () async {
      const store = SecureDeliveryStatusQueueStore();
      await Future.wait([
        for (var index = 0; index < 4; index++) store.add(job('$index')),
      ]);
      await Future.wait([store.remove(job('0')), store.add(job('new'))]);
      final restored = await const SecureDeliveryStatusQueueStore().load();
      expect(restored.map((value) => value.id), ['1', '2', '3', 'new']);
      expect(
        restored.map((value) => value.vehicleId),
        everyElement('vehicle-1'),
      );
      expect(
        restored.map((value) => value.status),
        everyElement(DeliveryStatusUpdate.arrivedAtLocation),
      );
    },
  );

  test('corrupt status manifest is reported and preserved', () async {
    const key = 'pending_delivery_statuses_v1';
    FlutterSecureStorage.setMockInitialValues({key: 'unreadable evidence'});
    const store = SecureDeliveryStatusQueueStore();
    await expectLater(store.load(), throwsFormatException);
    await expectLater(store.add(job('new')), throwsFormatException);
    expect(
      await const FlutterSecureStorage().read(key: key),
      'unreadable evidence',
    );
  });
}
