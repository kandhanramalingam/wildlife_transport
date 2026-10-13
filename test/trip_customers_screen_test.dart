import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/screens/trip_customers_screen.dart';

void main() {
  testWidgets('queued customer shows awaiting sync', (tester) async {
    final delivery = _delivery();
    await tester.pumpWidget(
      MaterialApp(
        home: TripCustomersScreen(
          delivery: delivery.copyWith(
            lots: delivery.lots
                .map((lot) => lot.copyWith(offloadingSyncPending: true))
                .toList(),
          ),
        ),
      ),
    );
    expect(find.text('Awaiting sync'), findsNWidgets(2));
    expect(find.text('Completed'), findsNothing);
    expect(find.text('At delivery point'), findsNothing);
  });

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

  testWidgets('lot button opens only that lot loading media', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TripCustomersScreen(delivery: _deliveryWithMedia())),
    );

    expect(find.widgetWithText(OutlinedButton, 'Lot 101'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Lot 102'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Lot 101'));
    await tester.pumpAndSettle();

    expect(find.text('Lot 101 Loading Media'), findsOneWidget);
    expect(find.text('Animal Photos (1)'), findsOneWidget);
    expect(find.text('Animal Loading Videos (1)'), findsOneWidget);
  });
}

DeliveryModel _deliveryWithMedia() {
  const assignment = DeliveryAssignment(
    driverId: 'driver-1',
    vehicleId: 'vehicle-1',
    lotNumbers: ['101', '102'],
  );
  return DeliveryModel(
    id: 'trip-media',
    dateTime: DateTime(2026, 9, 5),
    clientName: 'Media stop',
    clientAddress: 'Media address',
    status: DeliveryStatus.inProgress,
    startAnimalPhotos: const [
      'https://example.com/lot-101.jpg',
      'https://example.com/lot-102.jpg',
    ],
    onLoadAnimalsVideos: const [
      'https://example.com/lot-101.mp4',
      'https://example.com/lot-102.mp4',
    ],
    startMediaMetadata: const [
      DeliveryLoadingMedia(
        filePath: 'https://example.com/lot-101.jpg',
        kind: 'animal_photo',
        lotNumber: '101',
      ),
      DeliveryLoadingMedia(
        filePath: 'https://example.com/lot-101.mp4',
        kind: 'animal_video',
        lotNumber: '101',
      ),
      DeliveryLoadingMedia(
        filePath: 'https://example.com/lot-102.jpg',
        kind: 'animal_photo',
        lotNumber: '102',
      ),
      DeliveryLoadingMedia(
        filePath: 'https://example.com/lot-102.mp4',
        kind: 'animal_video',
        lotNumber: '102',
      ),
    ],
    lots: const [
      DeliveryLot(
        clientName: 'Media stop',
        buyerId: 'buyer-media',
        mainBuyer: true,
        deliveryId: 'trip-media',
        address: 'Media address',
        loadingOrder: 1,
        status: DeliveryStatus.inProgress,
        assignment: assignment,
      ),
    ],
  );
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
