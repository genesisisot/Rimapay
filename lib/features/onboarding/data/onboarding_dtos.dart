// Request/response models for the RIMA Accounts / Onboarding API (`/api/v1/onboarding/*`).
// Field names match the swagger spec exactly.

enum IdentityDocumentType {
  bvn,
  nin;

  int get value => index + 1;

  /// String the API expects for the IdentityDocumentType enum: 'BVN' | 'NIN'.
  String get apiName => name.toUpperCase();

  static IdentityDocumentType fromValue(int v) =>
      IdentityDocumentType.values[v - 1];
  static IdentityDocumentType fromString(String s) =>
      switch (s.toUpperCase()) {
        'BVN' => IdentityDocumentType.bvn,
        'NIN' => IdentityDocumentType.nin,
        _ => IdentityDocumentType.bvn,
      };
}

enum OnboardingStage {
  initialDataEntry,
  identityVerification,
  phoneNumberVerification,
  otpPending,
  otpVerified,
  facialValidationPending,
  facialValidationCompleted,
  passwordCreationPending,
  identityAccountCreated,
  profileCreationPending,
  profileCreated,
  coreBankingAccountPending,
  coreBankingAccountCreated,
  pinCreationPending,
  completed,
  failed;

  static OnboardingStage fromString(String s) =>
      OnboardingStage.values.firstWhere(
        // Backend sends PascalCase ("FacialValidationPending"); enum names are
        // camelCase. Compare case-insensitively so stages map correctly.
        (e) => e.name.toLowerCase() == s.toLowerCase(),
        orElse: () => OnboardingStage.initialDataEntry,
      );

  /// Tolerant parse — the gateway returns the stage as either the enum NAME
  /// (e.g. "OtpPending") or its integer INDEX (e.g. 0). Handle both.
  static OnboardingStage fromJson(Object? raw) {
    if (raw is int) {
      return (raw >= 0 && raw < OnboardingStage.values.length)
          ? OnboardingStage.values[raw]
          : OnboardingStage.initialDataEntry;
    }
    if (raw is String) return fromString(raw);
    return OnboardingStage.initialDataEntry;
  }
}

enum OnboardingStatus {
  inProgress,
  completed,
  failed,
  expired,
  abandoned;

  static OnboardingStatus fromString(String s) =>
      OnboardingStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == s.toLowerCase(),
        orElse: () => OnboardingStatus.inProgress,
      );

  /// Tolerant parse — accepts the enum NAME or its integer INDEX.
  static OnboardingStatus fromJson(Object? raw) {
    if (raw is int) {
      return (raw >= 0 && raw < OnboardingStatus.values.length)
          ? OnboardingStatus.values[raw]
          : OnboardingStatus.inProgress;
    }
    if (raw is String) return fromString(raw);
    return OnboardingStatus.inProgress;
  }
}

// ── Initiate ────────────────────────────────────────────────────────────────

class InitiateOnboardingRequest {
  final String? phoneNumber;
  final String? email;
  final String? identityNumber;
  final IdentityDocumentType? documentType;
  final String? deviceId;
  final String? deviceInfo;
  final String? ipAddress;

  const InitiateOnboardingRequest({
    this.phoneNumber,
    this.email,
    this.identityNumber,
    this.documentType,
    this.deviceId,
    this.deviceInfo,
    this.ipAddress,
  });

  Map<String, dynamic> toJson() => {
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (email != null) 'email': email,
        if (identityNumber != null) 'identityNumber': identityNumber,
        if (documentType != null) 'documentType': documentType!.apiName,
        if (deviceId != null) 'deviceId': deviceId,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
        if (ipAddress != null) 'ipAddress': ipAddress,
      };
}

class InitiateOnboardingResponse {
  final String sessionId;
  final OnboardingStage currentStage;
  final String? otpReference;
  final String? maskedDestination;
  final DateTime? otpExpiresAt;
  final String? firstName;
  final String? lastName;
  final DateTime expiresAt;
  final String? message;

  const InitiateOnboardingResponse({
    required this.sessionId,
    required this.currentStage,
    this.otpReference,
    this.maskedDestination,
    this.otpExpiresAt,
    this.firstName,
    this.lastName,
    required this.expiresAt,
    this.message,
  });

  factory InitiateOnboardingResponse.fromJson(Map<String, dynamic> json) {
    return InitiateOnboardingResponse(
      sessionId: json['sessionId'] as String,
      currentStage: OnboardingStage.fromJson(json['currentStage']),
      otpReference: json['otpReference'] as String?,
      maskedDestination: json['maskedDestination'] as String?,
      otpExpiresAt: json['otpExpiresAt'] != null
          ? DateTime.parse(json['otpExpiresAt'] as String)
          : null,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      message: json['message'] as String?,
    );
  }
}

// ── Verify OTP ──────────────────────────────────────────────────────────────

class VerifyOnboardingOtpRequest {
  final String sessionId;
  final String otpCode;
  final String otpReference;

  const VerifyOnboardingOtpRequest({
    required this.sessionId,
    required this.otpCode,
    required this.otpReference,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'otpCode': otpCode,
        'otpReference': otpReference,
      };
}

class VerifyOnboardingOtpResponse {
  final String sessionId;
  final OnboardingStage currentStage;
  final bool isVerified;
  final String? facialValidationHint;
  final String? message;

  const VerifyOnboardingOtpResponse({
    required this.sessionId,
    required this.currentStage,
    required this.isVerified,
    this.facialValidationHint,
    this.message,
  });

  factory VerifyOnboardingOtpResponse.fromJson(Map<String, dynamic> json) =>
      VerifyOnboardingOtpResponse(
        sessionId: json['sessionId'] as String,
        currentStage:
            OnboardingStage.fromJson(json['currentStage']),
        isVerified: json['isVerified'] == true,
        facialValidationHint: json['facialValidationHint'] as String?,
        message: json['message'] as String?,
      );
}

// ── Resend OTP ──────────────────────────────────────────────────────────────

class ResendOnboardingOtpRequest {
  final String sessionId;

  const ResendOnboardingOtpRequest({required this.sessionId});

  Map<String, dynamic> toJson() => {'sessionId': sessionId};
}

// ── Submit Identity ─────────────────────────────────────────────────────────

class SubmitIdentityRequest {
  final String sessionId;
  final String identityNumber;
  final IdentityDocumentType documentType;

  const SubmitIdentityRequest({
    required this.sessionId,
    required this.identityNumber,
    required this.documentType,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'identityNumber': identityNumber,
        'documentType': documentType.apiName,
      };
}

class SubmitIdentityResponse {
  final String sessionId;
  final OnboardingStage currentStage;
  final String? firstName;
  final String? lastName;
  final ValidatedIdentityData? identityData;
  final String? message;

  const SubmitIdentityResponse({
    required this.sessionId,
    required this.currentStage,
    this.firstName,
    this.lastName,
    this.identityData,
    this.message,
  });

  factory SubmitIdentityResponse.fromJson(Map<String, dynamic> json) =>
      SubmitIdentityResponse(
        sessionId: json['sessionId'] as String,
        currentStage:
            OnboardingStage.fromJson(json['currentStage']),
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        identityData: json['identityData'] != null
            ? ValidatedIdentityData.fromJson(
                json['identityData'] as Map<String, dynamic>)
            : null,
        message: json['message'] as String?,
      );
}

// ── Facial Validation ──────────────────────────────────────────────────────

class FacialValidationRequest {
  final String sessionId;
  final String capturedImageBase64;
  final bool? livenessCheckPassed;

  const FacialValidationRequest({
    required this.sessionId,
    required this.capturedImageBase64,
    this.livenessCheckPassed,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'capturedImageBase64': capturedImageBase64,
        if (livenessCheckPassed != null)
          'livenessCheckPassed': livenessCheckPassed,
      };
}

class FacialValidationResponse {
  final String sessionId;
  final OnboardingStage currentStage;
  final bool isMatch;
  final double confidenceScore;
  final String? message;

  const FacialValidationResponse({
    required this.sessionId,
    required this.currentStage,
    required this.isMatch,
    required this.confidenceScore,
    this.message,
  });

  factory FacialValidationResponse.fromJson(Map<String, dynamic> json) =>
      FacialValidationResponse(
        sessionId: json['sessionId'] as String,
        currentStage:
            OnboardingStage.fromJson(json['currentStage']),
        isMatch: json['isMatch'] == true,
        confidenceScore: (json['confidenceScore'] as num).toDouble(),
        message: json['message'] as String?,
      );
}

// ── Create Password ─────────────────────────────────────────────────────────

class CreatePasswordRequest {
  final String sessionId;
  final String password;
  final String confirmPassword;

  const CreatePasswordRequest({
    required this.sessionId,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'password': password,
        'confirmPassword': confirmPassword,
      };
}

class CreatePasswordResponse {
  final String sessionId;
  final OnboardingStage currentStage;
  final String? identityUserId;
  final bool profileCreated;
  final bool coreBankingAccountPending;
  final String? accountNumber;
  final String? message;

  const CreatePasswordResponse({
    required this.sessionId,
    required this.currentStage,
    this.identityUserId,
    required this.profileCreated,
    required this.coreBankingAccountPending,
    this.accountNumber,
    this.message,
  });

  factory CreatePasswordResponse.fromJson(Map<String, dynamic> json) =>
      CreatePasswordResponse(
        sessionId: json['sessionId'] as String,
        currentStage:
            OnboardingStage.fromJson(json['currentStage']),
        identityUserId: json['identityUserId'] as String?,
        profileCreated: json['profileCreated'] == true,
        coreBankingAccountPending: json['coreBankingAccountPending'] == true,
        accountNumber: json['accountNumber'] as String?,
        message: json['message'] as String?,
      );
}

// ── Create PIN ──────────────────────────────────────────────────────────────

class CreatePinRequest {
  final String sessionId;
  final String pin;
  final String confirmPin;

  const CreatePinRequest({
    required this.sessionId,
    required this.pin,
    required this.confirmPin,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'pin': pin,
        'confirmPin': confirmPin,
      };
}

class CreatePinResponse {
  final String sessionId;
  final OnboardingStage finalStage;
  final String identityUserId;
  final String? accountNumber;
  final bool isOnboardingComplete;
  final String? message;

  const CreatePinResponse({
    required this.sessionId,
    required this.finalStage,
    required this.identityUserId,
    this.accountNumber,
    required this.isOnboardingComplete,
    this.message,
  });

  factory CreatePinResponse.fromJson(Map<String, dynamic> json) =>
      CreatePinResponse(
        sessionId: json['sessionId'] as String,
        finalStage:
            OnboardingStage.fromJson(json['finalStage']),
        identityUserId: json['identityUserId'] as String,
        accountNumber: json['accountNumber'] as String?,
        isOnboardingComplete: json['isOnboardingComplete'] == true,
        message: json['message'] as String?,
      );
}

// ── Check Status ────────────────────────────────────────────────────────────

class CheckOnboardingStatusRequest {
  final String? phoneNumber;
  final String? email;
  final String? identityNumber;

  const CheckOnboardingStatusRequest({
    this.phoneNumber,
    this.email,
    this.identityNumber,
  });

  Map<String, dynamic> toJson() => {
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (email != null) 'email': email,
        if (identityNumber != null) 'identityNumber': identityNumber,
      };
}

class OnboardingStatusResponse {
  final bool hasActiveSession;
  final String? sessionId;
  final OnboardingStage currentStage;
  final OnboardingStatus status;
  final bool canResume;
  final DateTime? expiresAt;
  final String? message;

  const OnboardingStatusResponse({
    required this.hasActiveSession,
    this.sessionId,
    required this.currentStage,
    required this.status,
    required this.canResume,
    this.expiresAt,
    this.message,
  });

  factory OnboardingStatusResponse.fromJson(Map<String, dynamic> json) =>
      OnboardingStatusResponse(
        hasActiveSession: json['hasActiveSession'] == true,
        sessionId: json['sessionId'] as String?,
        currentStage:
            OnboardingStage.fromJson(json['currentStage']),
        status: OnboardingStatus.fromJson(json['status']),
        canResume: json['canResume'] == true,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        message: json['message'] as String?,
      );
}

// ── Resume ──────────────────────────────────────────────────────────────────

class ResumeOnboardingRequest {
  final String sessionId;
  final String? deviceId;
  final String? ipAddress;

  const ResumeOnboardingRequest({
    required this.sessionId,
    this.deviceId,
    this.ipAddress,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        if (deviceId != null) 'deviceId': deviceId,
        if (ipAddress != null) 'ipAddress': ipAddress,
      };
}

class ResumeOnboardingResponse {
  final String sessionId;
  final OnboardingStage currentStage;
  final OnboardingStatus status;
  final String? firstName;
  final String? lastName;
  final bool requiresOtpResend;
  final DateTime expiresAt;
  final String? message;

  const ResumeOnboardingResponse({
    required this.sessionId,
    required this.currentStage,
    required this.status,
    this.firstName,
    this.lastName,
    required this.requiresOtpResend,
    required this.expiresAt,
    this.message,
  });

  factory ResumeOnboardingResponse.fromJson(Map<String, dynamic> json) =>
      ResumeOnboardingResponse(
        sessionId: json['sessionId'] as String,
        currentStage:
            OnboardingStage.fromJson(json['currentStage']),
        status: OnboardingStatus.fromJson(json['status']),
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        requiresOtpResend: json['requiresOtpResend'] == true,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        message: json['message'] as String?,
      );
}

// ── Session State ───────────────────────────────────────────────────────────

class ValidatedIdentityData {
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? phoneNumber;
  final String? email;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? nationality;
  final String? photoBase64;
  final String? identityNumber;
  final IdentityDocumentType documentType;
  final bool isValid;
  final String? errorMessage;

  const ValidatedIdentityData({
    this.firstName,
    this.lastName,
    this.middleName,
    this.phoneNumber,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.nationality,
    this.photoBase64,
    this.identityNumber,
    required this.documentType,
    required this.isValid,
    this.errorMessage,
  });

  factory ValidatedIdentityData.fromJson(Map<String, dynamic> json) =>
      ValidatedIdentityData(
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        middleName: json['middleName'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        email: json['email'] as String?,
        dateOfBirth: json['dateOfBirth'] as String?,
        gender: json['gender'] as String?,
        address: json['address'] as String?,
        nationality: json['nationality'] as String?,
        photoBase64: json['photoBase64'] as String?,
        identityNumber: json['identityNumber'] as String?,
        documentType: json['documentType'] != null
            ? IdentityDocumentType.fromString(json['documentType'] as String)
            : IdentityDocumentType.bvn,
        isValid: json['isValid'] == true,
        errorMessage: json['errorMessage'] as String?,
      );
}

class OnboardingSessionState {
  final String sessionId;
  final OnboardingStage currentStage;
  final OnboardingStatus status;
  final String? phoneNumber;
  final String? email;
  final String? identityNumber;
  final IdentityDocumentType documentType;
  final ValidatedIdentityData? validatedData;
  final String? identityUserId;
  final String? accountNumber;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final DateTime? expiresAt;
  final bool canResume;

  const OnboardingSessionState({
    required this.sessionId,
    required this.currentStage,
    required this.status,
    this.phoneNumber,
    this.email,
    this.identityNumber,
    required this.documentType,
    this.validatedData,
    this.identityUserId,
    this.accountNumber,
    required this.createdAt,
    this.lastUpdatedAt,
    this.expiresAt,
    required this.canResume,
  });

  factory OnboardingSessionState.fromJson(Map<String, dynamic> json) =>
      OnboardingSessionState(
        sessionId: json['sessionId'] as String,
        currentStage:
            OnboardingStage.fromJson(json['currentStage']),
        status: OnboardingStatus.fromJson(json['status']),
        phoneNumber: json['phoneNumber'] as String?,
        email: json['email'] as String?,
        identityNumber: json['identityNumber'] as String?,
        documentType: json['documentType'] != null
            ? IdentityDocumentType.fromString(json['documentType'] as String)
            : IdentityDocumentType.bvn,
        validatedData: json['validatedData'] != null
            ? ValidatedIdentityData.fromJson(
                json['validatedData'] as Map<String, dynamic>)
            : null,
        identityUserId: json['identityUserId'] as String?,
        accountNumber: json['accountNumber'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastUpdatedAt: json['lastUpdatedAt'] != null
            ? DateTime.parse(json['lastUpdatedAt'] as String)
            : null,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        canResume: json['canResume'] == true,
      );
}

// ── Account Summary ─────────────────────────────────────────────────────────

class AccountSummary {
  final String identityUserId;
  final String? profileId;
  final String? accountNumber;
  final String? customerId;
  final String? balance;
  final String? balanceResponseCode;
  final String? balanceResponseDesc;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? phoneNumber;
  final String? email;
  final String? identityNumber;
  final IdentityDocumentType documentType;
  final DateTime onboardedAt;

  const AccountSummary({
    required this.identityUserId,
    this.profileId,
    this.accountNumber,
    this.customerId,
    this.balance,
    this.balanceResponseCode,
    this.balanceResponseDesc,
    this.firstName,
    this.lastName,
    this.middleName,
    this.phoneNumber,
    this.email,
    this.identityNumber,
    required this.documentType,
    required this.onboardedAt,
  });

  factory AccountSummary.fromJson(Map<String, dynamic> json) =>
      AccountSummary(
        identityUserId: json['identityUserId'] as String,
        profileId: json['profileId'] as String?,
        accountNumber: json['accountNumber'] as String?,
        customerId: json['customerId'] as String?,
        balance: json['balance'] as String?,
        balanceResponseCode: json['balanceResponseCode'] as String?,
        balanceResponseDesc: json['balanceResponseDesc'] as String?,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        middleName: json['middleName'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        email: json['email'] as String?,
        identityNumber: json['identityNumber'] as String?,
        documentType: json['documentType'] != null
            ? IdentityDocumentType.fromString(json['documentType'] as String)
            : IdentityDocumentType.bvn,
        onboardedAt: DateTime.parse(json['onboardedAt'] as String),
      );
}
