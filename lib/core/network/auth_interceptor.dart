import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService =
      SecureStorageService();

  // Global authentication-expired signal.
  static final ValueNotifier<bool> authExpired =
      ValueNotifier<bool>(false);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token =
        await _storageService.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] =
          'Bearer $token';
    }

    options.headers['Content-Type'] =
        'application/json';

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode =
        err.response?.statusCode;

    if (statusCode == 401 || statusCode == 403) {
      debugPrint(
        'Authentication failed with status $statusCode',
      );

      await _storageService.clearAll();

      // Tell the application that the session
      // is no longer valid.
      if (!authExpired.value) {
        authExpired.value = true;
      }
    }

    handler.next(err);
  }
}