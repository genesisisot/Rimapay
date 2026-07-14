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

  /// POST /api/v1/profile/completion/address
  Future<CompletionResponse> completeAddress(
      AddressCompletionRequest request) async {
    return _postCompletion('/api/v1/profile/completion/address',
        request.toJson());
  }

  /// POST /api/v1/profile/completion/pep
  Future<CompletionResponse> completePep(
      PepCompletionRequest request) async {
    return _postCompletion('/api/v1/profile/completion/pep',
        request.toJson());
  }

  /// POST /api/v1/profile/completion/source-of-income
  Future<CompletionResponse> completeSourceOfIncome(
      SourceOfIncomeRequest request) async {
    return _postCompletion(
        '/api/v1/profile/completion/source-of-income', request.toJson());
  }

  /// GET /api/v1/profile/completion
  Future<ProfileCompletionStatusDto?> getCompletionStatus() async {
    try {
      final res = await _dio.get('/api/v1/profile/completion');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ProfileCompletionStatusDto.fromJson(data);
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/v1/profile/by-identity/{identityUserId}/image-base64
  Future<String?> getProfileImageBase64(String identityUserId) async {
    try {
      final res = await _dio.get(
          '/api/v1/profile/by-identity/$identityUserId/image-base64');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return data['data'] as String?;
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/v1/profile/daily-limit
  Future<DailyLimitResponse?> getDailyLimit() async {
    try {
      final res = await _dio.get('/api/v1/profile/daily-limit');
      return _unwrapData(res.data, DailyLimitResponse.fromJson);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// PUT /api/v1/profile/daily-limit
  Future<DailyLimitResponse?> updateDailyLimit(
      UpdateDailyLimitRequest request) async {
    try {
      final res = await _dio.put('/api/v1/profile/daily-limit',
          data: request.toJson());
      return _unwrapData(res.data, DailyLimitResponse.fromJson);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/v1/profile/daily-limit/balance
  Future<DailyLimitBalanceResponse?> getDailyLimitBalance() async {
    try {
      final res = await _dio.get('/api/v1/profile/daily-limit/balance');
      return _unwrapData(res.data, DailyLimitBalanceResponse.fromJson);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// POST /api/v1/payment/transfer (intra-bank / Rima-to-Rima)
  Future<TransferResponse> transfer(TransferRequest request) async {
    try {
      final res =
          await _dio.post('/api/v1/payment/transfer', data: request.toJson());
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner is Map<String, dynamic>) {
          return TransferResponse.fromJson(inner);
        }
        return TransferResponse(
          isSuccess: body['isSuccess'] == true,
          errorMessage: body['message'] as String?,
          errorCode: body['errorCode'] as String?,
        );
      }
      return TransferResponse(
        isSuccess: false,
        errorMessage: 'Unexpected response (${res.statusCode}).',
      );
    } on DioException catch (e) {
      return TransferResponse(isSuccess: false, errorMessage: _dioMessage(e));
    } catch (e) {
      return TransferResponse(
          isSuccess: false, errorMessage: 'Unexpected error: $e');
    }
  }

  /// POST /api/v1/payment/transfer/inter (inter-bank / external)
  Future<TransferResponse> transferInter(TransferRequest request) async {
    try {
      final res =
          await _dio.post('/api/v1/payment/transfer/inter', data: request.toJson());
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner is Map<String, dynamic>) {
          return TransferResponse.fromJson(inner);
        }
        return TransferResponse(
          isSuccess: body['isSuccess'] == true,
          errorMessage: body['message'] as String?,
          errorCode: body['errorCode'] as String?,
        );
      }
      return TransferResponse(
        isSuccess: false,
        errorMessage: 'Unexpected response (${res.statusCode}).',
      );
    } on DioException catch (e) {
      return TransferResponse(isSuccess: false, errorMessage: _dioMessage(e));
    } catch (e) {
      return TransferResponse(
          isSuccess: false, errorMessage: 'Unexpected error: $e');
    }
  }

  /// GET /api/v1/payment/account-details/{accountNumber} — Name Enquiry
  Future<AccountDetailsResponse?> getAccountDetails(
      String accountNumber) async {
    try {
      final res = await _dio.get(
          '/api/v1/payment/account-details/$accountNumber');
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner is Map<String, dynamic>) {
          return AccountDetailsResponse.fromJson(inner);
        }
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/v1/payment/getbanks — supported destination banks (inter-bank)
  Future<List<BankDto>> getBanks() async {
    try {
      final res = await _dio.get('/api/v1/payment/getbanks');
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner is List) {
          return inner
              .whereType<Map<String, dynamic>>()
              .map(BankDto.fromJson)
              .toList();
        }
      }
      return const [];
    } on DioException catch (_) {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// GET /api/v1/payment/name-enquiry/inter?accountNumber=&bankCode= — Name Enquiry
  Future<InterNameEnquiryResponse?> nameEnquiryInter(
      String accountNumber, String bankCode) async {
    try {
      final res = await _dio.get(
        '/api/v1/payment/name-enquiry/inter',
        queryParameters: {
          'accountNumber': accountNumber,
          'bankCode': bankCode,
        },
      );
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner is Map<String, dynamic>) {
          return InterNameEnquiryResponse.fromJson(inner);
        }
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/v1/payment/status/{transactionReference}
  Future<TransferResponse?> getTransferStatus(
      String transactionReference) async {
    try {
      final res = await _dio.get(
          '/api/v1/payment/status/$transactionReference');
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner is Map<String, dynamic>) {
          return TransferResponse.fromJson(inner);
        }
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// POST /api/v1/file/upload/base64
  Future<FileUploadResponse?> uploadFileBase64(
      Base64FileUploadRequest request) async {
    try {
      final res = await _dio.post('/api/v1/file/upload/base64',
          data: request.toJson());
      return _unwrapData(res.data, FileUploadResponse.fromJson);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/v1/file/presigned-url?key=&expirySeconds=
  Future<PresignedUrlResponse?> getPresignedUrl(
      String key, int expirySeconds) async {
    try {
      final res = await _dio.get('/api/v1/file/presigned-url',
          queryParameters: {
            'key': key,
            'expirySeconds': expirySeconds,
          });
      return _unwrapData(res.data, PresignedUrlResponse.fromJson);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// DELETE /api/v1/file?key=
  Future<bool> deleteFile(String key) async {
    try {
      final res = await _dio.delete('/api/v1/file',
          queryParameters: {'key': key});
      return res.statusCode == 204;
    } on DioException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  T? _unwrapData<T>(
    dynamic responseBody,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (responseBody is! Map<String, dynamic>) return null;
    final inner = responseBody['data'];
    if (inner is Map<String, dynamic>) return fromJson(inner);
    return null;
  }

  Future<CompletionResponse> _postCompletion(
      String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return CompletionResponse.fromJson(data);
      }
      return CompletionResponse(
        isSuccess: false,
        errorMessage: 'Unexpected response (${res.statusCode}).',
      );
    } on DioException catch (e) {
      return CompletionResponse(
        isSuccess: false,
        errorMessage: _dioMessage(e),
      );
    } catch (e) {
      return CompletionResponse(
        isSuccess: false,
        errorMessage: 'Unexpected error: $e',
      );
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
