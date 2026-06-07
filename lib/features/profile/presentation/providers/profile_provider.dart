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

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.profile,
    this.profileCreated = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    UserProfileDetails? profile,
    bool? profileCreated,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profile: profile ?? this.profile,
      profileCreated: profileCreated ?? this.profileCreated,
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

  Future<bool> createProfile(CreateProfileRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
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
