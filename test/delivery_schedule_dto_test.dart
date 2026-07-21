import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_schedule_dto.dart';

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
  });
}
