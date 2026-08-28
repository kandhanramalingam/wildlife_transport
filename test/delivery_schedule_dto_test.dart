import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_schedule_dto.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';

void main() {
  test('parses a today schedule response item', () {
    final dto = DeliveryScheduleDto.fromJson({
      '_id': 'schedule-1',
      'buyerId': 'buyer-1',
      'buyerName': 'Buyer Name',
      'address': 'Delivery address',
      'companyName': 'KROMSTAAN BOERDERY',
      'contactNumber': '082 550 7809',
      'auctionId': 'auction-1',
      'scheduleDate': '2026-07-18T17:17:27.208Z',
      'deliveryStatus': 'pending',
      'paymentStatus': true,
      'invoicePath':
          'uploads/invoices/1e3e8eaf-dda6-45e8-9ea4-4323e10a39b8.pdf',
    });

    expect(dto.id, 'schedule-1');
    expect(dto.buyerName, 'Buyer Name');
    expect(dto.companyName, 'KROMSTAAN BOERDERY');
    expect(dto.contactNumber, '082 550 7809');
    expect(dto.lots.first.companyName, 'KROMSTAAN BOERDERY');
    expect(dto.lots.first.contactNumber, '082 550 7809');
    expect(dto.scheduleDate.isUtc, isTrue);
    expect(dto.paymentStatus, isTrue);
    expect(
      dto.invoicePath,
      'uploads/invoices/1e3e8eaf-dda6-45e8-9ea4-4323e10a39b8.pdf',
    );
    expect(dto.lots.first.invoicePath, dto.invoicePath);
    expect(DeliveryStatus.fromApi(dto.deliveryStatus), DeliveryStatus.pending);
  });

  test('parses separate invoice paths for combined deliveries', () {
    final dto = DeliveryScheduleDto.fromJson({
      '_id': 'main-delivery',
      'buyerId': '3068',
      'buyerName': 'Main Client',
      'auctionId': '216',
      'scheduleDate': '2026-08-14T01:38:00.000Z',
      'deliveryStatus': 'started',
      'invoicePath': 'uploads/invoices/main.pdf',
      'combinedLotBuyers': ['5050'],
      'combinedLotDeliveries': [
        {
          '_id': 'combined-delivery',
          'buyerId': '5050',
          'invoicePath': 'uploads/invoices/combined.pdf',
        },
      ],
    });

    expect(dto.lots.first.invoicePath, 'uploads/invoices/main.pdf');
    expect(dto.lots[1].invoicePath, 'uploads/invoices/combined.pdf');
  });

  test('uses buyer id when buyer name is null and maps started status', () {
    final dto = DeliveryScheduleDto.fromJson({
      '_id': 'schedule-2',
      'buyerId': '5150',
      'buyerName': null,
      'address': 'Delivery address',
      'auctionId': 'auction-1',
      'scheduleDate': '2026-08-04T12:11:00.000Z',
      'deliveryStatus': 'started',
      'paymentStatus': true,
    });

    expect(dto.buyerName, '5150');
    expect(
      DeliveryStatus.fromApi(dto.deliveryStatus),
      DeliveryStatus.inProgress,
    );
  });

  test('parses main and combined lots from the schedule response', () {
    final dto = DeliveryScheduleDto.fromJson({
      '_id': 'main-delivery',
      'buyerId': '3068',
      'buyerName': 'User #3068',
      'address': 'Main address',
      'auctionId': '216',
      'scheduleDate': '2026-08-09T14:01:00.000Z',
      'deliveryStatus': 'pending',
      'paymentStatus': true,
      'combinedLotBuyers': [
        {'value': '4010', 'label': 'User #4010', 'address': 'Second address'},
        {'buyerId': '5020', 'buyerName': 'User #5020'},
      ],
      'combinedLotDeliveries': [
        {
          '_id': 'combined-delivery-1',
          'buyerId': '4010',
          'deliveryStatus': 'started',
          'loadingOrder': 2,
        },
        'combined-delivery-2',
      ],
    });

    expect(dto.lots, hasLength(3));
    expect(dto.lots.first.deliveryId, 'main-delivery');
    expect(dto.lots.first.mainBuyer, isTrue);
    expect(dto.lots[1].buyerName, 'User #4010');
    expect(dto.lots[1].address, 'Second address');
    expect(dto.lots[1].deliveryId, 'combined-delivery-1');
    expect(dto.lots[1].deliveryStatus, 'started');
    expect(dto.lots[1].loadingOrder, 2);
    expect(dto.lots[2].deliveryId, 'combined-delivery-2');
    expect(dto.lots[2].address, isEmpty);
  });

  test(
    'uses each combined buyer profile instead of the main buyer details',
    () {
      final dto = DeliveryScheduleDto.fromJson({
        '_id': 'main-delivery',
        'buyerId': 'buyer-1',
        'buyerName': 'First buyer',
        'address': 'First address',
        'companyName': 'First company',
        'contactNumber': '111',
        'clientLatitude': '1.1',
        'clientLongitude': '2.2',
        'auctionId': 'auction-1',
        'scheduleDate': '2026-08-19T14:45:00.000Z',
        'deliveryStatus': 'pending',
        'combinedLotBuyers': [
          {
            'buyerId': {
              '_id': 'buyer-2',
              'name': 'Second buyer',
              'address': 'Second address',
              'companyName': 'Second company',
              'contactNumber': '222',
              'clientLatitude': '3.3',
              'clientLongitude': '4.4',
            },
          },
        ],
        'combinedLotDeliveries': [
          {
            '_id': 'second-delivery',
            'buyerId': {'_id': 'buyer-2'},
            'address': 'First address',
            'companyName': 'First company',
            'contactNumber': '111',
            'clientLatitude': '1.1',
            'clientLongitude': '2.2',
          },
        ],
      });

      expect(dto.lots, hasLength(2));
      expect(dto.lots[1].buyerId, 'buyer-2');
      expect(dto.lots[1].buyerName, 'Second buyer');
      expect(dto.lots[1].address, 'Second address');
      expect(dto.lots[1].companyName, 'Second company');
      expect(dto.lots[1].contactNumber, '222');
      expect(dto.lots[1].latitude, '3.3');
      expect(dto.lots[1].longitude, '4.4');
      expect(dto.lots[1].deliveryId, 'second-delivery');
    },
  );

  test('parses farm and coordinates from nested client records', () {
    final dto = DeliveryScheduleDto.fromJson({
      '_id': 'main-delivery',
      'buyerId': {
        '_id': '3068',
        'name': 'Main Client',
        'farmName': 'Acacia Farm',
        'latitude': -25.7461,
        'longitude': 28.1881,
      },
      'auctionId': '216',
      'scheduleDate': '2026-08-09T14:01:00.000Z',
      'deliveryStatus': 'started',
      'combinedLotBuyers': [
        {
          'value': {
            '_id': '4010',
            'clientName': 'Second Client',
            'farm_name': 'River Farm',
            'lat': '-26.1',
            'lng': '27.9',
          },
        },
      ],
      'combinedLotDeliveries': [
        {'_id': 'combined-delivery', 'buyerId': '4010'},
      ],
    });

    expect(dto.buyerId, '3068');
    expect(dto.buyerName, 'Main Client');
    expect(dto.lots.first.farmName, 'Acacia Farm');
    expect(dto.lots.first.latitude, '-25.7461');
    expect(dto.lots.first.longitude, '28.1881');
    expect(dto.lots[1].buyerName, 'Second Client');
    expect(dto.lots[1].farmName, 'River Farm');
    expect(dto.lots[1].latitude, '-26.1');
    expect(dto.lots[1].longitude, '27.9');
  });

  test('prefers client coordinates and falls back to generic coordinates', () {
    final dto = DeliveryScheduleDto.fromJson({
      '_id': 'main-delivery',
      'buyerId': '3068',
      'buyerName': 'Main Client',
      'clientLatitude': '-25.7000',
      'clientLongitude': '28.1000',
      'latitude': '-25.9000',
      'longitude': '28.9000',
      'auctionId': '216',
      'scheduleDate': '2026-08-09T14:01:00.000Z',
      'deliveryStatus': 'started',
      'combinedLotBuyers': [
        {
          'buyerId': '4010',
          'buyerName': 'Second Client',
          'clientLatitude': null,
          'clientLongitude': '',
          'latitude': '-26.1000',
          'longitude': '27.9000',
        },
      ],
      'combinedLotDeliveries': [
        {'_id': 'combined-delivery', 'buyerId': '4010'},
      ],
    });

    expect(dto.lots.first.latitude, '-25.7000');
    expect(dto.lots.first.longitude, '28.1000');
    expect(dto.lots[1].latitude, '-26.1000');
    expect(dto.lots[1].longitude, '27.9000');
  });

  test('parses client coordinates from combined delivery response rows', () {
    final dto = DeliveryScheduleDto.fromJson({
      '_id': '6a7bce6bba1e9bc860c74ded',
      'buyerId': '3068',
      'buyerName': 'User #3068',
      'address': '6A 2ND Street brindhavan nagar avadi',
      'companyName': 'ABC COMPANY',
      'contactNumber': '09150237873',
      'latitude': null,
      'longitude': null,
      'clientLatitude': '89',
      'clientLongitude': '90',
      'auctionId': '216',
      'scheduleDate': '2026-08-14T01:38:00.000Z',
      'deliveryStatus': 'started',
      'paymentStatus': true,
      'deliveryType': 'Load',
      'combinedLotBuyers': ['5050', '5161'],
      'combinedLotDeliveries': [
        {
          '_id': '6a7bcec2ba1e9bc860c74df7',
          'buyerId': '5050',
          'buyerName': null,
          'address': '6A 2ND Street brindhavan nagar avadi',
          'companyName': 'ABC COMPANY',
          'contactNumber': '09150237873',
          'latitude': null,
          'longitude': null,
          'clientLatitude': '89',
          'clientLongitude': '90',
          'deliveryStatus': 'started',
        },
        {
          '_id': '6a7f0d169ffb4e6d48111933',
          'buyerId': '5161',
          'buyerName': null,
          'address': '6A 2ND Street brindhavan nagar avadi',
          'companyName': 'ABC COMPANY',
          'contactNumber': '09150237873',
          'latitude': null,
          'longitude': null,
          'clientLatitude': '89',
          'clientLongitude': '90',
          'deliveryStatus': 'started',
        },
      ],
    });

    expect(dto.lots, hasLength(3));
    expect(dto.lots.map((lot) => lot.buyerId), ['3068', '5050', '5161']);
    expect(dto.lots.map((lot) => lot.latitude), everyElement('89'));
    expect(dto.lots.map((lot) => lot.longitude), everyElement('90'));
    expect(dto.lots[1].buyerName, '5050');
    expect(dto.lots[2].buyerName, '5161');
  });
}
