import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';

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

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> notifications = [
    NotificationModel(
      id: '1',
      title: 'Payment Successful',
      message: 'Your airtime purchase of ₦1,000 to 08012345678 was successful',
      time: '2 minutes ago',
      type: NotificationType.transaction,
      isRead: false,
      icon: '✅',
    ),
    NotificationModel(
      id: '2',
      title: 'New Feature Available',
      message:
          'Loan services are now available in your RimaPay app. Apply for instant loans up to ₦500,000',
      time: '1 hour ago',
      type: NotificationType.promotion,
      isRead: false,
      icon: '🎉',
    ),
    NotificationModel(
      id: '3',
      title: 'Money Received',
      message:
          'You received ₦25,000 from Adebayo Okafor with reference: Split dinner bill',
      time: '3 hours ago',
      type: NotificationType.transaction,
      isRead: true,
      icon: '💰',
    ),
    NotificationModel(
      id: '4',
      title: 'Security Alert',
      message:
          'New device login detected from Lagos, Nigeria. If this wasn\'t you, please secure your account.',
      time: '1 day ago',
      type: NotificationType.security,
      isRead: true,
      icon: '🔒',
    ),
    NotificationModel(
      id: '5',
      title: 'System Maintenance',
      message:
          'Scheduled maintenance on Sunday 2AM - 4AM. Some services may be temporarily unavailable.',
      time: '2 days ago',
      type: NotificationType.system,
      isRead: true,
      icon: '⚙️',
    ),
    NotificationModel(
      id: '6',
      title: 'Cashback Earned',
      message:
          'You earned ₦50 cashback from your electricity bill payment. Total cashback this month: ₦350',
      time: '3 days ago',
      type: NotificationType.promotion,
      isRead: true,
      icon: '🎁',
    ),
  ];

  String _filter = 'all';

  List<NotificationModel> get _filteredNotifications {
    return notifications
        .where((n) => _filter == 'all' ? true : !n.isRead)
        .toList();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  void _markAsRead(String id) {
    setState(() {
      final i = notifications.indexWhere((n) => n.id == id);
      if (i != -1) notifications[i].isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in notifications) {
        n.isRead = true;
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() => notifications.removeWhere((n) => n.id == id));
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
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 17),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Effra',
                  ),
                ),
                if (unreadCount > 0)
                  Text(
                    '$unreadCount unread',
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
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: Colors.white,
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
      color: Colors.white,
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
                        : const Color(0xFF98A2B3),
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
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filter == 'unread'
                  ? 'You have no unread notifications'
                  : 'Notifications will appear here',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF667085), fontFamily: 'Effra'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredNotifications.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1, indent: 72, endIndent: 16, color: Color(0xFFE4E7EC)),
      itemBuilder: (_, i) => _buildItem(_filteredNotifications[i]),
    );
  }

  Widget _buildItem(NotificationModel n) {
    final accent = _typeAccent(n.type);
    return Container(
      color: n.isRead ? Colors.white : const Color(0xFF166C46).withOpacity(0.03),
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
                  style: const TextStyle(fontSize: 19),
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
                            color: const Color(0xFF101828),
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF667085),
                      height: 1.4,
                      fontFamily: 'Effra',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        n.time,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF98A2B3)),
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
                            child: const Text(
                              'Mark read',
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
                            color: const Color(0xFFFEF2F2),
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
