import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../domain/delivery_repository.dart';
import '../models/delivery_model.dart';

class UpcomingDeliveriesController extends ChangeNotifier {
  final DeliveryRepository _repository;
  CancelToken? _cancelToken;

  bool isLoading = false;
  bool requiresLogin = false;
  String? errorMessage;
  List<DeliveryModel> deliveries = const [];

  UpcomingDeliveriesController(this._repository);

  Future<void> load() async {
    _cancelToken?.cancel('Schedule refreshed');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    isLoading = true;
    requiresLogin = false;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getUpcomingSchedule(
        cancelToken: cancelToken,
      );
      if (_cancelToken != cancelToken) return;
      deliveries = result;
    } on UnauthorizedFailure catch (failure) {
      if (_cancelToken != cancelToken) return;
      requiresLogin = true;
      errorMessage = failure.message;
    } on Failure catch (failure) {
      if (_cancelToken != cancelToken) return;
      errorMessage = failure.message;
    } finally {
      if (_cancelToken == cancelToken) {
        isLoading = false;
        _cancelToken = null;
        notifyListeners();
      }
    }
  }

  void markTripStarted(String deliveryId) {
    _updateStatus(deliveryId, DeliveryStatus.inProgress);
  }

  void markLotLoadingStarted(String deliveryId, String lotDeliveryId) {
    _updateLotStatus(deliveryId, lotDeliveryId, DeliveryStatus.loading);
  }

  void markLotLoaded(
    String deliveryId,
    String lotDeliveryId, {
    required int loadingOrder,
  }) {
    final index = deliveries.indexWhere((item) => item.id == deliveryId);
    if (index == -1) return;

    final updated = List<DeliveryModel>.of(deliveries);
    final delivery = updated[index];
    updated[index] = delivery.copyWith(
      lots: delivery.lots
          .map(
            (lot) => lot.deliveryId == lotDeliveryId
                ? lot.copyWith(
                    status: DeliveryStatus.loadingCompleted,
                    loadingOrder: loadingOrder,
                  )
                : lot,
          )
          .toList(growable: false),
    );
    deliveries = List.unmodifiable(updated);
    notifyListeners();
  }

  void _updateLotStatus(
    String deliveryId,
    String lotDeliveryId,
    DeliveryStatus status,
  ) {
    final index = deliveries.indexWhere((item) => item.id == deliveryId);
    if (index == -1) return;

    final updated = List<DeliveryModel>.of(deliveries);
    final delivery = updated[index];
    updated[index] = delivery.copyWith(
      lots: delivery.lots
          .map(
            (lot) => lot.deliveryId == lotDeliveryId
                ? lot.copyWith(status: status)
                : lot,
          )
          .toList(growable: false),
    );
    deliveries = List.unmodifiable(updated);
    notifyListeners();
  }

  void markDeliveryCompleted(String deliveryId) {
    _updateStatus(deliveryId, DeliveryStatus.completed);
  }

  void updateLots(String deliveryId, List<DeliveryLot> lots) {
    final index = deliveries.indexWhere((item) => item.id == deliveryId);
    if (index == -1) return;

    final updated = List<DeliveryModel>.of(deliveries);
    updated[index] = updated[index].copyWith(lots: List.unmodifiable(lots));
    deliveries = List.unmodifiable(updated);
    notifyListeners();
  }

  void reorderLots(String deliveryId, int oldIndex, int newIndex) {
    final index = deliveries.indexWhere((item) => item.id == deliveryId);
    if (index == -1) return;

    final delivery = deliveries[index];
    if (oldIndex < 0 ||
        oldIndex >= delivery.lots.length ||
        newIndex < 0 ||
        newIndex >= delivery.lots.length ||
        delivery.lots.any((lot) => lot.status != DeliveryStatus.pending)) {
      return;
    }

    final lots = List<DeliveryLot>.of(delivery.lots);
    final lot = lots.removeAt(oldIndex);
    lots.insert(newIndex, lot);
    updateLots(deliveryId, lots);
  }

  void applyDeliveryUpdate(DeliveryModel updated) {
    final index = deliveries.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;

    final list = List<DeliveryModel>.of(deliveries);
    list[index] = updated;
    deliveries = List.unmodifiable(list);
    notifyListeners();
  }

  void updateDeliveryStatusAndPartial({
    required String deliveryId,
    required DeliveryStatus status,
    bool? partialDelivery,
    int? balanceLots,
    int? deliveredLots,
    int? totalLots,
    List<String>? balanceLotNumbers,
  }) {
    final index = deliveries.indexWhere((item) => item.id == deliveryId);
    if (index == -1) return;

    final list = List<DeliveryModel>.of(deliveries);
    final delivery = list[index];
    list[index] = delivery.copyWith(
      status: status,
      partialDelivery: partialDelivery,
      balanceLots: balanceLots,
      deliveredLots: deliveredLots,
      totalLots: totalLots,
      balanceLotNumbers: balanceLotNumbers,
    );
    deliveries = List.unmodifiable(list);
    notifyListeners();
  }

  void _updateStatus(String deliveryId, DeliveryStatus status) {
    final index = deliveries.indexWhere(
      (delivery) => delivery.id == deliveryId,
    );
    if (index == -1) return;
    final updated = List<DeliveryModel>.of(deliveries);
    updated[index] = updated[index].copyWith(status: status);
    deliveries = List.unmodifiable(updated);
    notifyListeners();
  }

  @override
  void dispose() {
    final cancelToken = _cancelToken;
    _cancelToken = null;
    cancelToken?.cancel('Upcoming deliveries disposed');
    super.dispose();
  }
}
