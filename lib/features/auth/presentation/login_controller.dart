import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../domain/auth_repository.dart';
import '../domain/driver.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository _repository;
  CancelToken? _cancelToken;

  bool isLoading = false;
  String? errorMessage;

  LoginController(this._repository);

  Future<LoginResult?> login({
    required String phone,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    _cancelToken = CancelToken();

    try {
      return await _repository.login(
        phone: phone,
        password: password,
        cancelToken: _cancelToken,
      );
    } on Failure catch (failure) {
      errorMessage = failure.message;
      return null;
    } finally {
      isLoading = false;
      _cancelToken = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Login screen disposed');
    super.dispose();
  }
}
