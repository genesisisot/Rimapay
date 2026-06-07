import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'notification_dtos.dart';

/// Dio client for the RIMA Notification API (`/api/v1/notification/*`).
class NotificationApiService {
  NotificationApiService({Dio? dio})
      : _dio = dio ?? DioClient.instance.forBaseUrl(ApiConfig.otpBaseUrl);

  final Dio _dio;

  /// POST /api/v1/notification/sms
  Future<ApiResponse<SendSmsResponse>> sendSms(SendSmsRequest request) {
    return _postSms('/api/v1/notification/sms', request.toJson());
  }

  /// POST /api/v1/notification/push
  Future<ApiResponse<SendPushNotificationResponse>> sendPush(
      SendPushNotificationRequest request) {
    return _postPush('/api/v1/notification/push', request.toJson());
  }

  /// POST /api/v1/notification/push/device/register
  Future<ApiResponse<void>> registerDevice({
    required String userId,
    required DeviceTokenDto deviceToken,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/notification/push/device/register',
        queryParameters: {'userId': userId},
        data: deviceToken.toJson(),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<void>.fromJson(data);
      }
      final ok =
          (res.statusCode ?? 500) >= 200 && (res.statusCode ?? 500) < 300;
      return ApiResponse<void>(
        isSuccess: ok,
        statusCode: res.statusCode?.toString(),
        message: ok ? null : 'Request failed (${res.statusCode}).',
      );
    } on DioException catch (e) {
      return ApiResponse<void>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<void>.failure('Unexpected error: $e');
    }
  }

  /// DELETE /api/v1/notification/push/device/unregister
  Future<ApiResponse<void>> unregisterDevice({
    required String userId,
    required String token,
  }) async {
    try {
      final res = await _dio.delete(
        '/api/v1/notification/push/device/unregister',
        queryParameters: {'userId': userId, 'token': token},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<void>.fromJson(data);
      }
      final ok =
          (res.statusCode ?? 500) >= 200 && (res.statusCode ?? 500) < 300;
      return ApiResponse<void>(
        isSuccess: ok,
        statusCode: res.statusCode?.toString(),
        message: ok ? null : 'Request failed (${res.statusCode}).',
      );
    } on DioException catch (e) {
      return ApiResponse<void>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<void>.failure('Unexpected error: $e');
    }
  }

  /// GET /api/v1/notification/push/device/{userId}
  Future<ApiResponse<List<DeviceTokenDto>>> getUserDevices(
      String userId) async {
    try {
      final res = await _dio.get('/api/v1/notification/push/device/$userId');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<List<DeviceTokenDto>>.fromJson(
          data,
          fromData: (d) => (d as List)
              .map((e) =>
                  DeviceTokenDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      return ApiResponse<List<DeviceTokenDto>>.failure(
          'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<List<DeviceTokenDto>>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<List<DeviceTokenDto>>.failure(
          'Unexpected error: $e');
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<ApiResponse<SendSmsResponse>> _postSms(
    String path,
    Object? body,
  ) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<SendSmsResponse>.fromJson(
          data,
          fromData: (d) =>
              SendSmsResponse.fromJson(d as Map<String, dynamic>),
        );
      }
      return ApiResponse<SendSmsResponse>.failure(
          'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<SendSmsResponse>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<SendSmsResponse>.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<SendPushNotificationResponse>> _postPush(
    String path,
    Object? body,
  ) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<SendPushNotificationResponse>.fromJson(
          data,
          fromData: (d) => SendPushNotificationResponse.fromJson(
              d as Map<String, dynamic>),
        );
      }
      return ApiResponse<SendPushNotificationResponse>.failure(
          'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<SendPushNotificationResponse>.failure(
          _dioMessage(e));
    } catch (e) {
      return ApiResponse<SendPushNotificationResponse>.failure(
          'Unexpected error: $e');
    }
  }

  String _dioMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Network error. Please check your internet connection.';
    }
    return e.message ?? 'Network request failed.';
  }
}
