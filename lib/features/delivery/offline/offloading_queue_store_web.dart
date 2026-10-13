import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../models/start_delivery_submission.dart';
import 'offloading_job_codec.dart';
import 'offloading_queue_store.dart';

OffloadingQueueStore createOffloadingQueueStore() =>
    IndexedDbOffloadingQueueStore();

class IndexedDbOffloadingQueueStore implements OffloadingQueueStore {
  final String databaseName;
  static const _storeName = 'submissions';
  Future<web.IDBDatabase>? _database;

  IndexedDbOffloadingQueueStore({
    this.databaseName = 'awa_transport_offloading_v1',
  });

  Future<web.IDBDatabase> _open() =>
      _database ??= _openDatabase().catchError((Object error) {
        _database = null;
        throw error;
      });

  Future<web.IDBDatabase> _openDatabase() async {
    final factory = web.window.indexedDB;
    final request = factory.open(databaseName, 1);
    request.onupgradeneeded = ((web.Event _) {
      final database = request.result as web.IDBDatabase;
      database.createObjectStore(_storeName);
    }).toJS;
    final database = await _request(request) as web.IDBDatabase;
    database.onversionchange = ((web.Event _) {
      database.close();
      _database = null;
    }).toJS;
    return database;
  }

  @override
  Future<List<PendingOffloadingJob>> load() async {
    final database = await _open();
    final transaction = database.transaction(_storeName.toJS, 'readonly');
    final result = await _request(transaction.objectStore(_storeName).getAll());
    final values = (result as JSArray<JSString>).toDart;
    final jobs = values
        .map((value) => decodeOffloadingJob(value.toDart))
        .toList();
    jobs.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return jobs;
  }

  @override
  Future<PendingOffloadingJob> enqueue({
    required String deliveryId,
    required String? vehicleId,
    required CompleteOffloadingSubmission submission,
  }) async {
    final queuedAt = DateTime.now().toUtc();
    final job = PendingOffloadingJob(
      id: '${deliveryId}_${web.window.crypto.randomUUID()}',
      deliveryId: deliveryId,
      vehicleId: vehicleId,
      queuedAt: queuedAt,
      submission: submission,
    );
    final encoded = await encodeOffloadingJob(job);
    final database = await _open();
    final transaction = database.transaction(_storeName.toJS, 'readwrite');
    final completion = _committed(transaction);
    transaction.objectStore(_storeName).put(encoded.toJS, job.id.toJS);
    // Report "saved" only after the complete transaction commits to storage.
    await completion;
    return job;
  }

  @override
  Future<void> remove(PendingOffloadingJob job) async {
    final database = await _open();
    final transaction = database.transaction(_storeName.toJS, 'readwrite');
    final completion = _committed(transaction);
    transaction.objectStore(_storeName).delete(job.id.toJS);
    await completion;
  }

  Future<JSAny?> _request(web.IDBRequest request) {
    final completer = Completer<JSAny?>();
    request.onsuccess = ((web.Event _) => completer.complete(
      request.result,
    )).toJS;
    request.onerror = ((web.Event _) {
      completer.completeError(
        StateError(request.error?.message ?? 'Could not read offline evidence'),
      );
    }).toJS;
    return completer.future;
  }

  Future<void> _committed(web.IDBTransaction transaction) {
    final completer = Completer<void>();
    transaction.oncomplete = ((web.Event _) => completer.complete()).toJS;
    transaction.onabort = ((web.Event _) {
      completer.completeError(
        StateError(
          transaction.error?.message ?? 'Could not save offline evidence',
        ),
      );
    }).toJS;
    return completer.future;
  }
}
