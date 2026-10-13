import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../models/photo_meta.dart';
import '../models/start_delivery_submission.dart';
import 'offloading_queue_store.dart';

// Browser evidence is copied into IndexedDB rather than retaining temporary
// blob URLs, which stop working when the page is refreshed.
Future<String> encodeOffloadingJob(PendingOffloadingJob job) async {
  final submission = job.submission;
  Future<Map<String, dynamic>> encodeMedia(PhotoMeta media) async => {
    'bytes': base64Encode(await media.photo.readAsBytes()),
    'name': media.photo.name,
    'capturedAt': media.dateTime.toUtc().toIso8601String(),
    'latitude': media.latitude,
    'longitude': media.longitude,
    'lotNumber': media.lotNumber,
  };

  return jsonEncode({
    'id': job.id,
    'deliveryId': job.deliveryId,
    'vehicleId': job.vehicleId,
    'queuedAt': job.queuedAt.toIso8601String(),
    'photos': await Future.wait(submission.endAnimalPhotos.map(encodeMedia)),
    'video': await encodeMedia(submission.endAnimalVideos),
    'signature': base64Encode(submission.clientSignature),
    'checklist': submission.offLoadChecklist
        .map((item) => item.toJson())
        .toList(),
    'endOdometerReading': submission.endOdometerReading,
    'buyerId': submission.buyerId,
    'clientComment': submission.clientComment,
  });
}

PendingOffloadingJob decodeOffloadingJob(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  PhotoMeta decodeMedia(dynamic value) {
    final media = Map<String, dynamic>.from(value as Map);
    return PhotoMeta(
      photo: XFile.fromData(
        base64Decode(media['bytes'] as String),
        name: media['name'] as String,
      ),
      dateTime: DateTime.parse(media['capturedAt'] as String),
      latitude: (media['latitude'] as num).toDouble(),
      longitude: (media['longitude'] as num).toDouble(),
      lotNumber: media['lotNumber'] as String?,
    );
  }

  return PendingOffloadingJob(
    id: json['id'] as String,
    deliveryId: json['deliveryId'] as String,
    vehicleId: json['vehicleId'] as String?,
    queuedAt: DateTime.parse(json['queuedAt'] as String),
    submission: CompleteOffloadingSubmission(
      endAnimalPhotos: (json['photos'] as List).map(decodeMedia).toList(),
      endAnimalVideos: decodeMedia(json['video']),
      clientSignature: base64Decode(json['signature'] as String),
      offLoadChecklist: (json['checklist'] as List).map((value) {
        final item = Map<String, dynamic>.from(value as Map);
        return DeliveryChecklistItem(
          item: item['item'] as String,
          checked: item['checked'] as bool,
          reason: item['reason'] as String?,
        );
      }).toList(),
      endOdometerReading: json['endOdometerReading'] as int,
      buyerId: json['buyerId'] as String,
      clientComment: json['clientComment'] as String?,
    ),
  );
}
