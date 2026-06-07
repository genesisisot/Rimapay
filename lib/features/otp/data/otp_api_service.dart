import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'otp_dtos.dart';

/// Dio client for the RIMA OTP API (`/api/v1/otp/*`).
class OtpApiService {
  OtpApiService({Dio? dio})
      : _dio = dio ?? DioClient.instance.forBaseUrl(ApiConfig.otpBaseUrl);

  final Dio _dio;

  /// POST /api/v1/otp/generate
  Future<ApiResponse<GenerateOtpResponse>> generate(
      GenerateOtpRequest request) {
    return _postOtp('/api/v1/otp/generate', request.toJson());
  }

  /// POST /api/v1/otp/verify
  Future<ApiResponse<VerifyOtpResponse>> verify(VerifyOtpRequest request) {
    return _postVerify('/api/v1/otp/verify', request.toJson());
  }

  /// POST /api/v1/otp/resend
  Future<ApiResponse<GenerateOtpResponse>> resend(ResendOtpRequest request) {
    return _postOtp('/api/v1/otp/resend', request.toJson());
  }

  Future<ApiResponse<GenerateOtpResponse>> _postOtp(
    String path,
    Object? body,
  ) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<GenerateOtpResponse>.fromJson(
          data,
          fromData: (d) =>
              GenerateOtpResponse.fromJson(d as Map<String, dynamic>),
        );
      }
      return ApiResponse<GenerateOtpResponse>.failure(
          'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<GenerateOtpResponse>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<GenerateOtpResponse>.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<VerifyOtpResponse>> _postVerify(
    String path,
    Object? body,
  ) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<VerifyOtpResponse>.fromJson(
          data,
          fromData: (d) =>
              VerifyOtpResponse.fromJson(d as Map<String, dynamic>),
        );
      }
      return ApiResponse<VerifyOtpResponse>.failure(
          'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<VerifyOtpResponse>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<VerifyOtpResponse>.failure('Unexpected error: $e');
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
