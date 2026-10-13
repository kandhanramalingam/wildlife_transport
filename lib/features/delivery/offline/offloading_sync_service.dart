import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../core/connectivity/connectivity_monitor.dart';
import '../../../core/error/failure.dart';
import '../domain/delivery_repository.dart';
import '../models/start_delivery_submission.dart';
import '../models/delivery_model.dart';
import 'delivery_status_queue_store.dart';
import 'offloading_queue_store.dart';

enum OffloadingSubmitResult { synced, queued }

class OffloadingSyncService extends ChangeNotifier with WidgetsBindingObserver {
  static const defaultRetryInterval = Duration(minutes: 1);

  final DeliveryRepository Function() _repositoryFactory;
  final OffloadingQueueStore _store;
  final ConnectivityMonitor _connectivity;
  final DeliveryStatusQueueStore? _statusStore;
  final Future<void> Function(PendingDeliveryStatus)? _replayStatus;
  late final Duration _retryInterval;

  StreamSubscription<void>? _connectivitySubscription;
  Timer? _timer;
  bool _started = false;
  Future<void>? _flushFuture;
  bool _retryRequested = false;
  Set<String> _pendingDeliveryIds = const {};
  int _pendingCount = 0;
  Map<String, DeliveryStatus> _pendingStatuses = const {};
  int _statusSequence = 0;
  final _submittingStatusIds = <String>{};
  final _statusFailures = <String, Failure>{};
  bool _isSyncing = false;
  String? _lastError;
  PendingOffloadingJob? _lastFailedJob;
  int _syncRevision = 0;

  OffloadingSyncService(
    this._repositoryFactory,
    this._store,
    this._connectivity, {
    Duration retryInterval = defaultRetryInterval,
    DeliveryStatusQueueStore? statusStore,
    Future<void> Function(PendingDeliveryStatus)? replayStatus,
  }) : _statusStore = statusStore,
       _replayStatus = replayStatus {
    _retryInterval = retryInterval;
    assert((statusStore == null) == (replayStatus == null));
  }

  Set<String> get pendingDeliveryIds => _pendingDeliveryIds;
  int get pendingCount => _pendingCount;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  PendingOffloadingJob? get lastFailedJob => _lastFailedJob;
  int get syncRevision => _syncRevision;
  Map<String, DeliveryStatus> get pendingStatuses => _pendingStatuses;
  bool isPending(String deliveryId) => _pendingDeliveryIds.contains(deliveryId);

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = _connectivity.onConnected.listen(
      (_) => unawaited(flushPending()),
    );
    _timer = Timer.periodic(_retryInterval, (_) {
      // A large video may take longer than the retry interval. Timer ticks
      // must not force endless extra passes while that request is in flight.
      if (_flushFuture == null) unawaited(flushPending());
    });
    try {
      await _refreshPending();
    } catch (_) {
      _lastError = 'Could not read saved off-loading data. Retry now.';
      notifyListeners();
    }
    unawaited(flushPending());
  }

  Future<void> submitStatus({
    required String deliveryId,
    required String? vehicleId,
    required DeliveryStatusUpdate status,
  }) async {
    final store = _statusStore;
    if (store == null) throw StateError('Status queue is not configured');
    final job = PendingDeliveryStatus(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_statusSequence++}',
      deliveryId: deliveryId,
      vehicleId: vehicleId,
      status: status,
    );
    // Arrival and begin offloading are saved even when the form is not finished.
    await store.add(job);
    _submittingStatusIds.add(job.id);
    try {
      await _refreshPending();
      await flushPending();
      final failure = _statusFailures[job.id];
      if (failure != null) throw failure;
    } finally {
      _submittingStatusIds.remove(job.id);
      _statusFailures.remove(job.id);
    }
  }

  Future<OffloadingSubmitResult> submit({
    required String deliveryId,
    required String? vehicleId,
    required CompleteOffloadingSubmission submission,
  }) async {
    // Save evidence before any upload. Timeouts, server errors and app restarts
    // must all leave a durable submission that can be retried.
    final job = await _store.enqueue(
      deliveryId: deliveryId,
      vehicleId: vehicleId,
      submission: submission,
    );
    _lastError = null;
    await _refreshPending();
    // An existing flush may have taken its snapshot before this job was saved.
    final previousFlush = _flushFuture;
    if (previousFlush != null) await previousFlush;
    await flushPending();
    final remaining = await _store.load();
    return remaining.any((pending) => pending.id == job.id)
        ? OffloadingSubmitResult.queued
        : OffloadingSubmitResult.synced;
  }

  Future<void> flushPending() {
    // A reconnect can arrive while an old request is still timing out. Keep
    // that request for another pass rather than losing the reconnect event.
    _retryRequested = true;
    return _flushFuture ??= _runFlush().whenComplete(() => _flushFuture = null);
  }

  Future<void> _runFlush() async {
    do {
      _retryRequested = false;
      try {
        await _refreshPending();
        await _flushPending();
      } catch (_) {
        _lastError =
            'Could not read or sync saved off-loading data. Retry now.';
        notifyListeners();
      }
    } while (_retryRequested);
  }

  Future<void> _flushPending() async {
    if (!await _safeConnectivityCheck()) return;
    _isSyncing = true;
    _lastError = null;
    _lastFailedJob = null;
    notifyListeners();
    try {
      final repository = _repositoryFactory();
      final blockedDeliveries = <String, Failure>{};
      final statuses = await _statusStore?.load() ?? <PendingDeliveryStatus>[];
      for (final job in statuses) {
        final earlierFailure = blockedDeliveries[job.deliveryId];
        if (earlierFailure != null) {
          if (_submittingStatusIds.contains(job.id)) {
            _statusFailures[job.id] = earlierFailure;
          }
          continue;
        }
        try {
          await _replayStatus!(job);
          await _statusStore!.remove(job);
          _syncRevision++;
          await _refreshPending();
        } on NetworkFailure {
          return;
        } on TimeoutFailure {
          return;
        } on UnauthorizedFailure {
          _lastError = 'Sign in again to sync saved off-loading actions.';
          if (_submittingStatusIds.contains(job.id)) {
            _statusFailures[job.id] = const UnauthorizedFailure(
              'Sign in again to sync saved off-loading actions.',
            );
          }
          return;
        } on Failure catch (failure) {
          blockedDeliveries[job.deliveryId] = failure;
          _lastError = failure.message;
          if (_submittingStatusIds.contains(job.id)) {
            _statusFailures[job.id] = failure;
          }
        } catch (_) {
          blockedDeliveries[job.deliveryId] = const UnknownFailure(
            'Could not sync saved off-loading actions.',
          );
          _lastError = 'Could not sync saved off-loading actions.';
        }
      }
      final jobs = await _store.load();
      for (final job in jobs) {
        if (blockedDeliveries.containsKey(job.deliveryId)) continue;
        try {
          await repository.completeOffloading(
            job.deliveryId,
            job.submission,
            vehicleId: job.vehicleId,
          );
          await _store.remove(job);
          _syncRevision++;
          await _refreshPending();
        } on NetworkFailure {
          return;
        } on TimeoutFailure {
          return;
        } on UnauthorizedFailure {
          _lastError = 'Sign in again to sync saved off-loading submissions.';
          notifyListeners();
          return;
        } on DeliveryNotFoundFailure {
          _lastFailedJob = job;
          _lastError =
              'Saved off-loading could not sync: delivery record not found. '
              'Your photos and signature remain saved.';
          notifyListeners();
          continue;
        } on Failure catch (failure) {
          // Retain server-rejected data for inspection/retry; never discard it.
          _lastError = failure.message;
          _lastFailedJob = job;
          notifyListeners();
          // A rejected delivery must not block unrelated queued deliveries.
          continue;
        } catch (_) {
          _lastError = 'Could not sync saved off-loading data.';
          _lastFailedJob = job;
          notifyListeners();
          continue;
        }
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> _safeConnectivityCheck() async {
    try {
      return await _connectivity.isConnected;
    } catch (_) {
      // If radio state cannot be read, let the API request determine reachability.
      return true;
    }
  }

  Future<void> _refreshPending() async {
    final jobs = await _store.load();
    final statuses = await _statusStore?.load() ?? <PendingDeliveryStatus>[];
    final pendingStatuses = <String, DeliveryStatus>{
      for (final job in statuses)
        job.deliveryId: DeliveryStatus.fromApi(job.status.apiValue),
    };
    final updated = Set<String>.unmodifiable(jobs.map((job) => job.deliveryId));
    final count = jobs.length + statuses.length;
    final countChanged = _pendingCount != count;
    if (!countChanged &&
        setEquals(updated, _pendingDeliveryIds) &&
        mapEquals(pendingStatuses, _pendingStatuses)) {
      return;
    }
    _pendingDeliveryIds = updated;
    _pendingStatuses = Map.unmodifiable(pendingStatuses);
    _pendingCount = count;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(flushPending());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
