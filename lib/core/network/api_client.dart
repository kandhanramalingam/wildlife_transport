import 'dart:convert';

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
    debugPrint('    Request headers: ${_formatLogValue(options.headers)}');
    debugPrint('    Request body: ${_formatLogValue(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '<-- ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri}',
    );
    debugPrint(
      '    Response headers: ${_formatLogValue(response.headers.map)}',
    );
    debugPrint('    Response body: ${_formatLogValue(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    debugPrint(
      '<-- ${error.response?.statusCode ?? 'ERROR'} '
      '${error.requestOptions.method} ${error.requestOptions.uri}',
    );
    final response = error.response;
    if (response != null) {
      debugPrint(
        '    Response headers: ${_formatLogValue(response.headers.map)}',
      );
      debugPrint('    Response body: ${_formatLogValue(response.data)}');
    }
    debugPrint('    Dio error: ${error.message}');
    handler.next(error);
  }

  String _formatLogValue(Object? value) {
    if (value == null) return '<empty>';
    final safeValue = _makeLogSafe(value);
    try {
      return const JsonEncoder.withIndent('  ').convert(safeValue);
    } catch (_) {
      return safeValue.toString();
    }
  }

  Object? _makeLogSafe(Object? value, {String? fieldName}) {
    if (_isSensitiveField(fieldName)) return '<redacted>';
    if (value is FormData) {
      return {
        'fields': [
          for (final field in value.fields)
            {field.key: _makeLogSafe(field.value, fieldName: field.key)},
        ],
        'files': [
          for (final file in value.files)
            {
              'field': file.key,
              'filename': file.value.filename,
              'contentType': file.value.contentType?.toString(),
              'length': file.value.length,
            },
        ],
      };
    }
    if (value is MultipartFile) {
      return {
        'filename': value.filename,
        'contentType': value.contentType?.toString(),
        'length': value.length,
      };
    }
    if (value is Uint8List) return '<${value.length} bytes>';
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          _makeLogSafe(item, fieldName: key.toString()),
        ),
      );
    }
    if (value is List<int> && value.length > 100) {
      return '<${value.length} bytes>';
    }
    if (value is Iterable) {
      return value.map((item) => _makeLogSafe(item)).toList(growable: false);
    }
    return value;
  }

  bool _isSensitiveField(String? name) {
    final normalized = name?.toLowerCase().replaceAll(RegExp(r'[-_]'), '');
    return normalized == 'authorization' ||
        normalized == 'cookie' ||
        normalized == 'setcookie' ||
        normalized == 'password' ||
        normalized == 'accesstoken' ||
        normalized == 'refreshtoken' ||
        normalized == 'apikey' ||
        normalized == 'xapikey';
  }
}
