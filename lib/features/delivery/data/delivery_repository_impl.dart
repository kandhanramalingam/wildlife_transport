import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/dio_failure_mapper.dart';
import '../domain/delivery_repository.dart';
import '../models/delivery_model.dart';
import '../models/start_delivery_submission.dart';
import 'delivery_remote_data_source.dart';
import 'delivery_schedule_dto.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  final DeliveryRemoteDataSource _remoteDataSource;

  const DeliveryRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<DeliveryModel>> getTodaySchedule({CancelToken? cancelToken}) =>
      _getSchedule(
        () => _remoteDataSource.getTodaySchedule(cancelToken: cancelToken),
      );

  @override
  Future<List<DeliveryModel>> getUpcomingSchedule({CancelToken? cancelToken}) =>
      _getSchedule(
        () => _remoteDataSource.getUpcomingSchedule(cancelToken: cancelToken),
      );

  @override
  Future<void> startDelivery(
    String deliveryId,
    StartDeliverySubmission submission,
  ) async {
    try {
      final vehiclePhotos = await Future.wait(
        submission.startVehiclePhotos.map(
          (photo) async => _remoteDataSource.uploadImage(
            await photo.readAsBytes(),
            photo.name,
          ),
        ),
      );
      final animalPhotos = await Future.wait(
        submission.startAnimalPhotos.map(
          (photo) async => _remoteDataSource.uploadImage(
            await photo.readAsBytes(),
            photo.name,
          ),
        ),
      );
      final uploaded = await Future.wait([
        _remoteDataSource.uploadVideo(
          await submission.onLoadAnimalsVideo.readAsBytes(),
          submission.onLoadAnimalsVideo.name,
        ),
        _remoteDataSource.uploadImage(
          submission.managerSignature,
          'manager-signature.png',
        ),
        _remoteDataSource.uploadImage(
          submission.otherSignature,
          'other-signature.png',
        ),
      ]);

      final request = StartDeliveryRequest(
        startOdometerReading: submission.startOdometerReading,
        startVehiclePhotos: vehiclePhotos,
        startAnimalPhotos: animalPhotos,
        onLoadAnimalsVideo: uploaded[0],
        startLatitude: submission.startLatitude,
        startLongitude: submission.startLongitude,
        vehicleChecklist: submission.vehicleChecklist,
        gameLoadingChecklist: submission.gameLoadingChecklist,
        managerSignature: uploaded[1],
        otherSignature: uploaded[2],
      );
      await _remoteDataSource.startDelivery(deliveryId, request.toJson());
    } on DioException catch (exception) {
      throw mapDioException(exception);
    } on Failure {
      rethrow;
    } on FormatException catch (exception) {
      throw UnknownFailure(exception.message);
    } on TypeError {
      throw const UnknownFailure('Invalid response from server');
    }
  }

  Future<List<DeliveryModel>> _getSchedule(
    Future<List<DeliveryScheduleDto>> Function() request,
  ) async {
    try {
      final items = await request();
      return items
          .map(
            (dto) => DeliveryModel(
              id: dto.id,
              buyerId: dto.buyerId,
              auctionId: dto.auctionId,
              dateTime: dto.scheduleDate.toLocal(),
              clientName: dto.buyerName,
              clientAddress: dto.address,
              status: DeliveryStatus.fromApi(dto.deliveryStatus),
              paymentStatus: dto.paymentStatus,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw mapDioException(exception);
    } on Failure {
      rethrow;
    } on FormatException {
      throw const UnknownFailure('Invalid schedule response from server');
    } on TypeError {
      throw const UnknownFailure('Invalid schedule response from server');
    }
  }
}
