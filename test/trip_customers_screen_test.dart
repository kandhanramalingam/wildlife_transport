import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/screens/trip_customers_screen.dart';

void main() {
  testWidgets('only the first unfinished customer can confirm arrival', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: TripCustomersScreen(delivery: _delivery())),
    );

    final enabledButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'At delivery point'),
    );
    final lockedButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Complete Previous Delivery First'),
    );

    expect(enabledButton.onPressed, isNotNull);
    expect(lockedButton.onPressed, isNull);
  });

  testWidgets('enables the next customer after the first is completed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TripCustomersScreen(delivery: _delivery(firstCompleted: true)),
      ),
    );

    final enabledButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'At delivery point'),
    );

    expect(enabledButton.onPressed, isNotNull);
    expect(find.text('Complete Previous Delivery First'), findsNothing);
  });
}

DeliveryModel _delivery({bool firstCompleted = false}) {
  return DeliveryModel(
    id: 'trip-1',
    dateTime: DateTime(2026, 9, 5),
    clientName: 'Second stop',
    clientAddress: 'Second address',
    status: DeliveryStatus.inProgress,
    lots: [
      const DeliveryLot(
        clientName: 'Second stop',
        buyerId: 'buyer-2',
        mainBuyer: false,
        deliveryId: 'delivery-2',
        address: 'Second address',
        loadingOrder: 1,
        status: DeliveryStatus.inProgress,
      ),
      DeliveryLot(
        clientName: 'First stop',
        buyerId: 'buyer-1',
        mainBuyer: true,
        deliveryId: 'delivery-1',
        address: 'First address',
        loadingOrder: 2,
        status: firstCompleted
            ? DeliveryStatus.completed
            : DeliveryStatus.inProgress,
      ),
    ],
  );
}
