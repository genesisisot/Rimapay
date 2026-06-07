import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'pin_dtos.dart';

/// Thin client over the RIMA Identity API `/api/security/pin/*` endpoints.
/// All endpoints require an authenticated (Bearer) session.
class PinApiService {
  PinApiService({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  /// POST /api/security/pin/create
  Future<ApiResponse<void>> createPin(CreatePinRequest request) {
    return _postVoid('/api/security/pin/create', request.toJson());
  }

  /// POST /api/security/pin/verify
  Future<ApiResponse<void>> verifyPin(VerifyPinRequest request) {
    return _postVoid('/api/security/pin/verify', request.toJson());
  }

  /// POST /api/security/pin/change/initiate → returns OTP reference in `data`/`message`.
  Future<ApiResponse<Map<String, dynamic>>> initiateChange(
      InitiatePinRequest request) {
    return _postMap('/api/security/pin/change/initiate', request.toJson());
  }

  /// POST /api/security/pin/change/validate
  Future<ApiResponse<void>> validateChange(ValidatePinRequest request) {
    return _postVoid('/api/security/pin/change/validate', request.toJson());
  }

  /// POST /api/security/pin/reset/initiate → returns OTP reference in `data`/`message`.
  Future<ApiResponse<Map<String, dynamic>>> initiateReset(
      InitiatePinRequest request) {
    return _postMap('/api/security/pin/reset/initiate', request.toJson());
  }

  /// POST /api/security/pin/reset/validate
  Future<ApiResponse<void>> validateReset(ValidatePinRequest request) {
    return _postVoid('/api/security/pin/reset/validate', request.toJson());
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<ApiResponse<void>> _postVoid(String path, Object? body) async {
    try {
      final res = await _dio.post(path, data: body);
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

  Future<ApiResponse<Map<String, dynamic>>> _postMap(
      String path, Object? body) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>.fromJson(
          data,
          fromData: (d) =>
              d is Map<String, dynamic> ? d : <String, dynamic>{'value': d},
        );
      }
      return ApiResponse<Map<String, dynamic>>.failure(
          'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<Map<String, dynamic>>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.failure('Unexpected error: $e');
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
