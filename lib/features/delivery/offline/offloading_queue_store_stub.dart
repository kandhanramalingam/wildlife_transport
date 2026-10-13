import 'offloading_queue_store.dart';
import '../models/start_delivery_submission.dart';

OffloadingQueueStore createOffloadingQueueStore() =>
    _MemoryOffloadingQueueStore();

class _MemoryOffloadingQueueStore implements OffloadingQueueStore {
  final List<PendingOffloadingJob> _jobs = [];

  @override
  Future<List<PendingOffloadingJob>> load() async => List.unmodifiable(_jobs);

  @override
  Future<PendingOffloadingJob> enqueue({
    required String deliveryId,
    required String? vehicleId,
    required CompleteOffloadingSubmission submission,
  }) async {
    final job = PendingOffloadingJob(
      id: '${deliveryId}_${DateTime.now().microsecondsSinceEpoch}',
      deliveryId: deliveryId,
      vehicleId: vehicleId,
      queuedAt: DateTime.now().toUtc(),
      submission: submission,
    );
    _jobs.add(job);
    return job;
  }

  @override
  Future<void> remove(PendingOffloadingJob job) async => _jobs.remove(job);
}
