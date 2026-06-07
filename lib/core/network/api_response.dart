/// Mirrors the `ApiResponse` envelope used by every RIMA Identity API response
/// (rimaaa.json → components.schemas.ApiResponse and its `*ApiResponse` variants):
/// `{ isSuccess, errorCode, statusCode, message, devMessage, exceptionStackTrace, data? }`.
class ApiResponse<T> {
  final bool isSuccess;
  final String? errorCode;
  final String? statusCode;
  final String? message;
  final String? devMessage;
  final T? data;

  const ApiResponse({
    required this.isSuccess,
    this.errorCode,
    this.statusCode,
    this.message,
    this.devMessage,
    this.data,
  });

  /// Parses the envelope. [fromData] maps the `data` field (when present) to [T].
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? data)? fromData,
  }) {
    final rawData = json['data'];
    return ApiResponse<T>(
      isSuccess: json['isSuccess'] == true,
      errorCode: json['errorCode'] as String?,
      statusCode: json['statusCode']?.toString(),
      message: json['message'] as String?,
      devMessage: json['devMessage'] as String?,
      data: (fromData != null && rawData != null) ? fromData(rawData) : null,
    );
  }

  /// A synthetic failure response (network/parse errors that never reach the server).
  factory ApiResponse.failure(String message, {String? errorCode}) {
    return ApiResponse<T>(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
    );
  }

  /// Best-effort human-readable error for the UI.
  String get errorMessage =>
      message ?? devMessage ?? errorCode ?? 'Something went wrong. Please try again.';
}
