import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/environment.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final Dio dio;

  ApiClient(TokenStorage tokenStorage)
    : dio = Dio(
        BaseOptions(
          baseUrl: Environment.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(_AccessTokenInterceptor(tokenStorage));
    if (kDebugMode) dio.interceptors.add(_SafeLogInterceptor());
  }
}

class _AccessTokenInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  _AccessTokenInterceptor(this._tokenStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _SafeLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('--> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    debugPrint(
      '<-- ${error.response?.statusCode ?? 'ERROR'} ${error.requestOptions.uri}',
    );
    handler.next(error);
  }
}
