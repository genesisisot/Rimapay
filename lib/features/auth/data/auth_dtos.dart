import '../../../core/config/api_config.dart';

/// Request/response models for the RIMA Identity API `/api/auth/*` endpoints.
/// Field names match rimaaa.json exactly.

/// RegisterRequestDto — POST /api/auth/create-user
class RegisterRequest {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String password; // required, min 6
  final String confirmPassword; // required

  const RegisterRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        'password': password,
        'confirmPassword': confirmPassword,
      };
}

/// LoginRequestDto — POST /api/auth/login
/// clientId/clientSecret/grantType come from [ApiConfig]; the user supplies
/// email OR phoneNumber, plus password.
class LoginRequest {
  final String? email;
  final String? phoneNumber;
  final String password;
  final String? deviceId;

  const LoginRequest({
    this.email,
    this.phoneNumber,
    required this.password,
    this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'clientId': ApiConfig.clientId,
        'clientSecret': ApiConfig.clientSecret,
        'grantType': ApiConfig.grantType,
        'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        'password': password,
        'deviceId': deviceId,
      };
}

/// ChangePasswordRequestDto — POST /api/auth/change-password
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword; // min 6
  final String confirmPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}

/// ResetPasswordRequestDto — POST /api/auth/reset-password
class ResetPasswordRequest {
  final String sessionToken;
  final String resetCode;
  final String newPassword; // min 6
  final String confirmPassword;

  const ResetPasswordRequest({
    required this.sessionToken,
    required this.resetCode,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'sessionToken': sessionToken,
        'resetCode': resetCode,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}

/// VerifyFaceResetRequestDto — POST /api/auth/verify-face-reset
class VerifyFaceResetRequest {
  final String sessionToken;
  final String faceImage;

  const VerifyFaceResetRequest({
    required this.sessionToken,
    required this.faceImage,
  });

  Map<String, dynamic> toJson() => {
        'sessionToken': sessionToken,
        'faceImage': faceImage,
      };
}

/// InitiateDeviceRegistrationRequestDto — POST /api/auth/device/register/initiate
class InitiateDeviceRegistrationRequest {
  final String deviceId;
  final String? phoneNumber;
  final String? email;
  final String? userId;

  const InitiateDeviceRegistrationRequest({
    required this.deviceId,
    this.phoneNumber,
    this.email,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (email != null) 'email': email,
        if (userId != null) 'userId': userId,
      };
}

/// VerifyDeviceFaceRequestDto — POST /api/auth/device/register/verify-face
class VerifyDeviceFaceRequest {
  final String sessionToken;
  final String faceImage;

  const VerifyDeviceFaceRequest({
    required this.sessionToken,
    required this.faceImage,
  });

  Map<String, dynamic> toJson() => {
        'sessionToken': sessionToken,
        'faceImage': faceImage,
      };
}

/// ConfirmDeviceOtpRequestDto — POST /api/auth/device/register/confirm-otp
class ConfirmDeviceOtpRequest {
  final String sessionToken;
  final String otpCode;

  const ConfirmDeviceOtpRequest({
    required this.sessionToken,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() => {
        'sessionToken': sessionToken,
        'otpCode': otpCode,
      };
}

/// ConfirmDevicePinRequestDto — POST /api/auth/device/register/confirm-pin
class ConfirmDevicePinRequest {
  final String sessionToken;
  final String pin;

  const ConfirmDevicePinRequest({
    required this.sessionToken,
    required this.pin,
  });

  Map<String, dynamic> toJson() => {
        'sessionToken': sessionToken,
        'pin': pin,
      };
}

/// AuthResponseDto — returned by create-user / login / refresh-token.
class AuthResponse {
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final bool emailConfirmed;
  final String? token;
  final String? refreshToken;
  final String? refreshTokenExpiryTime;
  final String? role;
  final String? userType;
  final List<String> permissions;
  final bool pinCreated;

  const AuthResponse({
    this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.emailConfirmed = false,
    this.token,
    this.refreshToken,
    this.refreshTokenExpiryTime,
    this.role,
    this.userType,
    this.permissions = const [],
    this.pinCreated = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      emailConfirmed: json['emailConfirmed'] == true,
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      refreshTokenExpiryTime: json['refreshTokenExpiryTime'] as String?,
      role: json['role'] as String?,
      userType: json['userType'] as String?,
      permissions: (json['permissions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      pinCreated: json['hasCreatedPin'] == true,
    );
  }
}
