import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/onboarding_api_service.dart';
import '../../data/onboarding_dtos.dart';
import '../../../../core/services/storage_service.dart';

/// Tracks which UI step the onboarding flow is on.
enum OnboardingStep {
  initialEntry,
  otpVerification,
  identitySubmission,
  facialValidation,
  createPassword,
  createPin,
  completed,
}

/// State for the full onboarding flow.
@immutable
class OnboardingState {
  final bool isLoading;
  final String? error;
  final OnboardingStep currentStep;

  // Initiate response
  final String? sessionId;
  final String? otpReference;
  final String? maskedDestination;
  final DateTime? otpExpiresAt;
  final String? firstName;
  final String? lastName;

  // OTP
  final bool otpVerified;

  // Identity
  final String? validatedFirstName;
  final String? validatedLastName;

  // Facial
  final bool facialMatch;
  final double? confidenceScore;

  // Password
  final bool passwordCreated;
  final String? accountNumber;
  final String? identityUserId;

  // PIN
  final bool pinCreated;
  final bool onboardingComplete;

  /// True when the current step was reached by resuming an existing server
  /// session (ACTIVE_SESSION_EXISTS / check-status), so the UI can show a
  /// "Resuming…" hint and navigate to the resumed step.
  final bool justResumed;

  const OnboardingState({
    this.isLoading = false,
    this.error,
    this.currentStep = OnboardingStep.initialEntry,
    this.sessionId,
    this.otpReference,
    this.maskedDestination,
    this.otpExpiresAt,
    this.firstName,
    this.lastName,
    this.otpVerified = false,
    this.validatedFirstName,
    this.validatedLastName,
    this.facialMatch = false,
    this.confidenceScore,
    this.passwordCreated = false,
    this.accountNumber,
    this.identityUserId,
    this.pinCreated = false,
    this.onboardingComplete = false,
    this.justResumed = false,
  });

  OnboardingState copyWith({
    bool? isLoading,
    String? error,
    OnboardingStep? currentStep,
    String? sessionId,
    String? otpReference,
    String? maskedDestination,
    DateTime? otpExpiresAt,
    String? firstName,
    String? lastName,
    bool? otpVerified,
    String? validatedFirstName,
    String? validatedLastName,
    bool? facialMatch,
    double? confidenceScore,
    bool? passwordCreated,
    String? accountNumber,
    String? identityUserId,
    bool? pinCreated,
    bool? onboardingComplete,
    bool? justResumed,
  }) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentStep: currentStep ?? this.currentStep,
      sessionId: sessionId ?? this.sessionId,
      otpReference: otpReference ?? this.otpReference,
      maskedDestination: maskedDestination ?? this.maskedDestination,
      otpExpiresAt: otpExpiresAt ?? this.otpExpiresAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      otpVerified: otpVerified ?? this.otpVerified,
      validatedFirstName: validatedFirstName ?? this.validatedFirstName,
      validatedLastName: validatedLastName ?? this.validatedLastName,
      facialMatch: facialMatch ?? this.facialMatch,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      passwordCreated: passwordCreated ?? this.passwordCreated,
      accountNumber: accountNumber ?? this.accountNumber,
      identityUserId: identityUserId ?? this.identityUserId,
      pinCreated: pinCreated ?? this.pinCreated,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      justResumed: justResumed ?? this.justResumed,
    );
  }
}

final onboardingApiServiceProvider = Provider<OnboardingApiService>((ref) {
  return OnboardingApiService();
});

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._api) : super(const OnboardingState());

  final OnboardingApiService _api;

  /// Entry point for the phone step. Decides whether to resume an existing
  /// session or start a fresh one, using check-status so we only ever call
  /// `resume` when the backend says `canResume` (per backend guidance — don't
  /// call resume on a non-resumable session).
  Future<bool> beginOnboarding({
    required String phoneNumber,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final deviceId = await StorageService.getDeviceId();

    final status = await _api.checkStatus(
      CheckOnboardingStatusRequest(phoneNumber: phoneNumber),
    );
    if (status.isSuccess && status.data != null) {
      final s = status.data!;
      if (s.status == OnboardingStatus.completed) {
        state = state.copyWith(
          isLoading: false,
          error:
              'An account already exists with this phone number. Please log in instead.',
          currentStep: OnboardingStep.initialEntry,
        );
        return false;
      }
      if (s.hasActiveSession && s.canResume && s.sessionId != null) {
        return await _resumeSession(s.sessionId!, deviceId: deviceId);
      }
    }
    return await initiate(
        phoneNumber: phoneNumber, email: email, deviceId: deviceId);
  }

  /// Step 1: Initiate onboarding (BVN/NIN + phone -> OTP sent).
  Future<bool> initiate({
    required String phoneNumber,
    String? identityNumber,
    IdentityDocumentType? documentType,
    String? deviceId,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.initiate(InitiateOnboardingRequest(
      phoneNumber: phoneNumber,
      identityNumber: identityNumber,
      documentType: documentType,
      deviceId: deviceId,
      email: email,
    ));
    if (res.isSuccess && res.data != null) {
      final d = res.data!;
      state = state.copyWith(
        isLoading: false,
        currentStep: OnboardingStep.otpVerification,
        sessionId: d.sessionId,
        otpReference: d.otpReference,
        maskedDestination: d.maskedDestination,
        otpExpiresAt: d.otpExpiresAt,
        firstName: d.firstName,
        lastName: d.lastName,
        justResumed: false,
      );
      return true;
    }
    if (!res.isSuccess) {
      if (res.errorCode == 'ACTIVE_SESSION_EXISTS' && res.data != null) {
        return await _resumeSession(res.data!.sessionId, deviceId: deviceId);
      }
      if (res.errorCode == 'CANNOT_RESUME') {
        state = state.copyWith(
          isLoading: false,
          error: res.errorMessage,
          currentStep: OnboardingStep.initialEntry,
          sessionId: null,
          otpReference: null,
        );
        return false;
      }
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  /// Step 2: Verify OTP.
  Future<bool> verifyOtp(String otpCode) async {
    final sessionId = state.sessionId;
    final otpReference = state.otpReference;
    if (sessionId == null || otpReference == null) {
      state = state.copyWith(error: 'Session expired. Please restart.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.verifyOtp(VerifyOnboardingOtpRequest(
      sessionId: sessionId,
      otpCode: otpCode,
      otpReference: otpReference,
    ));
    if (res.isSuccess && res.data != null) {
      final d = res.data!;
      state = state.copyWith(
        isLoading: false,
        otpVerified: d.isVerified,
        currentStep: d.isVerified
            ? OnboardingStep.identitySubmission
            : OnboardingStep.otpVerification,
      );
      return d.isVerified;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  /// Resend OTP.
  Future<bool> resendOtp() async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      state = state.copyWith(error: 'Session expired. Please restart.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.resendOtp(ResendOnboardingOtpRequest(
      sessionId: sessionId,
    ));
    if (res.isSuccess && res.data != null) {
      final d = res.data!;
      state = state.copyWith(
        isLoading: false,
        otpReference: d.otpReference,
        maskedDestination: d.maskedDestination,
        otpExpiresAt: d.otpExpiresAt,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  /// Step 3: Submit identity (after OTP verified, before facial).
  Future<bool> submitIdentity({
    required String identityNumber,
    required IdentityDocumentType documentType,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      state = state.copyWith(error: 'Session expired. Please restart.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.submitIdentity(SubmitIdentityRequest(
      sessionId: sessionId,
      identityNumber: identityNumber,
      documentType: documentType,
    ));
    if (res.isSuccess && res.data != null) {
      final d = res.data!;
      state = state.copyWith(
        isLoading: false,
        currentStep: OnboardingStep.facialValidation,
        validatedFirstName: d.firstName,
        validatedLastName: d.lastName,
        firstName: d.firstName,
        lastName: d.lastName,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  /// Step 4: Validate face.
  Future<bool> validateFace({
    required String capturedImageBase64,
    bool? livenessCheckPassed,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      state = state.copyWith(error: 'Session expired. Please restart.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.validateFace(FacialValidationRequest(
      sessionId: sessionId,
      capturedImageBase64: capturedImageBase64,
      livenessCheckPassed: livenessCheckPassed,
    ));
    if (res.isSuccess && res.data != null) {
      final d = res.data!;
      // Strict KYC: only advance when the backend says the face actually
      // matched. Otherwise stay on the face step.
      state = state.copyWith(
        isLoading: false,
        facialMatch: d.isMatch,
        confidenceScore: d.confidenceScore,
        currentStep: d.isMatch
            ? OnboardingStep.createPassword
            : OnboardingStep.facialValidation,
        error: d.isMatch
            ? null
            : (d.message ?? 'Face did not match. Please try again.'),
      );
      return d.isMatch;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  /// Step 5: Create password.
  Future<bool> createPassword({
    required String password,
    required String confirmPassword,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      state = state.copyWith(error: 'Session expired. Please restart.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.createPassword(CreatePasswordRequest(
      sessionId: sessionId,
      password: password,
      confirmPassword: confirmPassword,
    ));
    if (res.isSuccess && res.data != null) {
      final d = res.data!;
      state = state.copyWith(
        isLoading: false,
        currentStep: OnboardingStep.createPin,
        accountNumber: d.accountNumber,
        identityUserId: d.identityUserId,
        passwordCreated: true,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  /// Step 6: Create PIN.
  Future<bool> createPin({
    required String pin,
    required String confirmPin,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      state = state.copyWith(error: 'Session expired. Please restart.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.createPin(CreatePinRequest(
      sessionId: sessionId,
      pin: pin,
      confirmPin: confirmPin,
    ));
    if (res.isSuccess && res.data != null) {
      final d = res.data!;
      state = state.copyWith(
        isLoading: false,
        currentStep: OnboardingStep.completed,
        pinCreated: true,
        onboardingComplete: d.isOnboardingComplete,
        accountNumber: d.accountNumber ?? state.accountNumber,
        identityUserId: d.identityUserId ?? state.identityUserId,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  /// Check if there's an active session to resume.
  Future<bool> checkStatus({
    String? phoneNumber,
    String? email,
    String? identityNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final deviceId = await StorageService.getDeviceId();
    final res = await _api.checkStatus(CheckOnboardingStatusRequest(
      phoneNumber: phoneNumber,
      email: email,
      identityNumber: identityNumber,
    ));
    if (res.isSuccess && res.data != null) {
      final d = res.data!;
      if (d.hasActiveSession && d.canResume && d.sessionId != null) {
        return await _resumeSession(d.sessionId!, deviceId: deviceId);
      }
      state = state.copyWith(isLoading: false);
      return false;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  Future<bool> _resumeSession(String sessionId, {String? deviceId}) async {
    final res = await _api.resume(ResumeOnboardingRequest(
      sessionId: sessionId,
      deviceId: deviceId,
    ));
    if (res.isSuccess && res.data != null) {
      final d = res.data!;
      final step = _mapStageToStep(d.currentStage);
      final landsOnOtp = step == OnboardingStep.otpVerification;
      state = state.copyWith(
        isLoading: false,
        sessionId: d.sessionId,
        currentStep: step,
        firstName: d.firstName,
        lastName: d.lastName,
        otpVerified: !landsOnOtp,
        justResumed: true,
      );
      // Only request a fresh OTP when the resumed session is actually back at
      // the OTP step (resume never returns an otpReference). For later stages
      // (identity/face/password/pin) the backend rejects resend with
      // "Cannot resend OTP at current stage", so never call it there.
      if (landsOnOtp) {
        await resendOtp();
      }
      return true;
    }
    if (res.errorCode == 'CANNOT_RESUME') {
      state = state.copyWith(
        isLoading: false,
        error: res.errorMessage,
        currentStep: OnboardingStep.initialEntry,
        sessionId: null,
        otpReference: null,
      );
      return false;
    }
    state = state.copyWith(
      isLoading: false,
      error: res.errorMessage.isNotEmpty
          ? res.errorMessage
          : 'Couldn\'t resume your existing application. Please try again shortly.',
    );
    return false;
  }

  OnboardingStep _mapStageToStep(OnboardingStage stage) {
    return switch (stage) {
      // An ACTIVE session sitting at any pre-OTP / OTP stage means the phone is
      // already captured and a code is (or should be) out — land on the OTP
      // screen rather than bouncing back to phone entry (which would re-trigger
      // ACTIVE_SESSION_EXISTS).
      OnboardingStage.initialDataEntry ||
      OnboardingStage.identityVerification ||
      OnboardingStage.phoneNumberVerification ||
      OnboardingStage.otpPending =>
        OnboardingStep.otpVerification,
      OnboardingStage.otpVerified => OnboardingStep.identitySubmission,
      OnboardingStage.facialValidationPending =>
        OnboardingStep.facialValidation,
      OnboardingStage.facialValidationCompleted ||
      OnboardingStage.passwordCreationPending ||
      OnboardingStage.identityAccountCreated ||
      OnboardingStage.profileCreationPending ||
      OnboardingStage.profileCreated ||
      OnboardingStage.coreBankingAccountPending ||
      OnboardingStage.coreBankingAccountCreated =>
        OnboardingStep.createPassword,
      OnboardingStage.pinCreationPending => OnboardingStep.createPin,
      OnboardingStage.completed => OnboardingStep.completed,
      OnboardingStage.failed => OnboardingStep.initialEntry,
    };
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const OnboardingState();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref.watch(onboardingApiServiceProvider));
});
