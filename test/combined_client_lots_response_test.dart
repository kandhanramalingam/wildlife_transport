import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_remote_data_source.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_repository_impl.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_schedule_dto.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/screens/trip_customers_screen.dart';
import 'package:wildlife_transport/features/delivery/widgets/delivery_card.dart';

// Relevant fields from the supplied /schedule/today response. Authentication,
// identity documents, contact details and locations are deliberately omitted.
const _response = <String, dynamic>{
  '_id': '6ad11dab99d163580420a169',
  'buyerId': '5674',
  'buyerName': 'RIAAN SUTHERLAND',
  'auctionId': '301',
  'scheduleDate': '2026-10-15T18:40:00.000Z',
  'deliveryStatus': 'ready',
  'vehicleLotTotal': 2,
  'paymentStatus': true,
  'vehicleId': 'vehicle-1',
  'driverId': 'driver-1',
  'tripNumber': 1,
  'lotNumbers': ['B-15-A034', 'B-16-A051'],
  'loadedLotNumbers': [],
  'deliveredLotNumbers': [],
  'lots': [
    {
      'lotNo': 'B-16-A051',
      'description': 'Waterbuck Bull',
      'quantity': 1,
      'status': 'Sold',
      'comment': 'Riaan Lot',
    },
    {
      'lotNo': 'B-15-A034',
      'description': 'Red Hartebeest Bull',
      'quantity': 1,
      'status': 'Sold',
      'comment': null,
    },
  ],
  'combinedLotBuyers': ['3041'],
  'combinedLotDeliveries': [
    {
      '_id': '6ad11dc099d163580420a733',
      'buyerId': '3041',
      'buyerName': 'Johnny Thomson',
      'auctionId': '301',
      'deliveryStatus': 'pending',
      'vehicleId': 'vehicle-1',
      'driverId': 'driver-1',
      'tripNumber': 1,
      'lotNumbers': ['B-15-A034', 'B-16-A051'],
      'loadedLotNumbers': [],
      'deliveredLotNumbers': [],
      'lots': [
        {
          'lotNo': 'B-15-A034',
          'description': 'Red Hartebeest Bull',
          'quantity': 1,
          'status': 'Sold',
          'comment': null,
        },
      ],
      'combinedLotBuyers': [],
      'combinedLotDeliveries': [],
    },
  ],
};

Future<DeliveryModel> _loadResponse() async {
  final deliveries = await DeliveryRepositoryImpl(
    _ResponseSource(),
  ).getTodaySchedule();
  return deliveries.single;
}

void main() {
  testWidgets('supplied schedule response renders exactly one lot per client', (
    tester,
  ) async {
    final delivery = await _loadResponse();
    expect(delivery.assignment!.lotNumbers, ['B-15-A034', 'B-16-A051']);
    expect(delivery.lots[0].buyerId, '5674');
    expect(delivery.lots[0].lotNumbers, ['B-16-A051']);
    expect(delivery.lots[1].buyerId, '3041');
    expect(delivery.lots[1].lotNumbers, ['B-15-A034']);
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
    final riaan = find.byKey(
      const ValueKey('loading-customer-6ad11dab99d163580420a169'),
    );
    final johnny = find.byKey(
      const ValueKey('loading-customer-6ad11dc099d163580420a733'),
    );
    expect(
      find.descendant(of: riaan, matching: find.text('Lot B-16-A051')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: riaan, matching: find.text('Lot B-15-A034')),
      findsNothing,
    );
    expect(
      find.descendant(of: johnny, matching: find.text('Lot B-15-A034')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: johnny, matching: find.text('Lot B-16-A051')),
      findsNothing,
    );
    final chip = tester.widget<ActionChip>(
      find.widgetWithText(ActionChip, 'Lot B-16-A051'),
    );
    expect(chip.side!.color, Colors.red);
    await tester.tap(find.text('Lot B-16-A051'));
    await tester.pumpAndSettle();
    expect(find.text('Riaan Lot'), findsOneWidget);
    expect(find.textContaining('Waterbuck Bull'), findsOneWidget);
  });

  testWidgets(
    'Customer Delivery does not duplicate lots from the supplied response',
    (tester) async {
      final delivery = await _loadResponse();
      await tester.pumpWidget(
        MaterialApp(
          home: TripCustomersScreen(
            delivery: delivery.copyWith(status: DeliveryStatus.inProgress),
          ),
        ),
      );
      expect(find.widgetWithText(Chip, 'Lot B-16-A051'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Lot B-15-A034'), findsOneWidget);
    },
  );
}

class _ResponseSource implements DeliveryRemoteDataSource {
  @override
  Future<List<DeliveryScheduleDto>> getTodaySchedule({
    CancelToken? cancelToken,
  }) async => [
    DeliveryScheduleDto.fromJson(_response, authenticatedDriverId: 'driver-1'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
