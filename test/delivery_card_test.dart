import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/widgets/delivery_card.dart';

void main() {
  testWidgets(
    'queued evidence is labelled awaiting sync rather than completed',
    (tester) async {
      final delivery = _delivery().copyWith(
        status: DeliveryStatus.offloading,
        lots: _delivery().lots
            .map(
              (lot) => lot.copyWith(
                status: DeliveryStatus.offloading,
                offloadingSyncPending: true,
              ),
            )
            .toList(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeliveryCard(
                delivery: delivery,
                onStartLoading: (_) {},
                onStartTrip: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Your status: Awaiting sync'), findsOneWidget);
      expect(
        find.text('0/2 Delivery Completed • Awaiting sync'),
        findsOneWidget,
      );
      expect(find.text('Your status: Completed'), findsNothing);
    },
  );

  testWidgets('shows loading order and allows a pending lot to move earlier', (
    tester,
  ) async {
    int? oldIndex;
    int? newIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeliveryCard(
            delivery: _delivery(),
            onStartLoading: (_) {},
            onStartTrip: () {},
            onReorderLot: (oldValue, newValue) {
              oldIndex = oldValue;
              newIndex = newValue;
            },
          ),
        ),
      ),
    );

    expect(find.text('Load 1'), findsOneWidget);
    expect(find.text('Load 2'), findsOneWidget);
    expect(find.text('Waiting for Loading Turn'), findsOneWidget);

    await tester.tap(find.byTooltip('Move earlier').last);
    expect(oldIndex, 1);
    expect(newIndex, 0);
  });

  testWidgets('locks reordering after loading starts', (tester) async {
    final delivery = _delivery(firstStatus: DeliveryStatus.loading);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeliveryCard(
            delivery: delivery,
            onStartLoading: (_) {},
            onStartTrip: () {},
            onReorderLot: (_, _) {},
          ),
        ),
      ),
    );

    final moveLater = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Move later').first,
        matching: find.byType(IconButton),
      ),
    );
    expect(moveLater.onPressed, isNull);
    expect(find.text('Continue Loading'), findsOneWidget);
    expect(find.text('Waiting for Loading Turn'), findsOneWidget);
  });

  testWidgets('shows the authenticated driver name and status', (tester) async {
    final delivery = _delivery().copyWith(status: DeliveryStatus.inProgress);
    final assigned = DeliveryModel(
      id: delivery.id,
      dateTime: delivery.dateTime,
      clientName: delivery.clientName,
      clientAddress: delivery.clientAddress,
      status: DeliveryStatus.inProgress,
      lots: delivery.lots,
      assignment: const DeliveryAssignment(
        driverId: 'driver-2',
        driverName: 'Second Driver',
        vehicleId: 'vehicle-2',
        vehicleRegistrationNumber: 'TRUCK-TWO',
        status: DeliveryStatus.inProgress,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeliveryCard(
            delivery: assigned,
            onStartLoading: (_) {},
            onStartTrip: () {},
          ),
        ),
      ),
    );

    expect(find.text('Assigned driver: Second Driver'), findsOneWidget);
    expect(find.text('Your status: In delivery'), findsOneWidget);
    expect(find.textContaining('TRUCK-ONE'), findsNothing);
  });

  testWidgets('hides partial badge and renders pickup stops and permits', (
    tester,
  ) async {
    final delivery = DeliveryModel(
      id: 'route-partial',
      dateTime: DateTime(2026, 9, 15, 10, 0),
      clientName: 'Main Buyer',
      clientAddress: 'Main Address',
      lots: const [
        DeliveryLot(
          clientName: 'Main Buyer',
          buyerId: 'buyer-1',
          mainBuyer: true,
          deliveryId: 'delivery-1',
          address: 'Main Address',
        ),
      ],
      vehicleLotTotal: 5,
      totalLots: 5,
      assignedLots: 4,
      deliveredLots: 1,
      balanceLots: 4,
      balanceLotNumbers: const ['2', '3', '4', '5'],
      partialDelivery: true,
      multiPickupPointJob: true,
      pickupNotice: 'Check gate before loading',
      pickupStops: const [
        PickupStop(order: 1, address: 'Farm Alpha', lotNumbers: ['1', '2']),
      ],
      permits: const ['uploads/permits/permit-123.pdf'],
      maps: const ['uploads/maps/map-123.png'],
      lotDetails: const [
        DeliveryLotDetails(
          lotNumber: '11',
          description: 'Blue wildebeest',
          quantity: 2,
          status: 'Sold',
          comment: 'Fragile horns',
        ),
        DeliveryLotDetails(
          lotNumber: '12',
          description: 'Impala',
          quantity: 4,
          status: 'Sold',
        ),
      ],
      invoicePath: 'uploads/invoices/invoice-123.pdf',
      assignment: const DeliveryAssignment(
        driverId: 'driver-1',
        vehicleId: 'vehicle-1',
        lotNumbers: ['11', '12'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryCard(
              delivery: delivery,
              onStartLoading: (_) {},
              onStartTrip: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Partial • 1/5 Lots Delivered'), findsNothing);
    expect(find.text('Remaining Lots: 2, 3, 4, 5'), findsNothing);
    expect(find.text('Pickup Stops (Multi-Pickup Trip)'), findsOneWidget);
    expect(find.text('Check gate before loading'), findsOneWidget);
    expect(find.text('Farm Alpha'), findsOneWidget);
    expect(find.text('Permits (1)'), findsOneWidget);
    expect(find.text('Permit'), findsNothing);
    expect(find.text('permit-123.pdf'), findsNothing);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Lots Details'), findsOneWidget);
    expect(find.text('Lot 11'), findsOneWidget);
    expect(find.text('Lot 12'), findsOneWidget);
    expect(find.text('Fragile horns'), findsNothing);

    await tester.tap(find.text('Lot 11'));
    await tester.pumpAndSettle();

    expect(find.text('Lot 11'), findsNWidgets(2));
    expect(find.text('Fragile horns'), findsOneWidget);
    expect(find.textContaining('Blue wildebeest'), findsOneWidget);
    expect(find.textContaining('Quantity: 2'), findsOneWidget);
  });
}

DeliveryModel _delivery({DeliveryStatus firstStatus = DeliveryStatus.pending}) {
  return DeliveryModel(
    id: 'route-1',
    dateTime: DateTime(2026, 8, 19, 20, 15),
    clientName: 'First buyer',
    clientAddress: 'First address',
    lots: [
      DeliveryLot(
        clientName: 'First buyer',
        buyerId: 'buyer-1',
        mainBuyer: true,
        deliveryId: 'delivery-1',
        address: 'First address',
        status: firstStatus,
      ),
      const DeliveryLot(
        clientName: 'Second buyer',
        buyerId: 'buyer-2',
        mainBuyer: false,
        deliveryId: 'delivery-2',
        address: 'Second address',
      ),
    ],
  );
}
