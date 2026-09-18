import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/widgets/delivery_card.dart';

void main() {
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
    expect(find.text('permit-123.pdf'), findsOneWidget);
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
