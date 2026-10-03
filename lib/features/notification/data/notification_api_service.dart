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

  // ── In-app feed ──────────────────────────────────────────────────────────
  // These are the notifications shown in the app's own list, as opposed to the
  // push/SMS senders above. All are scoped to the caller's Bearer token.

  /// GET /api/v1/notifications/in-app
  Future<ApiResponse<InAppNotificationFeed>> getInAppFeed({
    bool? unreadOnly,
    NotificationCategory? category,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/api/v1/notifications/in-app',
        queryParameters: {
          if (unreadOnly != null) 'unreadOnly': unreadOnly,
          if (category != null) 'category': category.apiName,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<InAppNotificationFeed>.fromJson(
          data,
          fromData: (d) =>
              InAppNotificationFeed.fromJson(d as Map<String, dynamic>),
        );
      }
      return ApiResponse<InAppNotificationFeed>.failure(
          'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<InAppNotificationFeed>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<InAppNotificationFeed>.failure('Unexpected error: $e');
    }
  }

  /// GET /api/v1/notifications/in-app/unread-count — the badge number.
  Future<ApiResponse<int>> getUnreadCount() =>
      _call<int>(() => _dio.get('/api/v1/notifications/in-app/unread-count'),
          (d) => (d as num?)?.toInt() ?? 0);

  /// PATCH /api/v1/notifications/in-app/{id}/read
  Future<ApiResponse<bool>> markRead(String id) => _call<bool>(
      () => _dio.patch('/api/v1/notifications/in-app/$id/read'),
      (d) => d == true);

  /// POST /api/v1/notifications/in-app/read-all
  Future<ApiResponse<bool>> markAllRead() => _call<bool>(
      () => _dio.post('/api/v1/notifications/in-app/read-all'),
      (d) => d == true);

  /// DELETE /api/v1/notifications/in-app/{id} — a soft delete server-side.
  Future<ApiResponse<bool>> deleteNotification(String id) => _call<bool>(
      () => _dio.delete('/api/v1/notifications/in-app/$id'), (d) => d == true);

  /// DELETE /api/v1/notifications/in-app/clear-all
  Future<ApiResponse<bool>> clearAll() => _call<bool>(
      () => _dio.delete('/api/v1/notifications/in-app/clear-all'),
      (d) => d == true);

  /// Shared wrapper for the small scalar-returning calls above.
  Future<ApiResponse<T>> _call<T>(
    Future<Response<dynamic>> Function() send,
    T Function(Object? data) parse,
  ) async {
    try {
      final res = await send();
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<T>.fromJson(data, fromData: parse);
      }
      return ApiResponse<T>.failure('Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<T>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<T>.failure('Unexpected error: $e');
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
