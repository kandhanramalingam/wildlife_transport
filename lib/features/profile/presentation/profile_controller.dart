import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../domain/profile_repository.dart';
import '../models/driver_profile.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;
  CancelToken? _cancelToken;

  bool isLoading = false;
  bool requiresLogin = false;
  String? errorMessage;
  DriverProfile? profile;

  ProfileController(this._repository);

  Future<void> load() async {
    _cancelToken?.cancel('Profile refreshed');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    isLoading = true;
    requiresLogin = false;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _repository.getProfile(cancelToken: cancelToken);
    } on UnauthorizedFailure catch (failure) {
      requiresLogin = true;
      errorMessage = failure.message;
    } on Failure catch (failure) {
      errorMessage = failure.message;
    } finally {
      if (_cancelToken == cancelToken) {
        isLoading = false;
        _cancelToken = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Profile disposed');
    super.dispose();
  }
}
