// Request models for the RIMA Identity API `/api/security/pin/*` endpoints.
// Field names match rimaaa.json exactly. PIN is 4–8 digits.

/// CreatePinRequestDto — POST /api/security/pin/create
class CreatePinRequest {
  final String pin; // 4–8 chars
  final String confirmPin;
  final String userId; // UUID – required by the API

  const CreatePinRequest({
    required this.pin,
    required this.confirmPin,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'pin': pin,
        'confirmPin': confirmPin,
        'userId': userId,
      };
}

/// VerifyPinRequestDto — POST /api/security/pin/verify
class VerifyPinRequest {
  final String pin;

  const VerifyPinRequest({required this.pin});

  Map<String, dynamic> toJson() => {'pin': pin};
}

/// InitiatePinChangeRequestDto / InitiatePinResetRequestDto
/// POST /api/security/pin/change/initiate and /reset/initiate
class InitiatePinRequest {
  final String channel;

  const InitiatePinRequest({required this.channel});

  Map<String, dynamic> toJson() => {'channel': channel};
}

/// ValidatePinChangeRequestDto / ValidatePinResetRequestDto
/// POST /api/security/pin/change/validate and /reset/validate
class ValidatePinRequest {
  final String reference;
  final String otp;
  final String newPin; // 4–8 chars
  final String confirmPin;

  const ValidatePinRequest({
    required this.reference,
    required this.otp,
    required this.newPin,
    required this.confirmPin,
  });

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'otp': otp,
        'newPin': newPin,
        'confirmPin': confirmPin,
      };
}
