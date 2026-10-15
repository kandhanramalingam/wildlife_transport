import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/dio_failure_mapper.dart';
import '../domain/delivery_repository.dart';
import '../models/delivery_model.dart';
import '../models/location_tracking.dart';
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
  Future<DeliveryModel?> updateStatus(
    String deliveryId,
    DeliveryStatusUpdate status, {
    String? vehicleId,
  }) => _runModelAction(
    () => _remoteDataSource.updateStatus(
      deliveryId,
      status,
      vehicleId: vehicleId,
    ),
    fallbackMessage: 'Could not update delivery status',
  );

  @override
  Future<DeliveryModel?> startLoading(String deliveryId, {String? vehicleId}) =>
      updateStatus(
        deliveryId,
        DeliveryStatusUpdate.loadingInProgress,
        vehicleId: vehicleId,
      );

  Future<DeliveryModel?> replayStatus(
    String deliveryId,
    DeliveryStatusUpdate status, {
    String? vehicleId,
  }) => _runModelAction(
    () => _remoteDataSource.updateStatus(
      deliveryId,
      status,
      vehicleId: vehicleId,
      offlineReplay: true,
    ),
    fallbackMessage: 'Could not sync delivery status',
  );

  @override
  Future<DeliveryModel?> completeLoading(
    String deliveryId,
    StartDeliverySubmission submission, {
    String? vehicleId,
  }) async {
    try {
      final vehiclePhotos = await Future.wait(
        submission.startVehiclePhotos.map(
          (photo) async => _remoteDataSource.uploadImage(
            await photo.photo.readAsBytes(),
            photo.photo.name,
          ),
        ),
      );
      final animalPhotos = await Future.wait(
        submission.startAnimalPhotos.map(
          (photo) async => _remoteDataSource.uploadImage(
            await photo.photo.readAsBytes(),
            photo.photo.name,
          ),
        ),
      );
      final animalVideos = await Future.wait(
        submission.onLoadAnimalsVideos.map(
          (video) async => _remoteDataSource.uploadVideo(
            await video.photo.readAsBytes(),
            video.photo.name,
          ),
        ),
      );
      final uploadedSignatures = await Future.wait([
        _remoteDataSource.uploadImage(
          submission.managerSignature,
          'manager-signature.png',
        ),
        _remoteDataSource.uploadImage(
          submission.otherSignature,
          'other-signature.png',
        ),
      ]);

      final nowUtcIso = DateTime.now().toUtc().toIso8601String();
      final lat = double.tryParse(submission.startLatitude) ?? 0.0;
      final lng = double.tryParse(submission.startLongitude) ?? 0.0;

      final request = StartDeliveryRequest(
        startMediaMetadata: [
          for (var i = 0; i < vehiclePhotos.length; i++)
            submission.startVehiclePhotos[i].uploadedMetadata(
              vehiclePhotos[i],
              'vehicle_photo',
            ),
          for (var i = 0; i < animalPhotos.length; i++)
            submission.startAnimalPhotos[i].uploadedMetadata(
              animalPhotos[i],
              'animal_photo',
            ),
          for (var i = 0; i < animalVideos.length; i++)
            submission.onLoadAnimalsVideos[i].uploadedMetadata(
              animalVideos[i],
              'animal_video',
            ),
        ],
        startOdometerReading: submission.startOdometerReading,
        startVehiclePhotos: vehiclePhotos,
        startAnimalPhotos: animalPhotos,
        onLoadAnimalsVideo: animalVideos.first,
        onLoadAnimalsVideos: animalVideos,
        startLatitude: submission.startLatitude,
        startLongitude: submission.startLongitude,
        vehicleChecklist: submission.vehicleChecklist,
        gameLoadingChecklist: submission.gameLoadingChecklist,
        managerSignature: uploadedSignatures[0],
        managerSignatureMetadata: {
          'capturedAt': nowUtcIso,
          'latitude': lat,
          'longitude': lng,
        },
        otherSignature: uploadedSignatures[1],
        otherSignatureMetadata: {
          'capturedAt': nowUtcIso,
          'latitude': lat,
          'longitude': lng,
        },
      );
      final startDto = await _remoteDataSource.startDelivery(
        deliveryId,
        request.toJson(),
      );
      final statusDto = await _remoteDataSource.updateStatus(
        deliveryId,
        DeliveryStatusUpdate.loadingCompleted,
        vehicleId: vehicleId,
      );
      final updated = _deliveryModelFromDto(statusDto ?? startDto);
      // A status acknowledgement may omit evidence; the uploaded paths are authoritative.
      return updated?.copyWith(
        startVehiclePhotos: vehiclePhotos,
        startAnimalPhotos: animalPhotos,
        onLoadAnimalsVideo: animalVideos.first,
        onLoadAnimalsVideos: animalVideos,
        startMediaMetadata: request.startMediaMetadata
            .map(
              (media) => DeliveryLoadingMedia(
                filePath: media['filePath'] as String,
                kind: media['kind'] as String,
                lotNumber: media['lotNumber'] as String?,
              ),
            )
            .toList(),
      );
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
  Future<DeliveryModel?> startTrip(String deliveryId, {String? vehicleId}) =>
      updateStatus(
        deliveryId,
        DeliveryStatusUpdate.inDelivery,
        vehicleId: vehicleId,
      );

  @override
  Future<DeliveryModel?> atDeliveryLocation(
    String deliveryId, {
    String? vehicleId,
  }) => updateStatus(
    deliveryId,
    DeliveryStatusUpdate.arrivedAtLocation,
    vehicleId: vehicleId,
  );

  @override
  Future<DeliveryModel?> startOffloading(
    String deliveryId, {
    String? vehicleId,
  }) => updateStatus(
    deliveryId,
    DeliveryStatusUpdate.offloadingStarted,
    vehicleId: vehicleId,
  );

  @override
  Future<DeliveryModel?> completeOffloading(
    String deliveryId,
    CompleteOffloadingSubmission submission, {
    String? vehicleId,
  }) async {
    try {
      final animalPhotos = await Future.wait(
        submission.endAnimalPhotos.map(
          (photo) async => _remoteDataSource.uploadImage(
            await photo.photo.readAsBytes(),
            photo.photo.name,
          ),
        ),
      );
      final uploaded = await Future.wait([
        _remoteDataSource.uploadVideo(
          await submission.endAnimalVideos.photo.readAsBytes(),
          submission.endAnimalVideos.photo.name,
        ),
        _remoteDataSource.uploadImage(
          submission.clientSignature,
          'client-signature.png',
        ),
      ]);
      final request = CompleteOffloadingRequest(
        endMediaMetadata: [
          for (var i = 0; i < animalPhotos.length; i++)
            submission.endAnimalPhotos[i].uploadedMetadata(
              animalPhotos[i],
              'animal_photo',
            ),
          submission.endAnimalVideos.uploadedMetadata(
            uploaded[0],
            'animal_video',
          ),
        ],
        endAnimalPhotos: animalPhotos,
        endAnimalVideos: uploaded[0],
        offLoadChecklist: submission.offLoadChecklist,
        clientSignature: uploaded[1],
        endOdometerReading: submission.endOdometerReading,
        buyerId: submission.buyerId,
        clientComment: submission.clientComment,
      );
      final endDto = await _remoteDataSource.completeOffloading(
        deliveryId,
        request.toJson(),
      );
      // The completion endpoint is authoritative. A null DTO still means the
      // mutation succeeded but an older response shape could not be parsed.
      return _deliveryModelFromDto(endDto);
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
  Future<void> submitDriverLocation(DriverLocationReading reading) =>
      _runAction(
        () => _remoteDataSource.submitDriverLocation(reading),
        fallbackMessage: 'Could not update driver location',
      );

  @override
  Future<SavedCustomerLocation> saveCustomerLocation(
    CustomerLocationCapture capture,
  ) async {
    try {
      final json = await _remoteDataSource.saveCustomerLocation(capture);
      return SavedCustomerLocation.fromJson(json);
    } on DioException catch (exception) {
      throw mapDioException(exception);
    } on Failure {
      rethrow;
    } on FormatException catch (exception) {
      throw UnknownFailure(exception.message);
    } on TypeError {
      throw const UnknownFailure('Invalid customer location response');
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

  Future<DeliveryModel?> _runModelAction(
    Future<DeliveryScheduleDto?> Function() action, {
    required String fallbackMessage,
  }) async {
    try {
      final dto = await action();
      return _deliveryModelFromDto(dto);
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
          .map(_deliveryModelFromDto)
          .whereType<DeliveryModel>()
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

  DeliveryModel? _deliveryModelFromDto(DeliveryScheduleDto? dto) {
    if (dto == null) return null;
    return DeliveryModel(
      id: dto.id,
      buyerId: dto.buyerId,
      auctionId: dto.auctionId,
      dateTime: dto.scheduleDate.toLocal(),
      clientName: dto.buyerName,
      clientAddress: dto.address,
      status: DeliveryStatus.fromApi(dto.deliveryStatus),
      paymentStatus: dto.paymentStatus,
      invoicePath: dto.invoicePath,
      assignment: _assignmentFromDto(dto.assignment),
      multiPickupPointJob: dto.multiPickupPointJob,
      multiplePickupPoint: dto.multiplePickupPoint,
      pickupNotice: dto.pickupNotice,
      pickupStops: dto.pickupStops
          .map(
            (s) => PickupStop(
              order: s.order,
              address: s.address,
              lotNumbers: s.lotNumbers,
            ),
          )
          .toList(growable: false),
      vehicleLotTotal: dto.vehicleLotTotal,
      totalLots: dto.totalLots,
      assignedLots: dto.assignedLots,
      deliveredLots: dto.deliveredLots,
      balanceLots: dto.balanceLots,
      balanceLotNumbers: dto.balanceLotNumbers,
      partialDelivery: dto.partialDelivery,
      permits: dto.permits,
      maps: dto.maps,
      lotDetails: dto.lotDetails
          .map(
            (lot) => DeliveryLotDetails(
              lotNumber: lot.lotNumber,
              description: lot.description,
              quantity: lot.quantity,
              status: lot.status,
              comment: lot.comment,
            ),
          )
          .toList(growable: false),
      assignments: dto.assignments
          .map(_assignmentFromDto)
          .whereType<DeliveryAssignment>()
          .toList(growable: false),
      startVehiclePhotos: dto.startVehiclePhotos,
      startAnimalPhotos: dto.startAnimalPhotos,
      onLoadAnimalsVideo: dto.onLoadAnimalsVideo,
      onLoadAnimalsVideos: dto.onLoadAnimalsVideos,
      startMediaMetadata: dto.startMediaMetadata
          .map(
            (media) => DeliveryLoadingMedia(
              filePath: media.filePath,
              kind: media.kind,
              lotNumber: media.lotNumber,
            ),
          )
          .toList(growable: false),
      lots: dto.lots
          .map(
            (lot) => DeliveryLot(
              clientName: lot.buyerName,
              lotNumbers: lot.lotNumbers,
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
              assignment: _assignmentFromDto(lot.assignment),
            ),
          )
          .toList(growable: false),
    );
  }

  DeliveryAssignment? _assignmentFromDto(DeliveryAssignmentDto? dto) {
    if (dto == null) return null;
    return DeliveryAssignment(
      driverId: dto.driverId,
      driverName: dto.driverName,
      vehicleId: dto.vehicleId,
      vehicleRegistrationNumber: dto.vehicleRegistrationNumber,
      vehicleDescription: dto.vehicleDescription,
      status: dto.deliveryStatus == null
          ? null
          : DeliveryStatus.fromApi(dto.deliveryStatus!),
      lotNumbers: dto.lotNumbers,
      loadedLotNumbers: dto.loadedLotNumbers,
      deliveredLotNumbers: dto.deliveredLotNumbers,
    );
  }
}
