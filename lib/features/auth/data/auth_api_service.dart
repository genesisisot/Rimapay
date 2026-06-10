import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'auth_dtos.dart';

/// Thin client over the RIMA Identity API `/api/auth/*` endpoints.
/// Every method returns an [ApiResponse], never throws for HTTP/parse errors.
class AuthApiService {
  AuthApiService({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  /// POST /api/auth/create-user
  Future<ApiResponse<AuthResponse>> register(RegisterRequest request) {
    return _postAuth('/api/auth/create-user', request.toJson());
  }

  /// POST /api/auth/login
  Future<ApiResponse<AuthResponse>> login(LoginRequest request) {
    return _postAuth('/api/auth/login', request.toJson());
  }

  /// POST /api/auth/refresh-token
  Future<ApiResponse<AuthResponse>> refreshToken({
    required String accessToken,
    required String refreshToken,
  }) {
    return _postAuth('/api/auth/refresh-token', {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    });
  }

  /// POST /api/auth/change-password (requires auth)
  Future<ApiResponse<void>> changePassword(ChangePasswordRequest request) {
    return _postVoid('/api/auth/change-password', request.toJson());
  }

  /// POST /api/auth/forgot-password
  Future<ApiResponse<void>> forgotPassword(String email) {
    return _postVoid('/api/auth/forgot-password', {'email': email});
  }

  /// POST /api/auth/reset-password
  Future<ApiResponse<void>> resetPassword(ResetPasswordRequest request) {
    return _postVoid('/api/auth/reset-password', request.toJson());
  }

  /// GET /api/auth/verify-email?token=&email=
  Future<ApiResponse<void>> verifyEmail({
    required String token,
    required String email,
  }) async {
    try {
      final res = await _dio.get(
        '/api/auth/verify-email',
        queryParameters: {'token': token, 'email': email},
      );
      return _parseVoid(res);
    } on DioException catch (e) {
      return ApiResponse<void>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<void>.failure('Unexpected error: $e');
    }
  }

  /// POST /api/auth/logout (requires auth)
  Future<ApiResponse<void>> logout() {
    return _postVoid('/api/auth/logout', null);
  }

  /// DELETE /api/auth/delete-account
  Future<ApiResponse<void>> deleteAccount() async {
    try {
      final res = await _dio.delete('/api/auth/delete-account');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<void>.fromJson(data);
      }
      return ApiResponse<void>(
        isSuccess: (res.statusCode ?? 500) >= 200 && (res.statusCode ?? 500) < 300,
        statusCode: res.statusCode?.toString(),
        message: 'Request failed (${res.statusCode}).',
      );
    } on DioException catch (e) {
      return ApiResponse<void>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<void>.failure('Unexpected error: $e');
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<ApiResponse<AuthResponse>> _postAuth(
    String path,
    Object? body,
  ) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<AuthResponse>.fromJson(
          data,
          fromData: (d) => AuthResponse.fromJson(d as Map<String, dynamic>),
        );
      }
      return ApiResponse<AuthResponse>.failure(
          'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<AuthResponse>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<AuthResponse>.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<void>> _postVoid(String path, Object? body) async {
    try {
      final res = await _dio.post(path, data: body);
      return _parseVoid(res);
    } on DioException catch (e) {
      return ApiResponse<void>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<void>.failure('Unexpected error: $e');
    }
  }

  ApiResponse<void> _parseVoid(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ApiResponse<void>.fromJson(data);
    }
    // Some endpoints (e.g. verify-email) may return an empty 200 body.
    final ok = (res.statusCode ?? 500) >= 200 && (res.statusCode ?? 500) < 300;
    return ApiResponse<void>(
      isSuccess: ok,
      statusCode: res.statusCode?.toString(),
      message: ok ? null : 'Request failed (${res.statusCode}).',
    );
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
