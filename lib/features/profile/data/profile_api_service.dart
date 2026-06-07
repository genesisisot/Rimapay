import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import 'profile_dtos.dart';

/// Dio client for the RIMA Profile API (`/api/v1/profile/*`).
///
/// Note: The Profile API returns its own response shapes rather than the
/// generic [ApiResponse] envelope used by other RIMA APIs.
class ProfileApiService {
  ProfileApiService({Dio? dio})
      : _dio =
            dio ?? DioClient.instance.forBaseUrl(ApiConfig.profileBaseUrl);

  final Dio _dio;

  /// POST /api/v1/profile/create
  Future<CreateProfileResponse> create(CreateProfileRequest request) async {
    try {
      final res = await _dio.post('/api/v1/profile/create',
          data: request.toJson());
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return CreateProfileResponse.fromJson(data);
      }
      return CreateProfileResponse(isSuccess: false, errorMessage: 'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return CreateProfileResponse(isSuccess: false, errorMessage: _dioMessage(e));
    } catch (e) {
      return CreateProfileResponse(isSuccess: false, errorMessage: 'Unexpected error: $e');
    }
  }

  /// GET /api/v1/profile/details — authenticated user's profile
  Future<UserProfileDetails?> getMyProfile() async {
    try {
      final res = await _dio.get('/api/v1/profile/details');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return UserProfileDetails.fromJson(data);
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/v1/profile/by-identity/{identityUserId}
  Future<UserProfileDetails?> getProfileByIdentity(
      String identityUserId) async {
    try {
      final res =
          await _dio.get('/api/v1/profile/by-identity/$identityUserId');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return UserProfileDetails.fromJson(data);
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
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
