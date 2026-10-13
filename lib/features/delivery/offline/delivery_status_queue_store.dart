import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/delivery_model.dart';

class PendingDeliveryStatus {
  final String id;
  final String deliveryId;
  final String? vehicleId;
  final DeliveryStatusUpdate status;

  const PendingDeliveryStatus({
    required this.id,
    required this.deliveryId,
    required this.vehicleId,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deliveryId': deliveryId,
    'vehicleId': vehicleId,
    'status': status.apiValue,
  };

  factory PendingDeliveryStatus.fromJson(Map<String, dynamic> json) =>
      PendingDeliveryStatus(
        id: json['id'] as String,
        deliveryId: json['deliveryId'] as String,
        vehicleId: json['vehicleId'] as String?,
        status: DeliveryStatusUpdate.values.firstWhere(
          (status) => status.apiValue == json['status'],
        ),
      );
}

abstract interface class DeliveryStatusQueueStore {
  Future<List<PendingDeliveryStatus>> load();
  Future<void> add(PendingDeliveryStatus job);
  Future<void> remove(PendingDeliveryStatus job);
}

class SecureDeliveryStatusQueueStore implements DeliveryStatusQueueStore {
  static const _key = 'pending_delivery_statuses_v1';
  static Future<void> _writeTail = Future<void>.value();
  final FlutterSecureStorage _storage;

  const SecureDeliveryStatusQueueStore([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  ]);

  @override
  Future<List<PendingDeliveryStatus>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];
    // A corrupt manifest must surface as a storage error, never an empty queue.
    return (jsonDecode(raw) as List)
        .map(
          (value) => PendingDeliveryStatus.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> add(PendingDeliveryStatus job) => _write(() async {
    final jobs = await load();
    jobs.add(job);
    await _save(jobs);
  });

  @override
  Future<void> remove(PendingDeliveryStatus job) => _write(() async {
    final jobs = await load();
    jobs.removeWhere((pending) => pending.id == job.id);
    await _save(jobs);
  });

  Future<void> _save(List<PendingDeliveryStatus> jobs) async {
    if (jobs.isEmpty) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(
        key: _key,
        value: jsonEncode(jobs.map((job) => job.toJson()).toList()),
      );
    }
  }

  Future<void> _write(Future<void> Function() action) {
    final operation = _writeTail.then((_) => action());
    _writeTail = operation.catchError((Object _) {});
    return operation;
  }
}
