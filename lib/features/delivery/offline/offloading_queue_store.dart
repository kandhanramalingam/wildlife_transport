import '../models/start_delivery_submission.dart';

class PendingOffloadingJob {
  final String id;
  final String deliveryId;
  final String? vehicleId;
  final DateTime queuedAt;
  final CompleteOffloadingSubmission submission;

  const PendingOffloadingJob({
    required this.id,
    required this.deliveryId,
    required this.vehicleId,
    required this.queuedAt,
    required this.submission,
  });
}

abstract interface class OffloadingQueueStore {
  Future<List<PendingOffloadingJob>> load();

  Future<PendingOffloadingJob> enqueue({
    required String deliveryId,
    required String? vehicleId,
    required CompleteOffloadingSubmission submission,
  });

  Future<void> remove(PendingOffloadingJob job);
}
