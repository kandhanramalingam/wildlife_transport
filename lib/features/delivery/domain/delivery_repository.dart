import 'package:dio/dio.dart';

import '../models/delivery_model.dart';

abstract interface class DeliveryRepository {
  Future<List<DeliveryModel>> getTodaySchedule({CancelToken? cancelToken});
  Future<List<DeliveryModel>> getUpcomingSchedule({CancelToken? cancelToken});
}
