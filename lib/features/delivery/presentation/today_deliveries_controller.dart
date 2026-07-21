import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../domain/delivery_repository.dart';
import '../models/delivery_model.dart';

class TodayDeliveriesController extends ChangeNotifier {
  final DeliveryRepository _repository;
  CancelToken? _cancelToken;

  bool isLoading = false;
  bool requiresLogin = false;
  String? errorMessage;
  List<DeliveryModel> deliveries = const [];

  TodayDeliveriesController(this._repository);

  Future<void> load() async {
    _cancelToken?.cancel('Schedule refreshed');
    _cancelToken = CancelToken();
    isLoading = true;
    requiresLogin = false;
    errorMessage = null;
    notifyListeners();

    try {
      deliveries = await _repository.getTodaySchedule(
        cancelToken: _cancelToken,
      );
    } on UnauthorizedFailure catch (failure) {
      requiresLogin = true;
      errorMessage = failure.message;
    } on Failure catch (failure) {
      errorMessage = failure.message;
    } finally {
      isLoading = false;
      _cancelToken = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Today deliveries disposed');
    super.dispose();
  }
}
