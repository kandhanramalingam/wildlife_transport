import 'package:dio/dio.dart';

import '../models/delivery_model.dart';
import '../models/start_delivery_submission.dart';

abstract interface class DeliveryRepository {
  Future<List<DeliveryModel>> getTodaySchedule({CancelToken? cancelToken});
  Future<List<DeliveryModel>> getUpcomingSchedule({CancelToken? cancelToken});
  Future<void> updateStatus(String deliveryId, DeliveryStatusUpdate status);
  Future<void> startLoading(String deliveryId);
  Future<void> completeLoading(
    String deliveryId,
    StartDeliverySubmission submission,
  );
  Future<void> startTrip(String deliveryId);
  Future<void> atDeliveryLocation(String deliveryId);
  Future<void> startOffloading(String deliveryId);
  Future<void> completeOffloading(
    String deliveryId,
    CompleteOffloadingSubmission submission,
  );
}
