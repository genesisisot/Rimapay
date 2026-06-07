import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuration for all RIMA API gateways.
///
/// Identity API  → rimaaa.json ("RIMA IDENTITY API")
/// OTP API       → https://api.rimabank.ng/otp/swagger
/// Profile API   → https://api.rimabank.ng/profile/swagger
/// Accounts API  → https://api.rimabank.ng/accounts/swagger
///
/// The OpenAPI specs have no `servers` block and do not contain the app's
/// client credentials, so they live here. Fill these in with the real values
/// before running against the live identity service.
class ApiConfig {
  ApiConfig._();

  // ── Gateway resolution ────────────────────────────────────────────────────
  //
  // All four services share one host with different path segments
  // (identity / otp / profile / accounts). The gateway ROOT is resolved as:
  //
  //   1. `--dart-define=API_GATEWAY=<url>` if provided. Use this for any
  //      environment that can reach the backend directly (mobile builds, or a
  //      web host that CANNOT proxy). Example:
  //        flutter build web --dart-define=API_GATEWAY=https://api.rimabank.ng
  //
  //   2. Otherwise, on web: the app's own origin (same-origin). A reverse proxy
  //      (see vercel.json) rewrites /identity, /otp, /profile, /accounts to the
  //      real backend, which sidesteps browser CORS.
  //
  //   3. Otherwise (mobile, no override): the live backend directly.
  static const String _gatewayOverride =
      String.fromEnvironment('API_GATEWAY', defaultValue: '');

  /// Direct backend host, used on mobile and as the proxy target.
  static const String directGateway = 'https://api.rimabank.ng';

  static String get _gateway {
    if (_gatewayOverride.isNotEmpty) return _gatewayOverride;
    if (kIsWeb) return Uri.base.origin; // same-origin → proxied by the host
    return directGateway;
  }

  // ── Base URLs ─────────────────────────────────────────────────────────────

  /// Base URL for the Identity API gateway.
  static String get baseUrl => '$_gateway/identity';

  /// Base URL for the OTP / Notification API gateway.
  static String get otpBaseUrl => '$_gateway/otp';

  /// Base URL for the Profile API gateway.
  static String get profileBaseUrl => '$_gateway/profile';

  /// Base URL for the Accounts / Onboarding API gateway.
  static String get accountsBaseUrl => '$_gateway/accounts';

  // ── Client credentials & defaults ─────────────────────────────────────────

  // TODO: Replace with the real app client credentials issued by the Identity service.
  /// OAuth client id for this mobile app (LoginRequestDto.clientId).
  static const String clientId = 'rimapay-mobile';

  /// OAuth client secret for this mobile app (LoginRequestDto.clientSecret).
  static const String clientSecret = 'CHANGE_ME';

  /// Grant type used by end-user password login (GrantType enum: Confidential | Password).
  static const String grantType = 'Password';

  /// Default channel used when initiating PIN change/reset OTP flows.
  /// Must match the OtpChannel enum on the OTP API: Sms | Email | Both.
  static const String defaultOtpChannel = 'Sms';

  // ── Timeouts ──────────────────────────────────────────────────────────────

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
