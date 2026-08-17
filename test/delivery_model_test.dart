import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';

void main() {
  test('maps API lifecycle statuses and loading completion correctly', () {
    expect(DeliveryStatus.fromApi('loadingStarted'), DeliveryStatus.loading);
    expect(
      DeliveryStatus.fromApi('loading-completed'),
      DeliveryStatus.loadingCompleted,
    );
    expect(DeliveryStatus.fromApi('trip_started'), DeliveryStatus.inProgress);
    expect(
      DeliveryStatus.fromApi('offloading_started'),
      DeliveryStatus.offloading,
    );

    const loading = DeliveryLot(
      clientName: 'Client',
      buyerId: 'buyer-1',
      mainBuyer: true,
      deliveryId: 'delivery-1',
      address: 'Address',
      status: DeliveryStatus.loading,
    );
    expect(loading.loadingCompleted, isFalse);
    expect(
      loading
          .copyWith(status: DeliveryStatus.loadingCompleted)
          .loadingCompleted,
      isTrue,
    );
  });

  test('missing at-delivery-point state defaults to false', () {
    const lot = DeliveryLot(
      clientName: 'Client',
      buyerId: 'buyer-1',
      mainBuyer: true,
      deliveryId: 'delivery-1',
      address: 'Delivery address',
      atDeliveryPointState: null,
      invoicePath: 'uploads/invoices/invoice.pdf',
    );

    expect(lot.atDeliveryPoint, isFalse);
    expect(lot.copyWith(atDeliveryPoint: true).atDeliveryPoint, isTrue);
    expect(
      lot.copyWith(atDeliveryPoint: true).invoicePath,
      'uploads/invoices/invoice.pdf',
    );
  });

  test('null invoice path is handled as unavailable', () {
    const lot = DeliveryLot(
      clientName: 'Client',
      buyerId: 'buyer-1',
      mainBuyer: true,
      deliveryId: 'delivery-1',
      address: 'Delivery address',
      invoicePath: null,
    );

    expect(lot.invoicePathValue, isEmpty);
    expect(lot.hasInvoice, isFalse);
  });

  test('reports completed deliveries out of the combined lot total', () {
    final delivery = DeliveryModel(
      id: 'delivery-1',
      dateTime: DateTime(2026, 8, 12),
      clientName: 'Main client',
      clientAddress: 'Address',
      status: DeliveryStatus.inProgress,
      lots: const [
        DeliveryLot(
          clientName: 'Main client',
          buyerId: 'buyer-1',
          mainBuyer: true,
          deliveryId: 'delivery-1',
          address: 'Address',
          status: DeliveryStatus.completed,
        ),
        DeliveryLot(
          clientName: 'Second client',
          buyerId: 'buyer-2',
          mainBuyer: false,
          deliveryId: 'delivery-2',
          address: 'Address',
          status: DeliveryStatus.inProgress,
        ),
      ],
    );

    expect(delivery.completedDeliveryCount, 1);
    expect(delivery.deliveryCount, 2);
    expect(delivery.deliveryProgressLabel, '1/2 Delivery Completed');
    expect(
      delivery.copyWith(status: DeliveryStatus.completed).deliveryProgressLabel,
      '2/2 Delivery Completed',
    );
  });

  test('off-loading order is the reverse of loading order', () {
    final delivery = DeliveryModel(
      id: 'delivery-1',
      dateTime: DateTime(2026, 8, 14),
      clientName: 'First client',
      clientAddress: 'Address',
      lots: const [
        DeliveryLot(
          clientName: 'First loaded',
          buyerId: 'buyer-1',
          mainBuyer: true,
          deliveryId: 'delivery-1',
          address: 'Address',
          loadingOrder: 1,
          status: DeliveryStatus.inProgress,
        ),
        DeliveryLot(
          clientName: 'Third loaded',
          buyerId: 'buyer-3',
          mainBuyer: false,
          deliveryId: 'delivery-3',
          address: 'Address',
          loadingOrder: 3,
          status: DeliveryStatus.inProgress,
        ),
        DeliveryLot(
          clientName: 'Second loaded',
          buyerId: 'buyer-2',
          mainBuyer: false,
          deliveryId: 'delivery-2',
          address: 'Address',
          loadingOrder: 2,
          status: DeliveryStatus.inProgress,
        ),
      ],
    );

    expect(delivery.lotsInOffloadingOrder.map((lot) => lot.clientName), [
      'Third loaded',
      'Second loaded',
      'First loaded',
    ]);
    expect(delivery.nextLoadingOrder, 4);
  });
}
