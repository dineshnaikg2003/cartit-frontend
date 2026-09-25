import 'package:dio/dio.dart';

class NetworkErrorHelper {
  static String parseError(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Server connection timed out. Please check your Wi-Fi or mobile data.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to CartIT servers. Please check your network and try again.';
        case DioExceptionType.badResponse:
          if (e.response?.data != null && e.response?.data is Map) {
            return e.response?.data['message'] ??
                e.response?.data['error'] ??
                'Server error (${e.response?.statusCode}). Please try again.';
          }
          return 'Server responded with error ${e.response?.statusCode}.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          if (e.message != null && e.message!.contains('SocketException')) {
            return 'Network unreachable. Please check your connection.';
          }
          return 'Connection error. Please check your network and try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
