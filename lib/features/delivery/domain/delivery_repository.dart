import 'package:dio/dio.dart';

import '../models/delivery_model.dart';
import '../models/location_tracking.dart';
import '../models/start_delivery_submission.dart';

abstract interface class DeliveryRepository {
  Future<List<DeliveryModel>> getTodaySchedule({CancelToken? cancelToken});
  Future<List<DeliveryModel>> getUpcomingSchedule({CancelToken? cancelToken});
  Future<void> updateStatus(
    String deliveryId,
    DeliveryStatusUpdate status, {
    String? vehicleId,
  });
  Future<void> startLoading(String deliveryId, {String? vehicleId});
  Future<void> completeLoading(
    String deliveryId,
    StartDeliverySubmission submission, {
    String? vehicleId,
  });
  Future<void> startTrip(String deliveryId, {String? vehicleId});
  Future<void> atDeliveryLocation(String deliveryId, {String? vehicleId});
  Future<void> startOffloading(String deliveryId, {String? vehicleId});
  Future<void> completeOffloading(
    String deliveryId,
    CompleteOffloadingSubmission submission, {
    String? vehicleId,
  });
  Future<void> submitDriverLocation(DriverLocationReading reading);
  Future<SavedCustomerLocation> saveCustomerLocation(
    CustomerLocationCapture capture,
  );
}
