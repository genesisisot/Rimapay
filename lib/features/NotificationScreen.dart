import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
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
      message: 'Loan services are now available in your RimaPay app. Apply for instant loans up to ₦500,000',
      time: '1 hour ago',
      type: NotificationType.promotion,
      isRead: false,
      icon: '🎉',
    ),
    NotificationModel(
      id: '3',
      title: 'Money Received',
      message: 'You received ₦25,000 from Adebayo Okafor with reference: Split dinner bill',
      time: '3 hours ago',
      type: NotificationType.transaction,
      isRead: true,
      icon: '💰',
    ),
    NotificationModel(
      id: '4',
      title: 'Security Alert',
      message: 'New device login detected from Lagos, Nigeria. If this wasn\'t you, please secure your account.',
      time: '1 day ago',
      type: NotificationType.security,
      isRead: true,
      icon: '🔒',
    ),
    NotificationModel(
      id: '5',
      title: 'System Maintenance',
      message: 'Scheduled maintenance on Sunday 2AM - 4AM. Some services may be temporarily unavailable.',
      time: '2 days ago',
      type: NotificationType.system,
      isRead: true,
      icon: '⚙️',
    ),
    NotificationModel(
      id: '6',
      title: 'Cashback Earned',
      message: 'You earned ₦50 cashback from your electricity bill payment. Total cashback this month: ₦350',
      time: '3 days ago',
      type: NotificationType.promotion,
      isRead: true,
      icon: '🎁',
    ),
  ];

  String filter = 'all'; // 'all' or 'unread'
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  List<NotificationModel> get filteredNotifications {
    return notifications.where((notification) {
      return filter == 'all' ? true : !notification.isRead;
    }).toList();
  }

  int get unreadCount {
    return notifications.where((n) => !n.isRead).length;
  }

  Color getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return Colors.green.shade100;
      case NotificationType.promotion:
        return Colors.blue.shade100;
      case NotificationType.security:
        return Colors.red.shade100;
      case NotificationType.system:
        return Colors.yellow.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getNotificationTypeTextColor(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return Colors.green.shade700;
      case NotificationType.promotion:
        return Colors.blue.shade700;
      case NotificationType.security:
        return Colors.red.shade700;
      case NotificationType.system:
        return Colors.yellow.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return '💳';
      case NotificationType.promotion:
        return '🎁';
      case NotificationType.security:
        return '🔒';
      case NotificationType.system:
        return '⚙️';
      default:
        return '📢';
    }
  }

  void markAsRead(String id) {
    setState(() {
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        notifications[index].isRead = true;
      }
    });
  }

  void markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });
  }

  void deleteNotification(String id) {
    setState(() {
      notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Backdrop
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          
          // Notification Panel
          SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: const BoxConstraints(maxWidth: 320),
                height: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.2),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Notifications',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (unreadCount > 0)
                                          Text(
                                            '$unreadCount new notification${unreadCount > 1 ? 's' : ''}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    GestureDetector(
                                      onTap: markAllAsRead,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00B252),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Mark All Read',
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
                            ),
                            
                            // Filter Tabs
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade100,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => filter = 'all'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: filter == 'all'
                                                  ? const Color(0xFF00B252)
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'All (${notifications.length})',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: filter == 'all'
                                                ? const Color(0xFF00B252)
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => filter = 'unread'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: filter == 'unread'
                                                  ? const Color(0xFF00B252)
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Unread ($unreadCount)',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: filter == 'unread'
                                                ? const Color(0xFF00B252)
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Notification List
                    Expanded(
                      child: filteredNotifications.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              itemCount: filteredNotifications.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: Colors.grey.shade100,
                              ),
                              itemBuilder: (context, index) {
                                final notification = filteredNotifications[index];
                                return _buildNotificationItem(notification);
                              },
                            ),
                    ),
                    
                    // Footer
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                foregroundColor: Colors.grey.shade800,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.notifications_none,
                size: 32,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filter == 'unread' ? 'All caught up!' : 'No notifications',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'unread'
                  ? 'You have no unread notifications'
                  : 'When you have notifications, they\'ll appear here',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      color: !notification.isRead 
          ? Colors.blue.shade50.withOpacity(0.3) 
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: getNotificationTypeColor(notification.type),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: getNotificationTypeColor(notification.type),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  notification.icon ?? getNotificationTypeIcon(notification.type),
                  style: const TextStyle(fontSize: 18),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: !notification.isRead 
                                    ? Colors.black87 
                                    : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: !notification.isRead 
                                    ? Colors.grey.shade700 
                                    : Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  notification.time,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                if (!notification.isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00B252),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Actions
                      Row(
                        children: [
                          if (!notification.isRead)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                markAsRead(notification.id);
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              deleteNotification(notification.id);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
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