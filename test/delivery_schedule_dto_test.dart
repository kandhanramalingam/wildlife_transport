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
      'auctionId': 'auction-1',
      'scheduleDate': '2026-07-18T17:17:27.208Z',
      'deliveryStatus': 'pending',
      'paymentStatus': true,
    });

    expect(dto.id, 'schedule-1');
    expect(dto.buyerName, 'Buyer Name');
    expect(dto.scheduleDate.isUtc, isTrue);
    expect(dto.paymentStatus, isTrue);
    expect(DeliveryStatus.fromApi(dto.deliveryStatus), DeliveryStatus.pending);
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
}
