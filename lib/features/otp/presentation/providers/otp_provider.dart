import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/otp_api_service.dart';
import '../../data/otp_dtos.dart';

/// State for OTP operations.
@immutable
class OtpState {
  final bool isLoading;
  final String? error;
  final String? reference;
  final String? maskedDestination;
  final bool isVerified;

  const OtpState({
    this.isLoading = false,
    this.error,
    this.reference,
    this.maskedDestination,
    this.isVerified = false,
  });

  OtpState copyWith({
    bool? isLoading,
    String? error,
    String? reference,
    String? maskedDestination,
    bool? isVerified,
  }) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      reference: reference ?? this.reference,
      maskedDestination: maskedDestination ?? this.maskedDestination,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

/// Riverpod provider for the OtpApiService.
final otpApiServiceProvider = Provider<OtpApiService>((ref) {
  return OtpApiService();
});

/// StateNotifier that manages OTP generate/verify/resend operations.
class OtpNotifier extends StateNotifier<OtpState> {
  OtpNotifier(this._api) : super(const OtpState());

  final OtpApiService _api;

  Future<bool> generate({
    required String serviceId,
    required OtpPurpose purpose,
    required OtpChannel channel,
    required String identifier,
    String? phoneNumber,
    String? email,
    String? recipientName,
    int? expiryMinutes,
    int? maxAttempts,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.generate(GenerateOtpRequest(
      serviceId: serviceId,
      purpose: purpose,
      channel: channel,
      identifier: identifier,
      phoneNumber: phoneNumber,
      email: email,
      recipientName: recipientName,
      expiryMinutes: expiryMinutes,
      maxAttempts: maxAttempts,
    ));
    if (res.isSuccess && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        reference: res.data!.reference,
        maskedDestination: res.data!.maskedDestination,
        isVerified: false,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  Future<bool> verify({
    required String serviceId,
    required String reference,
    required String code,
    required String identifier,
    required OtpPurpose purpose,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.verify(VerifyOtpRequest(
      serviceId: serviceId,
      reference: reference,
      code: code,
      identifier: identifier,
      purpose: purpose,
    ));
    if (res.isSuccess && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        isVerified: res.data!.isVerified,
      );
      return res.data!.isVerified;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  Future<bool> resend({
    required String serviceId,
    required String reference,
    required String identifier,
    required OtpChannel channel,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.resend(ResendOtpRequest(
      serviceId: serviceId,
      reference: reference,
      identifier: identifier,
      channel: channel,
    ));
    if (res.isSuccess && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        reference: res.data!.reference,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const OtpState();
  }
}

final otpProvider =
    StateNotifierProvider<OtpNotifier, OtpState>((ref) {
  return OtpNotifier(ref.watch(otpApiServiceProvider));
});
