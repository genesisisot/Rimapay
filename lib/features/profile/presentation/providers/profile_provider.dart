import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_api_service.dart';
import '../../data/profile_dtos.dart';

@immutable
class ProfileState {
  final bool isLoading;
  final String? error;
  final UserProfileDetails? profile;
  final bool profileCreated;
  final bool addressCompleted;
  final bool pepCompleted;
  final bool sourceOfIncomeCompleted;
  final bool mockMode;

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.profile,
    this.profileCreated = false,
    this.addressCompleted = false,
    this.pepCompleted = false,
    this.sourceOfIncomeCompleted = false,
    this.mockMode = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    UserProfileDetails? profile,
    bool? profileCreated,
    bool? addressCompleted,
    bool? pepCompleted,
    bool? sourceOfIncomeCompleted,
    bool? mockMode,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profile: profile ?? this.profile,
      profileCreated: profileCreated ?? this.profileCreated,
      addressCompleted: addressCompleted ?? this.addressCompleted,
      pepCompleted: pepCompleted ?? this.pepCompleted,
      sourceOfIncomeCompleted:
          sourceOfIncomeCompleted ?? this.sourceOfIncomeCompleted,
      mockMode: mockMode ?? this.mockMode,
    );
  }
}

final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  return ProfileApiService();
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._api) : super(const ProfileState());

  final ProfileApiService _api;

  Future<bool> fetchMyProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    final profile = await _api.getMyProfile();
    if (profile != null) {
      state = ProfileState(
        isLoading: false,
        profile: profile,
        profileCreated: true,
      );
      return true;
    }
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<bool> fetchProfileByIdentity(String identityUserId) async {
    state = state.copyWith(isLoading: true, error: null);
    final profile = await _api.getProfileByIdentity(identityUserId);
    if (profile != null) {
      state = ProfileState(
        isLoading: false,
        profile: profile,
        profileCreated: true,
      );
      return true;
    }
    state = state.copyWith(isLoading: false);
    return false;
  }

  void setMockMode(bool v) {
    state = state.copyWith(mockMode: v);
  }

  Future<bool> createProfile(CreateProfileRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    if (state.mockMode) {
      state = state.copyWith(
        isLoading: false,
        profileCreated: true,
      );
      return true;
    }

    final res = await _api.create(request);
    if (res.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        profileCreated: true,
      );
      return true;
    }
    state = state.copyWith(
      isLoading: false,
      error: res.errorMessage ?? res.errorCode ?? 'Profile creation failed.',
    );
    return false;
  }

  Future<bool> completeAddress(AddressCompletionRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.completeAddress(request);
    state = state.copyWith(isLoading: false);
    if (res.isSuccess) {
      state = state.copyWith(addressCompleted: true);
      return true;
    }
    state = state.copyWith(error: res.errorMessage ?? 'Failed to save address.');
    return false;
  }

  Future<bool> completePep(PepCompletionRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.completePep(request);
    state = state.copyWith(isLoading: false);
    if (res.isSuccess) {
      state = state.copyWith(pepCompleted: true);
      return true;
    }
    state = state.copyWith(error: res.errorMessage ?? 'Failed to save PEP declaration.');
    return false;
  }

  Future<bool> completeSourceOfIncome(SourceOfIncomeRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.completeSourceOfIncome(request);
    state = state.copyWith(isLoading: false);
    if (res.isSuccess) {
      state = state.copyWith(sourceOfIncomeCompleted: true);
      return true;
    }
    state = state.copyWith(error: res.errorMessage ?? 'Failed to save income details.');
    return false;
  }

  Future<void> fetchCompletionStatus() async {
    final status = await _api.getCompletionStatus();
    if (status != null) {
      state = state.copyWith(
        addressCompleted: status.residentialAddressProvided,
        pepCompleted: status.isPepDeclared == true,
        sourceOfIncomeCompleted: status.sourceOfIncomeProvided,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const ProfileState();
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(profileApiServiceProvider));
});
