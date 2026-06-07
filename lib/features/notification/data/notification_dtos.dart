// Request/response models for the RIMA Notification API (`/api/v1/notification/*`).
// Field names match the swagger spec exactly.

enum NotificationType {
  otp,
  transactionAlert,
  accountActivity,
  marketing,
  securityAlert,
  system,
  welcome,
  passwordReset,
  statement,
  paymentReminder,
  custom;
}

enum NotificationChannelType {
  sms,
  email,
  whatsApp,
  mobilePush,
  webPush,
  all;

  int get value => index + 1;
  static NotificationChannelType fromValue(int v) =>
      NotificationChannelType.values[v - 1];
}

enum NotificationPriority {
  low,
  normal,
  high,
  critical;
}

enum NotificationStatus {
  pending,
  processing,
  sent,
  delivered,
  read,
  failed,
  cancelled,
  expired;
}

/// DeviceTokenDto — used for push notification registration
class DeviceTokenDto {
  final String token;
  final String platform;
  final String? appId;

  const DeviceTokenDto({
    required this.token,
    required this.platform,
    this.appId,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'platform': platform,
        if (appId != null) 'appId': appId,
      };

  factory DeviceTokenDto.fromJson(Map<String, dynamic> json) {
    return DeviceTokenDto(
      token: json['token'] as String,
      platform: json['platform'] as String,
      appId: json['appId'] as String?,
    );
  }
}

/// SendSmsRequestDto — POST /api/v1/notification/sms
class SendSmsRequest {
  final String phoneNumber;
  final String message;
  final String? senderId;
  final String? templateCode;
  final Map<String, String>? templateParameters;
  final String? idempotencyKey;
  final NotificationPriority? priority;

  const SendSmsRequest({
    required this.phoneNumber,
    required this.message,
    this.senderId,
    this.templateCode,
    this.templateParameters,
    this.idempotencyKey,
    this.priority,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'message': message,
        if (senderId != null) 'senderId': senderId,
        if (templateCode != null) 'templateCode': templateCode,
        if (templateParameters != null)
          'templateParameters': templateParameters,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
        if (priority != null) 'priority': priority!.name,
      };
}

/// SendSmsResponseDto
class SendSmsResponse {
  final String notificationId;
  final String? messageId;
  final NotificationStatus status;
  final int segmentCount;
  final double? costPerSegment;
  final double? totalCost;
  final String? currency;
  final String? message;

  const SendSmsResponse({
    required this.notificationId,
    this.messageId,
    required this.status,
    required this.segmentCount,
    this.costPerSegment,
    this.totalCost,
    this.currency,
    this.message,
  });

  factory SendSmsResponse.fromJson(Map<String, dynamic> json) {
    return SendSmsResponse(
      notificationId: json['notificationId'] as String,
      messageId: json['messageId'] as String?,
      status: _parseStatus(json['status']),
      segmentCount: (json['segmentCount'] as num).toInt(),
      costPerSegment: (json['costPerSegment'] as num?)?.toDouble(),
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      message: json['message'] as String?,
    );
  }

  static NotificationStatus _parseStatus(dynamic v) {
    if (v is String) {
      return NotificationStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => NotificationStatus.pending,
      );
    }
    return NotificationStatus.pending;
  }
}

/// SendPushNotificationRequestDto — POST /api/v1/notification/push
class SendPushNotificationRequest {
  final List<DeviceTokenDto> deviceTokens;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionUrl;
  final Map<String, String>? data;
  final int? badge;
  final String? sound;
  final int? ttlSeconds;
  final String? collapseKey;
  final String? idempotencyKey;
  final NotificationPriority? priority;

  const SendPushNotificationRequest({
    required this.deviceTokens,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionUrl,
    this.data,
    this.badge,
    this.sound,
    this.ttlSeconds,
    this.collapseKey,
    this.idempotencyKey,
    this.priority,
  });

  Map<String, dynamic> toJson() => {
        'deviceTokens': deviceTokens.map((e) => e.toJson()).toList(),
        'title': title,
        'body': body,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (actionUrl != null) 'actionUrl': actionUrl,
        if (data != null) 'data': data,
        if (badge != null) 'badge': badge,
        if (sound != null) 'sound': sound,
        if (ttlSeconds != null) 'ttlSeconds': ttlSeconds,
        if (collapseKey != null) 'collapseKey': collapseKey,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
        if (priority != null) 'priority': priority!.name,
      };
}

/// SendPushNotificationResponseDto
class SendPushNotificationResponse {
  final String notificationId;
  final int successCount;
  final int failureCount;
  final NotificationStatus status;
  final String? message;

  const SendPushNotificationResponse({
    required this.notificationId,
    required this.successCount,
    required this.failureCount,
    required this.status,
    this.message,
  });

  factory SendPushNotificationResponse.fromJson(Map<String, dynamic> json) {
    return SendPushNotificationResponse(
      notificationId: json['notificationId'] as String,
      successCount: (json['successCount'] as num).toInt(),
      failureCount: (json['failureCount'] as num).toInt(),
      status: SendSmsResponse._parseStatus(json['status']),
      message: json['message'] as String?,
    );
  }
}
