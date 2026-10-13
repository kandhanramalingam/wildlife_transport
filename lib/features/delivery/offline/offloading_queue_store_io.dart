import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/photo_meta.dart';
import '../models/start_delivery_submission.dart';
import 'offloading_queue_store.dart';

OffloadingQueueStore createOffloadingQueueStore() =>
    const SecureOffloadingQueueStore();

class SecureOffloadingQueueStore implements OffloadingQueueStore {
  static const _queueKey = 'pending_offloading_queue_v1';
  static Future<void> _queueWriteTail = Future<void>.value();
  final FlutterSecureStorage _storage;

  const SecureOffloadingQueueStore([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  ]);

  @override
  Future<List<PendingOffloadingJob>> load() async {
    final raw = await _storage.read(key: _queueKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Invalid saved off-loading queue');
      }
      final jobs = <PendingOffloadingJob>[];
      for (final value in decoded) {
        try {
          final json = Map<String, dynamic>.from(value as Map);
          final photos = (json['photos'] as List? ?? const [])
              .whereType<Map>()
              .map((item) => _photoFromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false);
          final video = _photoFromJson(
            Map<String, dynamic>.from(json['video'] as Map),
          );
          final checklist = (json['checklist'] as List? ?? const [])
              .whereType<Map>()
              .map((item) {
                final entry = Map<String, dynamic>.from(item);
                return DeliveryChecklistItem(
                  item: entry['item']?.toString() ?? '',
                  checked: entry['checked'] == true,
                  reason: entry['reason']?.toString(),
                );
              })
              .toList(growable: false);
          final signaturePath = json['signaturePath']?.toString() ?? '';
          jobs.add(
            PendingOffloadingJob(
              id: json['id'].toString(),
              deliveryId: json['deliveryId'].toString(),
              vehicleId: json['vehicleId']?.toString(),
              queuedAt: DateTime.parse(json['queuedAt'].toString()),
              submission: CompleteOffloadingSubmission(
                endAnimalPhotos: photos,
                endAnimalVideos: video,
                offLoadChecklist: checklist,
                clientSignature: await File(signaturePath).readAsBytes(),
                endOdometerReading: (json['endOdometerReading'] as num).toInt(),
                buyerId: json['buyerId'].toString(),
                clientComment: json['clientComment']?.toString(),
              ),
            ),
          );
        } catch (_) {
          // Never report a damaged submission as successfully synced or empty.
          throw StateError('Saved off-loading evidence could not be read');
        }
      }
      jobs.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
      return jobs;
    } catch (_) {
      throw StateError('Saved off-loading queue could not be read');
    }
  }

  @override
  Future<PendingOffloadingJob> enqueue({
    required String deliveryId,
    required String? vehicleId,
    required CompleteOffloadingSubmission submission,
  }) async {
    final queuedAt = DateTime.now().toUtc();
    final id = '${_safeName(deliveryId)}_${queuedAt.microsecondsSinceEpoch}';
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/pending_offloading/$id');
    await directory.create(recursive: true);

    final photoJson = <Map<String, dynamic>>[];
    for (var index = 0; index < submission.endAnimalPhotos.length; index++) {
      photoJson.add(
        await _persistPhoto(
          submission.endAnimalPhotos[index],
          directory,
          'photo_$index',
        ),
      );
    }
    final videoJson = await _persistPhoto(
      submission.endAnimalVideos,
      directory,
      'video',
    );
    final signaturePath = '${directory.path}/client_signature.png';
    await File(
      signaturePath,
    ).writeAsBytes(submission.clientSignature, flush: true);

    final entry = <String, dynamic>{
      'id': id,
      'deliveryId': deliveryId,
      if (vehicleId?.trim().isNotEmpty == true) 'vehicleId': vehicleId!.trim(),
      'queuedAt': queuedAt.toIso8601String(),
      'photos': photoJson,
      'video': videoJson,
      'checklist': submission.offLoadChecklist
          .map((item) => item.toJson())
          .toList(growable: false),
      'signaturePath': signaturePath,
      'endOdometerReading': submission.endOdometerReading,
      'buyerId': submission.buyerId,
      if (submission.clientComment?.trim().isNotEmpty == true)
        'clientComment': submission.clientComment!.trim(),
    };
    await _serializeQueueWrite(() async {
      final queue = await _readJsonQueue();
      queue.add(entry);
      await _storage.write(key: _queueKey, value: jsonEncode(queue));
    });

    return PendingOffloadingJob(
      id: id,
      deliveryId: deliveryId,
      vehicleId: vehicleId,
      queuedAt: queuedAt,
      submission: submission,
    );
  }

  @override
  Future<void> remove(PendingOffloadingJob job) async {
    await _serializeQueueWrite(() async {
      final queue = await _readJsonQueue();
      queue.removeWhere((item) => item['id'] == job.id);
      if (queue.isEmpty) {
        await _storage.delete(key: _queueKey);
      } else {
        await _storage.write(key: _queueKey, value: jsonEncode(queue));
      }
    });
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/pending_offloading/${job.id}');
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  // Enqueue and acknowledgement both read/modify the same manifest. Serialize
  // them so completing one upload cannot overwrite a newly saved submission.
  Future<void> _serializeQueueWrite(Future<void> Function() write) {
    final operation = _queueWriteTail.then((_) => write());
    _queueWriteTail = operation.catchError((Object _) {});
    return operation;
  }

  Future<List<Map<String, dynamic>>> _readJsonQueue() async {
    final raw = await _storage.read(key: _queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Invalid saved off-loading queue');
      }
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      // Do not overwrite an unreadable manifest with a new empty queue.
      throw StateError('Saved off-loading queue could not be read');
    }
  }

  Future<Map<String, dynamic>> _persistPhoto(
    PhotoMeta media,
    Directory directory,
    String baseName,
  ) async {
    final extension = _extension(media.photo.name);
    final path = '${directory.path}/$baseName$extension';
    await File(path).writeAsBytes(await media.photo.readAsBytes(), flush: true);
    return {
      'path': path,
      'name': media.photo.name,
      'capturedAt': media.dateTime.toUtc().toIso8601String(),
      'latitude': media.latitude,
      'longitude': media.longitude,
      if (media.lotNumber?.trim().isNotEmpty == true)
        'lotNumber': media.lotNumber!.trim(),
    };
  }

  static PhotoMeta _photoFromJson(Map<String, dynamic> json) => PhotoMeta(
    photo: XFile(json['path'].toString(), name: json['name']?.toString()),
    dateTime: DateTime.parse(json['capturedAt'].toString()),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    lotNumber: json['lotNumber']?.toString(),
  );

  static String _extension(String name) {
    final index = name.lastIndexOf('.');
    if (index <= 0 || index == name.length - 1) return '';
    return name.substring(index).replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '');
  }

  static String _safeName(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
