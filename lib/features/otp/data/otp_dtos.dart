// Request/response models for the RIMA OTP API (`/api/v1/otp/*`).
// Field names match the swagger spec exactly.

enum OtpPurpose {
  onboarding,
  pinChange,
  pinReset,
  passwordChange,
  passwordReset,
  transactionAuthorization,
  emailVerification,
  phoneVerification,
  twoFactorAuth,
  deviceLinking,
  accountRecovery,
  beneficiaryAddition,
  limitChange;

  int get value => index + 1;
  static OtpPurpose fromValue(int v) => OtpPurpose.values[v - 1];
}

enum OtpChannel {
  sms,
  email,
  both;

  int get value => index + 1;
  static OtpChannel fromValue(int v) => OtpChannel.values[v - 1];
}

/// GenerateOtpRequestDto — POST /api/v1/otp/generate
class GenerateOtpRequest {
  final String serviceId;
  final OtpPurpose purpose;
  final OtpChannel channel;
  final String identifier;
  final String? phoneNumber;
  final String? email;
  final String? recipientName;
  final int? expiryMinutes;
  final int? maxAttempts;
  final String? metadata;

  const GenerateOtpRequest({
    required this.serviceId,
    required this.purpose,
    required this.channel,
    required this.identifier,
    this.phoneNumber,
    this.email,
    this.recipientName,
    this.expiryMinutes,
    this.maxAttempts,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'purpose': purpose.value,
        'channel': channel.value,
        'identifier': identifier,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (email != null) 'email': email,
        if (recipientName != null) 'recipientName': recipientName,
        if (expiryMinutes != null) 'expiryMinutes': expiryMinutes,
        if (maxAttempts != null) 'maxAttempts': maxAttempts,
        if (metadata != null) 'metadata': metadata,
      };
}

/// GenerateOtpResponseDto — returned by generate and resend
class GenerateOtpResponse {
  final String? reference;
  final OtpPurpose purpose;
  final OtpChannel channel;
  final String? maskedDestination;
  final DateTime expiresAt;
  final int expiryMinutes;
  final int maxAttempts;
  final DateTime generatedAt;

  const GenerateOtpResponse({
    this.reference,
    required this.purpose,
    required this.channel,
    this.maskedDestination,
    required this.expiresAt,
    required this.expiryMinutes,
    required this.maxAttempts,
    required this.generatedAt,
  });

  factory GenerateOtpResponse.fromJson(Map<String, dynamic> json) {
    return GenerateOtpResponse(
      reference: json['reference'] as String?,
      purpose: OtpPurpose.values.firstWhere(
        (e) => e.value == (json['purpose'] as num?)?.toInt(),
        orElse: () => OtpPurpose.onboarding,
      ),
      channel: OtpChannel.values.firstWhere(
        (e) => e.value == (json['channel'] as num?)?.toInt(),
        orElse: () => OtpChannel.sms,
      ),
      maskedDestination: json['maskedDestination'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      expiryMinutes: (json['expiryMinutes'] as num).toInt(),
      maxAttempts: (json['maxAttempts'] as num).toInt(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}

/// VerifyOtpRequestDto — POST /api/v1/otp/verify
class VerifyOtpRequest {
  final String serviceId;
  final String reference;
  final String code;
  final String identifier;
  final OtpPurpose purpose;

  const VerifyOtpRequest({
    required this.serviceId,
    required this.reference,
    required this.code,
    required this.identifier,
    required this.purpose,
  });

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'reference': reference,
        'code': code,
        'identifier': identifier,
        'purpose': purpose.value,
      };
}

/// VerifyOtpResponseDto — returned by verify
class VerifyOtpResponse {
  final bool isVerified;
  final String? reference;
  final OtpPurpose purpose;
  final int? remainingAttempts;
  final DateTime verifiedAt;
  final String? metadata;

  const VerifyOtpResponse({
    required this.isVerified,
    this.reference,
    required this.purpose,
    this.remainingAttempts,
    required this.verifiedAt,
    this.metadata,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      isVerified: json['isVerified'] == true,
      reference: json['reference'] as String?,
      purpose: OtpPurpose.values.firstWhere(
        (e) => e.value == (json['purpose'] as num?)?.toInt(),
        orElse: () => OtpPurpose.onboarding,
      ),
      remainingAttempts: (json['remainingAttempts'] as num?)?.toInt(),
      verifiedAt: DateTime.parse(json['verifiedAt'] as String),
      metadata: json['metadata'] as String?,
    );
  }
}

/// ResendOtpRequestDto — POST /api/v1/otp/resend
class ResendOtpRequest {
  final String serviceId;
  final String reference;
  final String identifier;
  final OtpChannel channel;

  const ResendOtpRequest({
    required this.serviceId,
    required this.reference,
    required this.identifier,
    required this.channel,
  });

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'reference': reference,
        'identifier': identifier,
        'channel': channel.value,
      };
}
