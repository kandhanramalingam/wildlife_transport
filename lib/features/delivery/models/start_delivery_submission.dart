import 'dart:typed_data';

import 'photo_meta.dart';

class DeliveryChecklistItem {
  final String item;
  final bool checked;
  final String? reason;

  const DeliveryChecklistItem({
    required this.item,
    required this.checked,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'item': item,
    'checked': checked,
    if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
  };
}

class StartDeliverySubmission {
  final int startOdometerReading;
  final List<PhotoMeta> startVehiclePhotos;
  final List<PhotoMeta> startAnimalPhotos;
  final PhotoMeta onLoadAnimalsVideo;
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
  final List<Map<String, dynamic>> startMediaMetadata;
  final int startOdometerReading;
  final List<String> startVehiclePhotos;
  final List<String> startAnimalPhotos;
  final String onLoadAnimalsVideo;
  final String startLatitude;
  final String startLongitude;
  final List<DeliveryChecklistItem> vehicleChecklist;
  final List<DeliveryChecklistItem> gameLoadingChecklist;
  final String managerSignature;
  final Map<String, dynamic>? managerSignatureMetadata;
  final String otherSignature;
  final Map<String, dynamic>? otherSignatureMetadata;

  const StartDeliveryRequest({
    required this.startMediaMetadata,
    required this.startOdometerReading,
    required this.startVehiclePhotos,
    required this.startAnimalPhotos,
    required this.onLoadAnimalsVideo,
    required this.startLatitude,
    required this.startLongitude,
    required this.vehicleChecklist,
    required this.gameLoadingChecklist,
    required this.managerSignature,
    this.managerSignatureMetadata,
    required this.otherSignature,
    this.otherSignatureMetadata,
  });

  Map<String, dynamic> toJson() => {
    'startMediaMetadata': startMediaMetadata,
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
    if (managerSignatureMetadata != null)
      'managerSignatureMetadata': managerSignatureMetadata,
    'otherSignature': otherSignature,
    if (otherSignatureMetadata != null)
      'otherSignatureMetadata': otherSignatureMetadata,
  };
}

class CompleteOffloadingSubmission {
  final List<PhotoMeta> endAnimalPhotos;
  final PhotoMeta endAnimalVideos;
  final List<DeliveryChecklistItem> offLoadChecklist;
  final Uint8List clientSignature;
  final int endOdometerReading;
  final String buyerId;
  final String? clientComment;

  const CompleteOffloadingSubmission({
    required this.endAnimalPhotos,
    required this.endAnimalVideos,
    required this.offLoadChecklist,
    required this.clientSignature,
    required this.endOdometerReading,
    required this.buyerId,
    this.clientComment,
  });
}

class CompleteOffloadingRequest {
  final List<Map<String, dynamic>> endMediaMetadata;
  final List<String> endAnimalPhotos;
  final String endAnimalVideos;
  final List<DeliveryChecklistItem> offLoadChecklist;
  final String clientSignature;
  final int endOdometerReading;
  final String buyerId;
  final String? clientComment;

  const CompleteOffloadingRequest({
    required this.endMediaMetadata,
    required this.endAnimalPhotos,
    required this.endAnimalVideos,
    required this.offLoadChecklist,
    required this.clientSignature,
    required this.endOdometerReading,
    required this.buyerId,
    this.clientComment,
  });

  Map<String, dynamic> toJson() => {
    'endMediaMetadata': endMediaMetadata,
    'endAnimalPhotos': endAnimalPhotos,
    'endAnimalVideos': endAnimalVideos,
    'offLoadChecklist': offLoadChecklist.map((item) => item.toJson()).toList(),
    'clientSignature': clientSignature,
    'endOdometerReading': endOdometerReading,
    'buyerId': buyerId,
    if (clientComment != null && clientComment!.trim().isNotEmpty)
      'comment': clientComment!.trim(),
  };
}
