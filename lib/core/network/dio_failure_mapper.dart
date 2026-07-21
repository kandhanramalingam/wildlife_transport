import 'package:dio/dio.dart';

import '../error/failure.dart';

Failure mapDioException(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final statusCode = exception.response?.statusCode;
      final message = _responseMessage(exception.response?.data);

      if (statusCode == 401) {
        return UnauthorizedFailure(
          message ?? 'Your session has expired. Please log in again.',
        );
      }
      if (statusCode == 400 || statusCode == 422) {
        return ValidationFailure(
          message ?? 'Please check the submitted details',
        );
      }
      if (statusCode != null && statusCode >= 500) {
        return const ServerFailure();
      }
      return UnknownFailure(message ?? 'Request failed');
    case DioExceptionType.cancel:
      return const UnknownFailure('Request cancelled');
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return const UnknownFailure();
  }
}

String? _responseMessage(Object? data) {
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) return message.join('\n');
  }
  return null;
}
