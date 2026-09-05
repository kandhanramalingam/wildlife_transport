import 'package:image_picker/image_picker.dart';

/// A media file and the location/time recorded when capture completed.
class PhotoMeta {
  final XFile photo;
  final DateTime dateTime;
  final double latitude;
  final double longitude;

  const PhotoMeta({
    required this.photo,
    required this.dateTime,
    required this.latitude,
    required this.longitude,
  });

  String get location =>
      '${latitude.toStringAsFixed(5)}°, ${longitude.toStringAsFixed(5)}°';

  Map<String, dynamic> uploadedMetadata(String filePath, String kind) => {
    'filePath': filePath,
    'kind': kind,
    'capturedAt': dateTime.toUtc().toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };
}
