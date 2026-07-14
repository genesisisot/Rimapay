import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import 'profile_dtos.dart';

class AccountsApiService {
  AccountsApiService({Dio? dio})
      : _dio =
            dio ?? DioClient.instance.forBaseUrl(ApiConfig.accountsBaseUrl);

  final Dio _dio;

  /// GET /api/v1/accounts/get-all-accounts
  Future<List<AccountSummaryDto>> getAllAccounts() async {
    try {
      final res = await _dio.get('/api/v1/accounts/get-all-accounts');
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner is List) {
          return inner
              .map((e) =>
                  AccountSummaryDto.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (inner is Map<String, dynamic>) {
          return [AccountSummaryDto.fromJson(inner)];
        }
      }
      return [];
    } on DioException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }
}
