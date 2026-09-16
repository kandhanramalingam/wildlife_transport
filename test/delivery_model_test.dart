import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';

void main() {
  test('serializes delivery status update values for the API', () {
    expect(DeliveryStatusUpdate.values.map((status) => status.apiValue), [
      'pending',
      'ready',
      'started',
      'ongoing',
      'ended',
      'completed',
      'hold',
      'loading_in_progress',
      'loading_completed',
      'in_delivery',
      'arrived_at_location',
      'offloading_started',
    ]);
  });

  test('maps API lifecycle statuses and loading completion correctly', () {
    expect(DeliveryStatus.fromApi('loadingStarted'), DeliveryStatus.loading);
    expect(
      DeliveryStatus.fromApi('loading_in_progress'),
      DeliveryStatus.loading,
    );
    expect(
      DeliveryStatus.fromApi('loading-completed'),
      DeliveryStatus.loadingCompleted,
    );
    expect(DeliveryStatus.fromApi('trip_started'), DeliveryStatus.inProgress);
    expect(DeliveryStatus.fromApi('in_delivery'), DeliveryStatus.inProgress);
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

  test('delivery is complete when every combined lot is complete', () {
    final delivery = DeliveryModel(
      id: 'route-1',
      dateTime: DateTime(2026, 8, 19),
      clientName: 'Main buyer',
      clientAddress: 'Address',
      lots: const [
        DeliveryLot(
          clientName: 'Buyer one',
          buyerId: 'buyer-1',
          mainBuyer: true,
          deliveryId: 'delivery-1',
          address: 'Address one',
          status: DeliveryStatus.completed,
        ),
        DeliveryLot(
          clientName: 'Buyer two',
          buyerId: 'buyer-2',
          mainBuyer: false,
          deliveryId: 'delivery-2',
          address: 'Address two',
          status: DeliveryStatus.completed,
        ),
      ],
    );

    expect(delivery.deliveryCompleted, isTrue);
    expect(delivery.completedDeliveryCount, 2);
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

  test('updates a saved customer pin without losing lot state', () {
    const lot = DeliveryLot(
      clientName: 'Customer',
      buyerId: 'buyer-1',
      mainBuyer: true,
      deliveryId: 'delivery-1',
      address: 'Address',
      latitude: '-25.000000',
      longitude: '28.000000',
      status: DeliveryStatus.atDeliveryPoint,
    );
    final capturedAt = DateTime.utc(2026, 8, 30, 14, 5);

    final updated = lot.copyWith(
      latitude: '-25.751200',
      longitude: '28.193400',
      customerLocationCapturedAt: capturedAt,
    );

    expect(updated.latitude, '-25.751200');
    expect(updated.longitude, '28.193400');
    expect(updated.customerLocationCapturedAt, capturedAt);
    expect(updated.status, DeliveryStatus.atDeliveryPoint);
  });

  test('computes partial delivery properties and labels correctly', () {
    final delivery = DeliveryModel(
      id: 'delivery-1',
      dateTime: DateTime(2026, 9, 15),
      clientName: 'Buyer',
      clientAddress: 'Address',
      vehicleLotTotal: 5,
      totalLots: 5,
      assignedLots: 4,
      deliveredLots: 1,
      balanceLots: 4,
      balanceLotNumbers: const ['2', '3', '4', '5'],
      partialDelivery: true,
      permits: const ['uploads/permits/p1.pdf'],
      pickupStops: const [
        PickupStop(order: 2, address: 'Stop 2', lotNumbers: ['3', '4']),
        PickupStop(order: 1, address: 'Stop 1', lotNumbers: ['1', '2']),
      ],
      multiPickupPointJob: true,
      pickupNotice: 'Load Stop 1 before Stop 2',
    );

    expect(delivery.isPartial, isTrue);
    expect(delivery.partialProgressLabel, '1 / 5');
    expect(delivery.balanceLotsLabel, 'Balance: 2, 3, 4, 5');
    expect(delivery.isMultiPickup, isTrue);
    expect(delivery.sortedPickupStops.first.order, 1);
    expect(delivery.sortedPickupStops.last.order, 2);
    expect(delivery.permits, ['uploads/permits/p1.pdf']);
  });

  test('handles zero balance lots label gracefully', () {
    final delivery = DeliveryModel(
      id: 'delivery-2',
      dateTime: DateTime(2026, 9, 15),
      clientName: 'Buyer',
      clientAddress: 'Address',
      vehicleLotTotal: 5,
      totalLots: 5,
      assignedLots: 5,
      deliveredLots: 5,
      balanceLots: 0,
      balanceLotNumbers: const [],
      partialDelivery: false,
    );

    expect(delivery.isPartial, isFalse);
    expect(delivery.partialProgressLabel, '5 / 5');
    expect(delivery.balanceLotsLabel, '0 Remaining');
  });
}

