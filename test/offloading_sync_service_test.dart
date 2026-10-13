import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wildlife_transport/core/connectivity/connectivity_monitor.dart';
import 'package:wildlife_transport/core/error/failure.dart';
import 'package:wildlife_transport/features/delivery/domain/delivery_repository.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/models/location_tracking.dart';
import 'package:wildlife_transport/features/delivery/models/photo_meta.dart';
import 'package:wildlife_transport/features/delivery/models/start_delivery_submission.dart';
import 'package:wildlife_transport/features/delivery/offline/offloading_queue_store.dart';
import 'package:wildlife_transport/features/delivery/offline/offloading_sync_service.dart';
import 'package:wildlife_transport/features/delivery/offline/delivery_status_queue_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'offline actions replay in order before evidence for multiple buyers',
    () async {
      final repository = _Repository();
      final store = _QueueStore();
      final statuses = _StatusStore();
      final connectivity = _Connectivity()..connected = false;
      final events = <String>[];
      repository.onComplete = (id) => events.add('$id:completed');
      final service = OffloadingSyncService(
        () => repository,
        store,
        connectivity,
        statusStore: statuses,
        replayStatus: (job) async =>
            events.add('${job.deliveryId}:${job.status.apiValue}'),
      );
      await service.start();
      for (final id in ['buyer-1', 'buyer-2']) {
        await service.submitStatus(
          deliveryId: id,
          vehicleId: 'vehicle-1',
          status: DeliveryStatusUpdate.arrivedAtLocation,
        );
        await service.submitStatus(
          deliveryId: id,
          vehicleId: 'vehicle-1',
          status: DeliveryStatusUpdate.offloadingStarted,
        );
        await service.submit(
          deliveryId: id,
          vehicleId: 'vehicle-1',
          submission: _submission(),
        );
      }
      expect(events, isEmpty);
      expect(service.pendingCount, 6);
      expect(service.pendingStatuses, {
        'buyer-1': DeliveryStatus.offloading,
        'buyer-2': DeliveryStatus.offloading,
      });
      connectivity.reconnect();
      await Future<void>.delayed(Duration.zero);
      await service.flushPending();
      expect(events, [
        'buyer-1:arrived_at_location',
        'buyer-1:offloading_started',
        'buyer-2:arrived_at_location',
        'buyer-2:offloading_started',
        'buyer-1:completed',
        'buyer-2:completed',
      ]);
      expect(service.pendingCount, 0);
      expect(statuses.jobs, isEmpty);
      expect(store.jobs, isEmpty);
      service.dispose();
      await connectivity.close();
    },
  );

  test(
    'interrupted status replay retains the remaining actions and evidence',
    () async {
      final repository = _Repository();
      final store = _QueueStore();
      final statuses = _StatusStore();
      final connectivity = _Connectivity()..connected = false;
      var attempts = 0;
      var fail = true;
      final service = OffloadingSyncService(
        () => repository,
        store,
        connectivity,
        statusStore: statuses,
        replayStatus: (job) async {
          attempts++;
          if (fail && job.status == DeliveryStatusUpdate.offloadingStarted) {
            throw const TimeoutFailure();
          }
        },
      );
      await service.submitStatus(
        deliveryId: 'delivery-1',
        vehicleId: null,
        status: DeliveryStatusUpdate.arrivedAtLocation,
      );
      await service.submitStatus(
        deliveryId: 'delivery-1',
        vehicleId: null,
        status: DeliveryStatusUpdate.offloadingStarted,
      );
      await service.submit(
        deliveryId: 'delivery-1',
        vehicleId: null,
        submission: _submission(),
      );
      connectivity.connected = true;
      await service.flushPending();
      expect(attempts, 2);
      expect(
        statuses.jobs.single.status,
        DeliveryStatusUpdate.offloadingStarted,
      );
      expect(repository.attempts, 0);
      expect(store.jobs, hasLength(1));
      fail = false;
      await service.flushPending();
      expect(attempts, 3);
      expect(repository.attempts, 1);
      expect(service.pendingCount, 0);
      service.dispose();
      await connectivity.close();
    },
  );

  test(
    'rejected status blocks its evidence but allows another buyer to sync',
    () async {
      final repository = _Repository();
      final store = _QueueStore();
      final statuses = _StatusStore();
      final connectivity = _Connectivity()..connected = false;
      final service = OffloadingSyncService(
        () => repository,
        store,
        connectivity,
        statusStore: statuses,
        replayStatus: (job) async {
          if (job.deliveryId == 'on-hold') {
            throw const ValidationFailure('Delivery is on hold');
          }
        },
      );
      for (final id in ['on-hold', 'valid']) {
        await service.submitStatus(
          deliveryId: id,
          vehicleId: null,
          status: DeliveryStatusUpdate.arrivedAtLocation,
        );
        await service.submit(
          deliveryId: id,
          vehicleId: null,
          submission: _submission(),
        );
      }
      connectivity.connected = true;
      await service.flushPending();
      expect(repository.deliveryIds, ['valid']);
      expect(store.jobs.single.deliveryId, 'on-hold');
      expect(service.pendingCount, 2);
      expect(service.lastError, 'Delivery is on hold');
      service.dispose();
      await connectivity.close();
    },
  );

  test(
    'online rejected arrival reports the error instead of advancing the driver',
    () async {
      final statuses = _StatusStore();
      final connectivity = _Connectivity();
      final service = OffloadingSyncService(
        () => _Repository(),
        _QueueStore(),
        connectivity,
        statusStore: statuses,
        replayStatus: (_) async =>
            throw const ValidationFailure('Delivery is on hold'),
      );
      await expectLater(
        service.submitStatus(
          deliveryId: 'delivery-1',
          vehicleId: null,
          status: DeliveryStatusUpdate.arrivedAtLocation,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(statuses.jobs, hasLength(1));
      // A second tap must still report the earlier rejection, rather than skip
      // the blocked job and incorrectly advance the driver into offloading.
      await expectLater(
        service.submitStatus(
          deliveryId: 'delivery-1',
          vehicleId: null,
          status: DeliveryStatusUpdate.arrivedAtLocation,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(statuses.jobs, hasLength(2));
      service.dispose();
      await connectivity.close();
    },
  );

  test('offline completion is queued without calling the API', () async {
    final repository = _Repository();
    final store = _QueueStore();
    final connectivity = _Connectivity()..connected = false;
    final service = OffloadingSyncService(
      () => repository,
      store,
      connectivity,
    );

    final result = await service.submit(
      deliveryId: 'delivery-1',
      vehicleId: 'vehicle-1',
      submission: _submission(),
    );

    expect(result, OffloadingSubmitResult.queued);
    expect(repository.attempts, 0);
    expect(store.jobs, hasLength(1));
    expect(service.isPending('delivery-1'), isTrue);
    service.dispose();
    await connectivity.close();
  });

  test('queued completion is submitted after connectivity returns', () async {
    final repository = _Repository();
    final store = _QueueStore();
    final connectivity = _Connectivity()..connected = false;
    final service = OffloadingSyncService(
      () => repository,
      store,
      connectivity,
    );
    await service.start();
    await service.submit(
      deliveryId: 'delivery-1',
      vehicleId: 'vehicle-1',
      submission: _submission(),
    );

    connectivity.reconnect();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(repository.attempts, 1);
    expect(store.jobs, isEmpty);
    expect(service.isPending('delivery-1'), isFalse);
    service.dispose();
    await connectivity.close();
  });

  test('an API network failure also persists the completion', () async {
    final repository = _Repository()..offline = true;
    final store = _QueueStore();
    final connectivity = _Connectivity()..connected = true;
    final service = OffloadingSyncService(
      () => repository,
      store,
      connectivity,
    );

    final result = await service.submit(
      deliveryId: 'delivery-1',
      vehicleId: null,
      submission: _submission(),
    );

    expect(result, OffloadingSubmitResult.queued);
    expect(repository.attempts, 1);
    expect(store.jobs, hasLength(1));
    service.dispose();
    await connectivity.close();
  });

  test(
    'reconnect during a failing upload retries after that upload finishes',
    () async {
      final repository = _Repository()
        ..response = Completer<void>()
        ..failAfterResponseAttempts = 1;
      final store = _QueueStore();
      final connectivity = _Connectivity()..connected = false;
      final service = OffloadingSyncService(
        () => repository,
        store,
        connectivity,
      );
      await service.start();
      await service.submit(
        deliveryId: 'delivery-1',
        vehicleId: 'vehicle-1',
        submission: _submission(),
      );
      connectivity.connected = true;
      final firstFlush = service.flushPending();
      await Future<void>.delayed(Duration.zero);
      expect(repository.attempts, 1);
      // The radio reconnects before the request using its old connection fails.
      connectivity.reconnect();
      await Future<void>.delayed(Duration.zero);
      repository.response!.complete();
      await firstFlush;
      expect(repository.attempts, 2);
      expect(store.jobs, isEmpty);
      expect(service.pendingCount, 0);
      service.dispose();
      await connectivity.close();
    },
  );

  test('online evidence is durable until the server acknowledges it', () async {
    final repository = _Repository()..response = Completer<void>();
    final store = _QueueStore();
    final connectivity = _Connectivity();
    final service = OffloadingSyncService(
      () => repository,
      store,
      connectivity,
    );
    final submission = service.submit(
      deliveryId: 'delivery-1',
      vehicleId: null,
      submission: _submission(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.attempts, 1);
    expect(store.jobs, hasLength(1));
    expect(service.pendingCount, 1);
    // Connectivity and manual retries during an upload share one request.
    final retries = [service.flushPending(), service.flushPending()];
    repository.response!.complete();
    expect(await submission, OffloadingSubmitResult.synced);
    await Future.wait(retries);
    expect(repository.attempts, 1);
    expect(store.jobs, isEmpty);
    expect(service.syncRevision, 1);
    service.dispose();
    await connectivity.close();
  });

  test(
    'one rejected delivery does not block the next saved completion',
    () async {
      final repository = _Repository()
        ..failures['rejected'] = const ValidationFailure('Delivery is on hold');
      final store = _QueueStore();
      for (final id in ['rejected', 'valid']) {
        await store.enqueue(
          deliveryId: id,
          vehicleId: null,
          submission: _submission(),
        );
      }
      final connectivity = _Connectivity();
      final service = OffloadingSyncService(
        () => repository,
        store,
        connectivity,
      );
      await service.flushPending();
      expect(repository.deliveryIds, ['rejected', 'valid']);
      expect(store.jobs.single.deliveryId, 'rejected');
      expect(service.lastError, 'Delivery is on hold');
      expect(service.pendingDeliveryIds, {'rejected'});
      repository.failures.clear();
      await service.flushPending();
      expect(store.jobs, isEmpty);
      expect(service.lastError, isNull);
      service.dispose();
      await connectivity.close();
    },
  );

  test('a server failure preserves evidence for a later retry', () async {
    final repository = _Repository()
      ..failures['delivery-1'] = const ServerFailure();
    final store = _QueueStore();
    final connectivity = _Connectivity();
    final service = OffloadingSyncService(
      () => repository,
      store,
      connectivity,
    );
    expect(
      await service.submit(
        deliveryId: 'delivery-1',
        vehicleId: null,
        submission: _submission(),
      ),
      OffloadingSubmitResult.queued,
    );
    expect(store.jobs, hasLength(1));
    repository.failures.clear();
    await service.flushPending();
    expect(store.jobs, isEmpty);
    expect(service.syncRevision, 1);
    service.dispose();
    await connectivity.close();
  });

  test(
    'missing delivery stays saved and identifies the failed job while other jobs sync',
    () async {
      final repository = _Repository()
        ..failures['missing-delivery'] = const DeliveryNotFoundFailure();
      final store = _QueueStore();
      for (final id in ['missing-delivery', 'valid-delivery']) {
        await store.enqueue(
          deliveryId: id,
          vehicleId: 'vehicle-1',
          submission: _submission(),
        );
      }
      final connectivity = _Connectivity();
      final service = OffloadingSyncService(
        () => repository,
        store,
        connectivity,
      );
      await service.flushPending();
      expect(store.jobs.single.deliveryId, 'missing-delivery');
      expect(service.lastFailedJob?.deliveryId, 'missing-delivery');
      expect(service.lastError, contains('photos and signature remain saved'));
      expect(service.pendingCount, 1);
      expect(repository.deliveryIds, ['missing-delivery', 'valid-delivery']);
      service.dispose();
      await connectivity.close();
    },
  );

  testWidgets(
    'retry timer does not keep a slow failed video submission waiting forever',
    (tester) async {
      final repository = _Repository()
        ..response = Completer<void>()
        ..failAfterResponseAttempts = 1;
      final store = _QueueStore();
      await store.enqueue(
        deliveryId: 'delivery-1',
        vehicleId: null,
        submission: _submission(),
      );
      final connectivity = _Connectivity()..connected = false;
      final service = OffloadingSyncService(
        () => repository,
        store,
        connectivity,
      );
      await service.start();
      await tester.pump();
      connectivity.connected = true;
      final flush = service.flushPending();
      await tester.pump();
      expect(repository.attempts, 1);
      await tester.pump(const Duration(minutes: 2));
      repository.response!.complete();
      await flush;
      expect(repository.attempts, 1);
      expect(store.jobs, hasLength(1));
      await tester.pump(const Duration(minutes: 1));
      expect(repository.attempts, 2);
      expect(store.jobs, isEmpty);
      service.dispose();
      await connectivity.close();
    },
  );

  testWidgets('saved jobs retry periodically without a connectivity event', (
    tester,
  ) async {
    final repository = _Repository()..offline = true;
    final store = _QueueStore();
    await store.enqueue(
      deliveryId: 'delivery-1',
      vehicleId: null,
      submission: _submission(),
    );
    final connectivity = _Connectivity();
    final service = OffloadingSyncService(
      () => repository,
      store,
      connectivity,
    );
    await service.start();
    await tester.pump();
    expect(store.jobs, hasLength(1));
    repository.offline = false;
    await tester.pump(const Duration(minutes: 1));
    expect(store.jobs, isEmpty);
    expect(repository.attempts, 2);
    service.dispose();
    await connectivity.close();
  });
}

CompleteOffloadingSubmission _submission() {
  final capturedAt = DateTime.utc(2026, 9, 30, 17);
  PhotoMeta media(String name) => PhotoMeta(
    photo: XFile.fromData(Uint8List.fromList([1, 2, 3]), name: name),
    dateTime: capturedAt,
    latitude: -24.29,
    longitude: 28.12,
  );

  return CompleteOffloadingSubmission(
    endAnimalPhotos: [media('animals.jpg')],
    endAnimalVideos: media('offloading.mp4'),
    offLoadChecklist: const [
      DeliveryChecklistItem(item: 'Animals checked', checked: true),
    ],
    clientSignature: Uint8List.fromList([4, 5, 6]),
    endOdometerReading: 1200,
    buyerId: 'buyer-1',
  );
}

class _Connectivity implements ConnectivityMonitor {
  bool connected = true;
  final _controller = StreamController<void>.broadcast();

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<void> get onConnected => _controller.stream;

  void reconnect() {
    connected = true;
    _controller.add(null);
  }

  Future<void> close() => _controller.close();
}

class _QueueStore implements OffloadingQueueStore {
  final jobs = <PendingOffloadingJob>[];

  @override
  Future<PendingOffloadingJob> enqueue({
    required String deliveryId,
    required String? vehicleId,
    required CompleteOffloadingSubmission submission,
  }) async {
    final job = PendingOffloadingJob(
      id: 'job-${jobs.length + 1}',
      deliveryId: deliveryId,
      vehicleId: vehicleId,
      queuedAt: DateTime.now().toUtc(),
      submission: submission,
    );
    jobs.add(job);
    return job;
  }

  @override
  Future<List<PendingOffloadingJob>> load() async => List.of(jobs);

  @override
  Future<void> remove(PendingOffloadingJob job) async => jobs.remove(job);
}

class _Repository implements DeliveryRepository {
  bool offline = false;
  int attempts = 0;
  final failures = <String, Failure>{};
  final deliveryIds = <String>[];
  Completer<void>? response;
  int failAfterResponseAttempts = 0;
  void Function(String)? onComplete;

  @override
  Future<DeliveryModel?> completeOffloading(
    String deliveryId,
    CompleteOffloadingSubmission submission, {
    String? vehicleId,
  }) async {
    attempts++;
    deliveryIds.add(deliveryId);
    if (offline) throw const NetworkFailure();
    final failure = failures[deliveryId];
    if (failure != null) throw failure;
    if (response != null) await response!.future;
    if (attempts <= failAfterResponseAttempts) throw const NetworkFailure();
    onComplete?.call(deliveryId);
    return null;
  }

  @override
  Future<DeliveryModel?> atDeliveryLocation(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> completeLoading(
    String deliveryId,
    StartDeliverySubmission submission, {
    String? vehicleId,
  }) async => null;

  @override
  Future<List<DeliveryModel>> getTodaySchedule({
    CancelToken? cancelToken,
  }) async => const [];

  @override
  Future<List<DeliveryModel>> getUpcomingSchedule({
    CancelToken? cancelToken,
  }) async => const [];

  @override
  Future<SavedCustomerLocation> saveCustomerLocation(
    CustomerLocationCapture capture,
  ) => throw UnimplementedError();

  @override
  Future<DeliveryModel?> startLoading(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> startOffloading(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<DeliveryModel?> startTrip(
    String deliveryId, {
    String? vehicleId,
  }) async => null;

  @override
  Future<void> submitDriverLocation(DriverLocationReading reading) async {}

  @override
  Future<DeliveryModel?> updateStatus(
    String deliveryId,
    DeliveryStatusUpdate status, {
    String? vehicleId,
  }) async => null;
}

class _StatusStore implements DeliveryStatusQueueStore {
  final jobs = <PendingDeliveryStatus>[];

  @override
  Future<List<PendingDeliveryStatus>> load() async => List.of(jobs);

  @override
  Future<void> add(PendingDeliveryStatus job) async {
    jobs.add(job);
  }

  @override
  Future<void> remove(PendingDeliveryStatus job) async {
    jobs.removeWhere((pending) => pending.id == job.id);
  }
}
