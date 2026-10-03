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


// ── In-app notification feed ────────────────────────────────────────────────

@immutable
class InAppFeedState {
  final bool isLoading;
  final String? error;
  final List<InAppNotification> items;
  final int unreadCount;
  final int totalCount;

  /// True once a load has completed, so the UI can tell "nothing yet" from
  /// "nothing here" and avoid flashing an empty state on first paint.
  final bool loaded;

  const InAppFeedState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.unreadCount = 0,
    this.totalCount = 0,
    this.loaded = false,
  });

  InAppFeedState copyWith({
    bool? isLoading,
    String? error,
    List<InAppNotification>? items,
    int? unreadCount,
    int? totalCount,
    bool? loaded,
  }) =>
      InAppFeedState(
        isLoading: isLoading ?? this.isLoading,
        // Deliberately not preserved: each load decides afresh.
        error: error,
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        totalCount: totalCount ?? this.totalCount,
        loaded: loaded ?? this.loaded,
      );
}

/// Loads the in-app feed and keeps read/delete state in step with the server.
///
/// Read and delete are applied locally first so the list reacts immediately,
/// and rolled back if the call fails — the alternative is a row that sits
/// unchanged for a round trip and feels broken.
class InAppNotificationsNotifier extends StateNotifier<InAppFeedState> {
  InAppNotificationsNotifier(this._api) : super(const InAppFeedState());

  final NotificationApiService _api;

  Future<void> load({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    final res = await _api.getInAppFeed(pageSize: 50);
    if (!mounted) return;
    if (res.isSuccess && res.data != null) {
      final feed = res.data!;
      state = state.copyWith(
        isLoading: false,
        loaded: true,
        items: feed.notifications,
        unreadCount: feed.unreadCount,
        totalCount: feed.totalCount,
      );
      return;
    }
    state = state.copyWith(
      isLoading: false,
      loaded: true,
      error: res.errorMessage,
    );
  }

  /// Just the badge number. The bell needs it on every home screen build,
  /// and pulling the whole feed for that would be wasteful.
  Future<void> refreshUnreadCount() async {
    final res = await _api.getUnreadCount();
    if (!mounted || !res.isSuccess || res.data == null) return;
    state = state.copyWith(unreadCount: res.data!);
  }

  Future<void> markRead(String id) async {
    final before = state.items;
    final idx = before.indexWhere((n) => n.id == id);
    if (idx < 0 || before[idx].isRead) return;

    final optimistic = [...before]
      ..[idx] = before[idx].copyWith(isRead: true, readAt: DateTime.now());
    state = state.copyWith(
      items: optimistic,
      unreadCount: (state.unreadCount - 1).clamp(0, 1 << 30),
    );

    final res = await _api.markRead(id);
    if (!mounted) return;
    if (!res.isSuccess) {
      state = state.copyWith(
        items: before,
        unreadCount: state.unreadCount + 1,
        error: res.errorMessage,
      );
    }
  }

  Future<void> markAllRead() async {
    final before = state.items;
    final beforeUnread = state.unreadCount;
    if (beforeUnread == 0) return;

    state = state.copyWith(
      items: [
        for (final n in before)
          n.isRead ? n : n.copyWith(isRead: true, readAt: DateTime.now())
      ],
      unreadCount: 0,
    );

    final res = await _api.markAllRead();
    if (!mounted) return;
    if (!res.isSuccess) {
      state = state.copyWith(
        items: before,
        unreadCount: beforeUnread,
        error: res.errorMessage,
      );
    }
  }

  Future<void> remove(String id) async {
    final before = state.items;
    final removed = before.firstWhere((n) => n.id == id,
        orElse: () => throw StateError('no such notification'));

    state = state.copyWith(
      items: before.where((n) => n.id != id).toList(),
      unreadCount: removed.isRead
          ? state.unreadCount
          : (state.unreadCount - 1).clamp(0, 1 << 30),
      totalCount: (state.totalCount - 1).clamp(0, 1 << 30),
    );

    final res = await _api.deleteNotification(id);
    if (!mounted) return;
    if (!res.isSuccess) {
      // Put it back where it was rather than at the end.
      state = state.copyWith(
        items: before,
        unreadCount: removed.isRead ? state.unreadCount : state.unreadCount + 1,
        totalCount: state.totalCount + 1,
        error: res.errorMessage,
      );
    }
  }

  Future<void> clearAll() async {
    final before = state.items;
    final beforeUnread = state.unreadCount;
    final beforeTotal = state.totalCount;
    if (before.isEmpty) return;

    state = state.copyWith(items: const [], unreadCount: 0, totalCount: 0);

    final res = await _api.clearAll();
    if (!mounted) return;
    if (!res.isSuccess) {
      state = state.copyWith(
        items: before,
        unreadCount: beforeUnread,
        totalCount: beforeTotal,
        error: res.errorMessage,
      );
    }
  }
}

final inAppNotificationsProvider =
    StateNotifierProvider<InAppNotificationsNotifier, InAppFeedState>((ref) {
  return InAppNotificationsNotifier(ref.watch(notificationApiServiceProvider));
});

/// Badge count for the bell, kept in step with the feed once it is loaded.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(inAppNotificationsProvider).unreadCount;
});
