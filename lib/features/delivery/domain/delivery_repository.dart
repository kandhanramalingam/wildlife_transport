import 'package:dio/dio.dart';

import '../models/delivery_model.dart';
import '../models/start_delivery_submission.dart';

abstract interface class DeliveryRepository {
  Future<List<DeliveryModel>> getTodaySchedule({CancelToken? cancelToken});
  Future<List<DeliveryModel>> getUpcomingSchedule({CancelToken? cancelToken});
  Future<void> startDelivery(
    String deliveryId,
    StartDeliverySubmission submission,
  );
}
