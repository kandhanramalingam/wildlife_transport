import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/profile/data/driver_profile_dto.dart';

void main() {
  test('parses driver profile and assigned vehicle', () {
    final profile = DriverProfileDto.fromJson({
      'id': '642be2b55e6069098e0b27d7',
      'name': 'Shephard Sitole',
      'phone': '8306177465',
      'licenceExpiry': '2023-11-30',
      'allocationStartDate': '2026-06-23T00:00:00.000Z',
      'vehicle': {
        '_id': '67cc03302f924dca2b17b4bc',
        'make': 'TRUCK DEVON 3 COMP FIX',
        'year': 1990,
        'registrationNumber': 'JN41LYGP',
        'compartmentNumber': 3,
        'active': true,
      },
      'vehiclecombination': null,
    }).toModel();

    expect(profile.name, 'Shephard Sitole');
    expect(profile.phone, '8306177465');
    expect(profile.allocationStartDate!.isUtc, isTrue);
    expect(profile.vehicle!.registrationNumber, 'JN41LYGP');
    expect(profile.vehicle!.compartmentNumber, 3);
    expect(profile.vehicleCombination, isNull);
  });
}
