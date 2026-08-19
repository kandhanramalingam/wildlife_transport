import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/start_delivery_submission.dart';

void main() {
  test('serializes the start delivery API payload', () {
    const request = StartDeliveryRequest(
      startOdometerReading: 12500,
      startVehiclePhotos: ['uploads/images/vehicle.png'],
      startAnimalPhotos: ['uploads/images/animal.png'],
      onLoadAnimalsVideo: 'uploads/videos/animals.mp4',
      startLatitude: '-25.74611',
      startLongitude: '28.18806',
      vehicleChecklist: [
        DeliveryChecklistItem(item: 'Brakes working', checked: true),
      ],
      gameLoadingChecklist: [
        DeliveryChecklistItem(item: 'Confirm quantity', checked: true),
      ],
      managerSignature: 'uploads/images/manager-signature.png',
      otherSignature: 'uploads/images/other-signature.png',
    );

    expect(request.toJson(), {
      'startOdometerReading': 12500,
      'startVehiclePhotos': ['uploads/images/vehicle.png'],
      'startAnimalPhotos': ['uploads/images/animal.png'],
      'onLoadAnimalsVideo': 'uploads/videos/animals.mp4',
      'startLatitude': '-25.74611',
      'startLongitude': '28.18806',
      'vehicleChecklist': [
        {'item': 'Brakes working', 'checked': true},
      ],
      'gameLoadingChecklist': [
        {'item': 'Confirm quantity', 'checked': true},
      ],
      'managerSignature': 'uploads/images/manager-signature.png',
      'otherSignature': 'uploads/images/other-signature.png',
    });
  });

  test('serializes the end delivery API payload', () {
    const request = CompleteOffloadingRequest(
      endAnimalPhotos: ['uploads/images/end-animal.png'],
      endAnimalVideos: 'uploads/videos/off-loading.mp4',
      offLoadChecklist: [
        DeliveryChecklistItem(item: 'Confirm animal health', checked: true),
      ],
      clientSignature: 'uploads/images/client-signature.png',
      endOdometerReading: 12820,
      buyerId: '5150',
    );

    expect(request.toJson(), {
      'endAnimalPhotos': ['uploads/images/end-animal.png'],
      'endAnimalVideos': 'uploads/videos/off-loading.mp4',
      'offLoadChecklist': [
        {'item': 'Confirm animal health', 'checked': true},
      ],
      'clientSignature': 'uploads/images/client-signature.png',
      'endOdometerReading': 12820,
      'buyerId': '5150',
    });
  });
}
