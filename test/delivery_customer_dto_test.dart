import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_customer_dto.dart';

void main() {
  test('parses main and combined customer delivery rows', () {
    final mainBuyer = DeliveryCustomerDto.fromJson({
      'clientName': 'User #2119',
      'value': '2119',
      'completed': false,
      'mainBuyer': true,
      'deliveryId': 'main-delivery-id',
    });
    final combinedBuyer = DeliveryCustomerDto.fromJson({
      'clientName': null,
      'value': '5150',
      'completed': true,
      'mainBuyer': false,
      'deliveryId': 'combined-delivery-id',
    });

    expect(mainBuyer.clientName, 'User #2119');
    expect(mainBuyer.mainBuyer, isTrue);
    expect(mainBuyer.completed, isFalse);
    expect(combinedBuyer.clientName, '5150');
    expect(combinedBuyer.deliveryId, 'combined-delivery-id');
    expect(combinedBuyer.completed, isTrue);
  });
}
