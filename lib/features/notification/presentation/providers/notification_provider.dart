import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notification_api_service.dart';
import '../../data/notification_dtos.dart';

/// State for notification operations.
@immutable
class NotificationState {
  final bool isLoading;
  final String? error;
  final SendSmsResponse? smsResult;
  final SendPushNotificationResponse? pushResult;
  final List<DeviceTokenDto> registeredDevices;

  const NotificationState({
    this.isLoading = false,
    this.error,
    this.smsResult,
    this.pushResult,
    this.registeredDevices = const [],
  });

  NotificationState copyWith({
    bool? isLoading,
    String? error,
    SendSmsResponse? smsResult,
    SendPushNotificationResponse? pushResult,
    List<DeviceTokenDto>? registeredDevices,
    bool clearSmsResult = false,
    bool clearPushResult = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      smsResult: clearSmsResult ? null : (smsResult ?? this.smsResult),
      pushResult:
          clearPushResult ? null : (pushResult ?? this.pushResult),
      registeredDevices:
          registeredDevices ?? this.registeredDevices,
    );
  }
}

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService();
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this._api) : super(const NotificationState());

  final NotificationApiService _api;

  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
    String? senderId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, clearSmsResult: true);
    final res = await _api.sendSms(SendSmsRequest(
      phoneNumber: phoneNumber,
      message: message,
      senderId: senderId,
    ));
    if (res.isSuccess && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        smsResult: res.data,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  Future<bool> sendPush({
    required List<DeviceTokenDto> deviceTokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    state =
        state.copyWith(isLoading: true, error: null, clearPushResult: true);
    final res = await _api.sendPush(SendPushNotificationRequest(
      deviceTokens: deviceTokens,
      title: title,
      body: body,
      data: data,
    ));
    if (res.isSuccess && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        pushResult: res.data,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  Future<bool> registerDevice({
    required String userId,
    required String token,
    required String platform,
    String? appId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.registerDevice(
      userId: userId,
      deviceToken: DeviceTokenDto(
        token: token,
        platform: platform,
        appId: appId,
      ),
    );
    if (res.isSuccess) {
      state = state.copyWith(isLoading: false);
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  Future<bool> unregisterDevice({
    required String userId,
    required String token,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.unregisterDevice(userId: userId, token: token);
    if (res.isSuccess) {
      state = state.copyWith(isLoading: false);
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.errorMessage);
    return false;
  }

  Future<void> loadDevices(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _api.getUserDevices(userId);
    if (res.isSuccess && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        registeredDevices: res.data!,
      );
    } else {
      state = state.copyWith(isLoading: false, error: res.errorMessage);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const NotificationState();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.watch(notificationApiServiceProvider));
});
