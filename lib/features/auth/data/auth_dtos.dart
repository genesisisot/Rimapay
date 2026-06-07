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

  const LoginRequest({
    this.email,
    this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'clientId': ApiConfig.clientId,
        'clientSecret': ApiConfig.clientSecret,
        'grantType': ApiConfig.grantType,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        'password': password,
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
  final String email;
  final String token;
  final String newPassword; // min 6
  final String confirmPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
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
    );
  }
}
