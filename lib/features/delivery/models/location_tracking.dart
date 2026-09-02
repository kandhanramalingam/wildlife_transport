class DriverLocationReading {
  final String localId;
  final String deliveryId;
  final double latitude;
  final double longitude;
  final double accuracyMetres;
  final DateTime recordedAt;

  const DriverLocationReading({
    required this.localId,
    required this.deliveryId,
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    required this.recordedAt,
  });

  Map<String, dynamic> toApiJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMetres': accuracyMetres,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> toStorageJson() => {
    'localId': localId,
    'deliveryId': deliveryId,
    ...toApiJson(),
  };

  factory DriverLocationReading.fromStorageJson(Map<String, dynamic> json) {
    return DriverLocationReading(
      localId: json['localId'] as String,
      deliveryId: json['deliveryId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMetres: (json['accuracyMetres'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String).toUtc(),
    );
  }
}

class CustomerLocationCapture {
  final String deliveryId;
  final String buyerId;
  final double latitude;
  final double longitude;
  final double accuracyMetres;
  final DateTime capturedAt;

  const CustomerLocationCapture({
    required this.deliveryId,
    required this.buyerId,
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    required this.capturedAt,
  });

  Map<String, dynamic> toApiJson() => {
    'buyerId': buyerId,
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMetres': accuracyMetres,
    'capturedAt': capturedAt.toUtc().toIso8601String(),
  };
}

class SavedCustomerLocation {
  final String clientId;
  final String buyerId;
  final double latitude;
  final double longitude;
  final double accuracyMetres;
  final DateTime capturedAt;
  final DateTime? updatedAt;

  const SavedCustomerLocation({
    required this.clientId,
    required this.buyerId,
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    required this.capturedAt,
    this.updatedAt,
  });

  factory SavedCustomerLocation.fromJson(Map<String, dynamic> json) {
    return SavedCustomerLocation(
      clientId: json['clientId']?.toString() ?? '',
      buyerId: json['buyerId']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMetres: (json['accuracyMetres'] as num?)?.toDouble() ?? 0,
      capturedAt: DateTime.parse(json['capturedAt'] as String).toUtc(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString())?.toUtc(),
    );
  }
}
