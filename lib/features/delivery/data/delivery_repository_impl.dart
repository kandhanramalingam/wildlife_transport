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
  Future<void> startLoading(String deliveryId) => _runAction(
    () => _remoteDataSource.startLoading(deliveryId),
    fallbackMessage: 'Could not start loading',
  );

  @override
  Future<void> completeLoading(
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
      await _remoteDataSource.completeLoading(deliveryId, request.toJson());
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

  @override
  Future<void> startTrip(
    String deliveryId, {
    required String latitude,
    required String longitude,
  }) => _runAction(
    () => _remoteDataSource.startTrip(
      deliveryId,
      StartTripRequest(
        startLatitude: latitude,
        startLongitude: longitude,
      ).toJson(),
    ),
    fallbackMessage: 'Could not start trip',
  );

  @override
  Future<void> startOffloading(String deliveryId) => _runAction(
    () => _remoteDataSource.startOffloading(deliveryId),
    fallbackMessage: 'Could not start off-loading',
  );

  @override
  Future<void> completeOffloading(
    String deliveryId,
    CompleteOffloadingSubmission submission,
  ) async {
    try {
      final uploaded = await Future.wait([
        _remoteDataSource.uploadVideo(
          await submission.offLoadAnimalsVideo.readAsBytes(),
          submission.offLoadAnimalsVideo.name,
        ),
        _remoteDataSource.uploadImage(
          submission.clientSignature,
          'client-signature.png',
        ),
      ]);
      final request = CompleteOffloadingRequest(
        offLoadAnimalsVideo: uploaded[0],
        offLoadChecklist: submission.offLoadChecklist,
        clientSignature: uploaded[1],
        endOdometerReading: submission.endOdometerReading,
        buyerId: submission.buyerId,
      );
      await _remoteDataSource.completeOffloading(deliveryId, request.toJson());
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

  Future<void> _runAction(
    Future<void> Function() action, {
    required String fallbackMessage,
  }) async {
    try {
      await action();
    } on DioException catch (exception) {
      throw mapDioException(exception);
    } on Failure {
      rethrow;
    } catch (_) {
      throw UnknownFailure(fallbackMessage);
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
              invoicePath: dto.invoicePath,
              lots: dto.lots
                  .map(
                    (lot) => DeliveryLot(
                      clientName: lot.buyerName,
                      buyerId: lot.buyerId,
                      mainBuyer: lot.mainBuyer,
                      deliveryId: lot.deliveryId,
                      address: lot.address,
                      farmName: lot.farmName,
                      companyName: lot.companyName,
                      contactNumber: lot.contactNumber,
                      latitude: lot.latitude,
                      longitude: lot.longitude,
                      invoicePath: lot.invoicePath,
                      loadingOrder: lot.loadingOrder,
                      status: DeliveryStatus.fromApi(lot.deliveryStatus),
                    ),
                  )
                  .toList(growable: false),
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
