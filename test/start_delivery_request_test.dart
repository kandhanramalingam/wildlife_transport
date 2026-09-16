import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/start_delivery_submission.dart';

void main() {
  test('serializes the start delivery API payload', () {
    const request = StartDeliveryRequest(
      startMediaMetadata: [],
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
      'startMediaMetadata': [],
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

  test('serializes start delivery with manager and other signature metadata', () {
    const request = StartDeliveryRequest(
      startMediaMetadata: [],
      startOdometerReading: 12500,
      startVehiclePhotos: ['uploads/images/vehicle.png'],
      startAnimalPhotos: ['uploads/images/animal.png'],
      onLoadAnimalsVideo: 'uploads/videos/animals.mp4',
      startLatitude: '-25.74611',
      startLongitude: '28.18806',
      vehicleChecklist: [],
      gameLoadingChecklist: [],
      managerSignature: 'uploads/images/manager-signature.png',
      managerSignatureMetadata: {
        'capturedAt': '2026-09-16T12:00:00.000Z',
        'latitude': -25.74611,
        'longitude': 28.18806,
      },
      otherSignature: 'uploads/images/other-signature.png',
      otherSignatureMetadata: {
        'capturedAt': '2026-09-16T12:00:00.000Z',
        'latitude': -25.74611,
        'longitude': 28.18806,
      },
    );

    expect(request.toJson(), {
      'startMediaMetadata': [],
      'startOdometerReading': 12500,
      'startVehiclePhotos': ['uploads/images/vehicle.png'],
      'startAnimalPhotos': ['uploads/images/animal.png'],
      'onLoadAnimalsVideo': 'uploads/videos/animals.mp4',
      'startLatitude': '-25.74611',
      'startLongitude': '28.18806',
      'vehicleChecklist': [],
      'gameLoadingChecklist': [],
      'managerSignature': 'uploads/images/manager-signature.png',
      'managerSignatureMetadata': {
        'capturedAt': '2026-09-16T12:00:00.000Z',
        'latitude': -25.74611,
        'longitude': 28.18806,
      },
      'otherSignature': 'uploads/images/other-signature.png',
      'otherSignatureMetadata': {
        'capturedAt': '2026-09-16T12:00:00.000Z',
        'latitude': -25.74611,
        'longitude': 28.18806,
      },
    });
  });

  test('serializes the end delivery API payload', () {
    const request = CompleteOffloadingRequest(
      endMediaMetadata: [],
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
      'endMediaMetadata': [],
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

  test('serializes checklist item with uncheck reason and offloading client comment', () {
    const itemWithReason = DeliveryChecklistItem(
      item: 'Spare wheel',
      checked: false,
      reason: 'Tyre punctured at base',
    );
    expect(itemWithReason.toJson(), {
      'item': 'Spare wheel',
      'checked': false,
      'reason': 'Tyre punctured at base',
    });

    const offloadingRequest = CompleteOffloadingRequest(
      endMediaMetadata: [],
      endAnimalPhotos: ['uploads/images/end-animal.png'],
      endAnimalVideos: 'uploads/videos/off-loading.mp4',
      offLoadChecklist: [
        DeliveryChecklistItem(item: 'Check quantities', checked: true),
      ],
      clientSignature: 'uploads/images/client-signature.png',
      endOdometerReading: 12820,
      buyerId: '5150',
      clientComment: 'All 4 gemsbok received in good health',
    );

    expect(offloadingRequest.toJson(), {
      'endMediaMetadata': [],
      'endAnimalPhotos': ['uploads/images/end-animal.png'],
      'endAnimalVideos': 'uploads/videos/off-loading.mp4',
      'offLoadChecklist': [
        {'item': 'Check quantities', 'checked': true},
      ],
      'clientSignature': 'uploads/images/client-signature.png',
      'endOdometerReading': 12820,
      'buyerId': '5150',
      'comment': 'All 4 gemsbok received in good health',
    });
  });
}
