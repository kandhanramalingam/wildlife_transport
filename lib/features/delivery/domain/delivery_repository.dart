import 'package:dio/dio.dart';

import '../models/delivery_model.dart';
import '../models/start_delivery_submission.dart';

abstract interface class DeliveryRepository {
  Future<List<DeliveryModel>> getTodaySchedule({CancelToken? cancelToken});
  Future<List<DeliveryModel>> getUpcomingSchedule({CancelToken? cancelToken});
  Future<void> startLoading(String deliveryId);
  Future<void> completeLoading(
    String deliveryId,
    StartDeliverySubmission submission,
  );
  Future<void> startTrip(
    String deliveryId, {
    required String latitude,
    required String longitude,
  });
  Future<void> startOffloading(String deliveryId);
  Future<void> completeOffloading(
    String deliveryId,
    CompleteOffloadingSubmission submission,
  );
}
