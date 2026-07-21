import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/dio_failure_mapper.dart';
import '../domain/delivery_repository.dart';
import '../models/delivery_model.dart';
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
