import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import 'notification/data/notification_dtos.dart';
import 'notification/presentation/providers/notification_provider.dart';

import '../core/localization/l10n.dart';
// Notification model
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  bool isRead;
  final String? icon;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
    this.icon,
  });
}

enum NotificationType {
  transaction,
  system,
  promotion,
  security,
}

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  /// Which tab is showing: all notifications, or unread only.
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    // After the first frame so the provider can be read safely.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(inAppNotificationsProvider.notifier).load());
  }

  /// The feed, in the shape this screen already renders.
  List<NotificationModel> get notifications => ref
      .watch(inAppNotificationsProvider)
      .items
      .map(_toModel)
      .toList(growable: false);

  NotificationModel _toModel(InAppNotification n) => NotificationModel(
        id: n.id,
        title: (n.title ?? '').isEmpty ? 'Notification' : n.title!,
        message: n.body ?? '',
        time: _relativeTime(n.createdOn),
        type: _typeFor(n.category),
        isRead: n.isRead,
        icon: _iconFor(n.category),
      );

  NotificationType _typeFor(NotificationCategory c) {
    switch (c) {
      case NotificationCategory.payment:
      case NotificationCategory.moneyReceived:
      case NotificationCategory.cashback:
        return NotificationType.transaction;
      case NotificationCategory.promotion:
        return NotificationType.promotion;
      case NotificationCategory.security:
        return NotificationType.security;
      case NotificationCategory.system:
      case NotificationCategory.general:
        return NotificationType.system;
    }
  }

  String _iconFor(NotificationCategory c) {
    switch (c) {
      case NotificationCategory.payment:
        return '✅';
      case NotificationCategory.moneyReceived:
        return '💰';
      case NotificationCategory.promotion:
        return '🎉';
      case NotificationCategory.security:
        return '🔒';
      case NotificationCategory.cashback:
        return '🎁';
      case NotificationCategory.system:
        return '⚙️';
      case NotificationCategory.general:
        return '📢';
    }
  }

  /// "2 minutes ago" and friends; falls back to a date once it is old enough
  /// that a relative label stops being useful.
  String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) {
      return '${d.inMinutes} minute${d.inMinutes == 1 ? '' : 's'} ago';
    }
    if (d.inHours < 24) {
      return '${d.inHours} hour${d.inHours == 1 ? '' : 's'} ago';
    }
    if (d.inDays < 7) {
      return '${d.inDays} day${d.inDays == 1 ? '' : 's'} ago';
    }
    return '${t.day}/${t.month}/${t.year}';
  }

  List<NotificationModel> get _filteredNotifications {
    return notifications
        .where((n) => _filter == 'all' ? true : !n.isRead)
        .toList();
  }

  int get unreadCount =>
      ref.watch(inAppNotificationsProvider).unreadCount;

  void _markAsRead(String id) =>
      ref.read(inAppNotificationsProvider.notifier).markRead(id);

  void _markAllAsRead() =>
      ref.read(inAppNotificationsProvider.notifier).markAllRead();

  void _deleteNotification(String id) =>
      ref.read(inAppNotificationsProvider.notifier).remove(id);

  /// Opens the notification in a sheet, and marks it read on the way — the
  /// list row is too short for a long message.
  void _openNotification(NotificationModel n, Color accent) {
    HapticFeedback.lightImpact();
    if (!n.isRead) _markAsRead(n.id);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(n.icon ?? '📢',
                                    style: const TextStyle(fontSize: 21)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Effra',
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    n.time,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Effra',
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          n.message,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.55,
                            fontFamily: 'Effra',
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.78),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _deleteNotification(n.id);
                          },
                          icon: const Icon(Icons.delete_outline, size: 17),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD33B31),
                            minimumSize: const Size.fromHeight(46),
                            side: const BorderSide(color: Color(0x33D33B31)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          label: const Text('Delete',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary500,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Done',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _typeAccent(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return const Color(0xFF166C46);
      case NotificationType.promotion:
        return const Color(0xFF3B82F6);
      case NotificationType.security:
        return const Color(0xFFD33B31);
      case NotificationType.system:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilterTabs(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: Theme.of(context).cardColor, size: 17),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.notifications,
                  style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Effra',
                  ),
                ),
                if (unreadCount > 0)
                  Text(context.l10n.unreadcountUnread(unreadCount),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (unreadCount > 0)
            GestureDetector(
              onTap: _markAllAsRead,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: Text(context.l10n.markAllRead,
                  style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Theme.of(context).cardColor,
      child: Row(
        children: ['all', 'unread'].map((tab) {
          final selected = _filter == tab;
          final label = tab == 'all'
              ? 'All (${notifications.length})'
              : 'Unread ($unreadCount)';
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? AppColors.goldPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Effra',
                    color: selected
                        ? AppColors.goldPrimary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    final feed = ref.watch(inAppNotificationsProvider);

    if (feed.isLoading && !feed.loaded) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF166C46)));
    }

    if (feed.error != null && feed.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 34, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 14),
              Text(
                feed.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Effra',
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.read(inAppNotificationsProvider.notifier).load(),
                child: const Text('Try again',
                    style: TextStyle(
                        color: Color(0xFF166C46), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF166C46).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 36, color: Color(0xFF166C46)),
            ),
            const SizedBox(height: 16),
            Text(
              _filter == 'unread' ? 'All caught up!' : 'No notifications',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filter == 'unread'
                  ? 'You have no unread notifications'
                  : 'Notifications will appear here',
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontFamily: 'Effra'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF166C46),
      onRefresh: () =>
          ref.read(inAppNotificationsProvider.notifier).load(silent: true),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredNotifications.length,
        separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: Theme.of(context).dividerColor),
        itemBuilder: (_, i) => _buildItem(_filteredNotifications[i]),
      ),
    );
  }

  Widget _buildItem(NotificationModel n) {
    final accent = _typeAccent(n.type);
    return GestureDetector(
      onTap: () => _openNotification(n, accent),
      behavior: HitTestBehavior.opaque,
      child: _buildItemBody(n, accent),
    );
  }

  Widget _buildItemBody(NotificationModel n, Color accent) {
    return Container(
      color: n.isRead ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  n.icon ?? '📢',
                  style: TextStyle(fontSize: 19),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                n.isRead ? FontWeight.w600 : FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: 'Effra',
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4, left: 4),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      height: 1.4,
                      fontFamily: 'Effra',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        n.time,
                        style: TextStyle(
                            fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                      ),
                      const Spacer(),
                      if (!n.isRead)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _markAsRead(n.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF166C46).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(context.l10n.markRead,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF166C46),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _deleteNotification(n.id);
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 15, color: Color(0xFFD33B31)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
