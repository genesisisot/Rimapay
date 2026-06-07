import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'onboarding_dtos.dart';

/// Dio client for the RIMA Accounts / Onboarding API (`/api/v1/onboarding/*`).
class OnboardingApiService {
  OnboardingApiService({Dio? dio})
      : _dio = dio ?? DioClient.instance.forBaseUrl(ApiConfig.accountsBaseUrl);

  final Dio _dio;

  /// POST /api/v1/onboarding/initiate
  Future<ApiResponse<InitiateOnboardingResponse>> initiate(
      InitiateOnboardingRequest request) {
    return _post('/api/v1/onboarding/initiate', request.toJson(),
        fromData: (d) => InitiateOnboardingResponse.fromJson(d));
  }

  /// POST /api/v1/onboarding/verify-otp
  Future<ApiResponse<VerifyOnboardingOtpResponse>> verifyOtp(
      VerifyOnboardingOtpRequest request) {
    return _post('/api/v1/onboarding/verify-otp', request.toJson(),
        fromData: (d) => VerifyOnboardingOtpResponse.fromJson(d));
  }

  /// POST /api/v1/onboarding/resend-otp
  Future<ApiResponse<InitiateOnboardingResponse>> resendOtp(
      ResendOnboardingOtpRequest request) {
    return _post('/api/v1/onboarding/resend-otp', request.toJson(),
        fromData: (d) => InitiateOnboardingResponse.fromJson(d));
  }

  /// POST /api/v1/onboarding/submit-identity
  Future<ApiResponse<SubmitIdentityResponse>> submitIdentity(
      SubmitIdentityRequest request) {
    return _post('/api/v1/onboarding/submit-identity', request.toJson(),
        fromData: (d) => SubmitIdentityResponse.fromJson(d));
  }

  /// POST /api/v1/onboarding/validate-face
  Future<ApiResponse<FacialValidationResponse>> validateFace(
      FacialValidationRequest request) {
    return _post('/api/v1/onboarding/validate-face', request.toJson(),
        fromData: (d) => FacialValidationResponse.fromJson(d));
  }

  /// POST /api/v1/onboarding/create-password
  Future<ApiResponse<CreatePasswordResponse>> createPassword(
      CreatePasswordRequest request) {
    return _post('/api/v1/onboarding/create-password', request.toJson(),
        fromData: (d) => CreatePasswordResponse.fromJson(d));
  }

  /// POST /api/v1/onboarding/create-pin
  Future<ApiResponse<CreatePinResponse>> createPin(
      CreatePinRequest request) {
    return _post('/api/v1/onboarding/create-pin', request.toJson(),
        fromData: (d) => CreatePinResponse.fromJson(d));
  }

  /// POST /api/v1/onboarding/check-status
  Future<ApiResponse<OnboardingStatusResponse>> checkStatus(
      CheckOnboardingStatusRequest request) {
    return _post('/api/v1/onboarding/check-status', request.toJson(),
        fromData: (d) => OnboardingStatusResponse.fromJson(d));
  }

  /// POST /api/v1/onboarding/resume
  Future<ApiResponse<ResumeOnboardingResponse>> resume(
      ResumeOnboardingRequest request) {
    return _post('/api/v1/onboarding/resume', request.toJson(),
        fromData: (d) => ResumeOnboardingResponse.fromJson(d));
  }

  /// GET /api/v1/onboarding/session/{sessionId}
  Future<ApiResponse<OnboardingSessionState>> getSession(
      String sessionId) {
    return _get('/api/v1/onboarding/session/$sessionId',
        fromData: (d) => OnboardingSessionState.fromJson(d));
  }

  /// GET /api/v1/accounts/get-all-accounts
  Future<ApiResponse<List<AccountSummary>>> getAllAccounts() {
    return _getList('/api/v1/accounts/get-all-accounts',
        fromData: (d) => AccountSummary.fromJson(d));
  }

  Future<ApiResponse<T>> _post<T>(
    String path,
    Object? body, {
    required T Function(Map<String, dynamic> d) fromData,
  }) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<T>.fromJson(
          data,
          fromData: (d) => fromData(d as Map<String, dynamic>),
        );
      }
      return ApiResponse<T>.failure('Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<T>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<T>.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> _get<T>(
    String path, {
    required T Function(Map<String, dynamic> d) fromData,
  }) async {
    try {
      final res = await _dio.get(path);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<T>.fromJson(
          data,
          fromData: (d) => fromData(d as Map<String, dynamic>),
        );
      }
      return ApiResponse<T>.failure('Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<T>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<T>.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<List<T>>> _getList<T>(
    String path, {
    required T Function(Map<String, dynamic> d) fromData,
  }) async {
    try {
      final res = await _dio.get(path);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<List<T>>.fromJson(
          data,
          fromData: (d) {
            if (d is List) {
              return d
                  .map((e) => fromData(e as Map<String, dynamic>))
                  .toList();
            }
            return <T>[];
          },
        );
      }
      return ApiResponse<List<T>>.failure(
          'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return ApiResponse<List<T>>.failure(_dioMessage(e));
    } catch (e) {
      return ApiResponse<List<T>>.failure('Unexpected error: $e');
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
