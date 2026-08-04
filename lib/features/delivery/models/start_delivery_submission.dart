import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class DeliveryChecklistItem {
  final String item;
  final bool checked;

  const DeliveryChecklistItem({required this.item, required this.checked});

  Map<String, dynamic> toJson() => {'item': item, 'checked': checked};
}

class StartDeliverySubmission {
  final int startOdometerReading;
  final List<XFile> startVehiclePhotos;
  final List<XFile> startAnimalPhotos;
  final XFile onLoadAnimalsVideo;
  final String startLatitude;
  final String startLongitude;
  final List<DeliveryChecklistItem> vehicleChecklist;
  final List<DeliveryChecklistItem> gameLoadingChecklist;
  final Uint8List managerSignature;
  final Uint8List otherSignature;

  const StartDeliverySubmission({
    required this.startOdometerReading,
    required this.startVehiclePhotos,
    required this.startAnimalPhotos,
    required this.onLoadAnimalsVideo,
    required this.startLatitude,
    required this.startLongitude,
    required this.vehicleChecklist,
    required this.gameLoadingChecklist,
    required this.managerSignature,
    required this.otherSignature,
  });
}

class StartDeliveryRequest {
  final int startOdometerReading;
  final List<String> startVehiclePhotos;
  final List<String> startAnimalPhotos;
  final String onLoadAnimalsVideo;
  final String startLatitude;
  final String startLongitude;
  final List<DeliveryChecklistItem> vehicleChecklist;
  final List<DeliveryChecklistItem> gameLoadingChecklist;
  final String managerSignature;
  final String otherSignature;

  const StartDeliveryRequest({
    required this.startOdometerReading,
    required this.startVehiclePhotos,
    required this.startAnimalPhotos,
    required this.onLoadAnimalsVideo,
    required this.startLatitude,
    required this.startLongitude,
    required this.vehicleChecklist,
    required this.gameLoadingChecklist,
    required this.managerSignature,
    required this.otherSignature,
  });

  Map<String, dynamic> toJson() => {
    'startOdometerReading': startOdometerReading,
    'startVehiclePhotos': startVehiclePhotos,
    'startAnimalPhotos': startAnimalPhotos,
    'onLoadAnimalsVideo': onLoadAnimalsVideo,
    'startLatitude': startLatitude,
    'startLongitude': startLongitude,
    'vehicleChecklist': vehicleChecklist.map((item) => item.toJson()).toList(),
    'gameLoadingChecklist': gameLoadingChecklist
        .map((item) => item.toJson())
        .toList(),
    'managerSignature': managerSignature,
    'otherSignature': otherSignature,
  };
}
