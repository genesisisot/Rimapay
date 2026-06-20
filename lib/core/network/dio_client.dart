import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../services/storage_service.dart';

/// Shared Dio instances for the RIMA API gateways.
///
/// Responsibilities:
///  - base URL + JSON headers + timeouts from [ApiConfig]
///  - attach `Authorization: Bearer <token>` from [StorageService]
///  - on a 401, transparently call `/api/auth/refresh-token` once and retry
///
/// Use [DioClient.instance.dio] for the Identity API (backward compatible) or
/// [DioClient.instance.forBaseUrl] for any other gateway.
class DioClient {
  DioClient._();

  static final DioClient instance = DioClient._();

  /// Endpoint prefixes that must never carry a stale token or trigger a refresh loop.
  /// All onboarding and unauthenticated auth paths are included.
  static const _noAuthPrefixes = <String>{
    '/api/auth/login',
    '/api/auth/create-user',
    '/api/auth/refresh-token',
    '/api/auth/forgot-password',
    '/api/auth/reset-password',
    '/api/auth/verify-email',
    '/api/v1/onboarding/',
    '/api/v1/file/',
  };

  static bool _shouldSkipAuth(String path) =>
      _noAuthPrefixes.any((p) => path.startsWith(p));

  bool _isRefreshing = false;

  // Identity API Dio (backward-compatible getter).
  late final Dio dio = _create(ApiConfig.baseUrl);

  // Cache of Dio instances keyed by base URL.
  final Map<String, Dio> _instances = {};

  /// Returns a shared [Dio] instance configured for [baseUrl].
  /// Instances are cached so the same base URL always returns the same Dio.
  Dio forBaseUrl(String baseUrl) {
    if (baseUrl == ApiConfig.baseUrl) return dio;
    return _instances.putIfAbsent(baseUrl, () => _create(baseUrl));
  }

  Dio _create(String baseUrl) {
    // Per-service path quirk (verified by probing the live gateway):
    // All gateways serve routes WITH the `/api` prefix (matching their OAS).
    //   • Identity  → .../identity/api/auth/login
    //   • Accounts  → .../accounts/api/v1/onboarding/initiate
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: 'application/json',
        headers: {'accept': 'application/json'},
        validateStatus: (_) => true,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_shouldSkipAuth(options.path)) {
            final token = await StorageService.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          // All gateways serve routes with the `/api` prefix — no rewrite needed.
          handler.next(options);
        },
        onResponse: (response, handler) async {
          final isAuthError = response.statusCode == 401;
          final path = response.requestOptions.path;
          final alreadyRetried =
              response.requestOptions.extra['__retried'] == true;

          if (isAuthError &&
              !alreadyRetried &&
              !_shouldSkipAuth(path)) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              try {
                final retried = await _retry(response.requestOptions);
                return handler.resolve(retried);
              } catch (_) {
                // fall through to original response
              }
            }
          }
          handler.next(response);
        },
      ),
    );

    return dio;
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final accessToken = await StorageService.getAccessToken();
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      // Always use the Identity API Dio for token refresh.
      final res = await dio.post(
        '/api/auth/refresh-token',
        data: {
          'accessToken': accessToken ?? '',
          'refreshToken': refreshToken,
        },
      );

      final body = res.data;
      if (res.statusCode == 200 &&
          body is Map<String, dynamic> &&
          body['isSuccess'] == true &&
          body['data'] is Map<String, dynamic>) {
        final data = body['data'] as Map<String, dynamic>;
        await StorageService.saveTokens(
          accessToken: data['token'] as String?,
          refreshToken: data['refreshToken'] as String?,
        );
        return true;
      }

      await StorageService.clearTokens();
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final token = StorageService.getAccessToken();
    return token.then((t) {
      final headers = Map<String, dynamic>.from(requestOptions.headers);
      if (t != null && t.isNotEmpty) {
        headers['Authorization'] = 'Bearer $t';
      }
      return dio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: Options(
          method: requestOptions.method,
          headers: headers,
          extra: {...requestOptions.extra, '__retried': true},
        ),
      );
    });
  }
}
