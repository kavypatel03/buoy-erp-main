import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final result = await NotificationService.getNotifications();
    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _notifications = result['data'] ?? [];
        _isLoading = false;
      });
      // Mark all as read
      for (var n in _notifications) {
        if (n['is_read'] == false) {
          NotificationService.markAsRead(n['id']);
        }
      }
    } else {
      setState(() {
        _error = result['error'] ?? 'Failed to load notifications';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will remove all current notifications.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await NotificationService.clearAll();
    if (result['success']) {
      HapticFeedback.lightImpact();
      setState(() => _notifications.clear());
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to clear notifications')),
      );
    }
  }

  Future<void> _deleteNotification(String id) async {
    final result = await NotificationService.deleteNotification(id);
    if (result['success']) {
      HapticFeedback.lightImpact();
      setState(() {
        _notifications.removeWhere((n) => n['id'] == id);
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to delete notification')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              ErpHeaderBar(
                title: 'Notifications',
                isNotificationActive: true,
                onBackTap: () => Navigator.pop(context),
                trailing: _notifications.isNotEmpty
                    ? TextButton.icon(
                        onPressed: _clearAllNotifications,
                        icon: const Icon(Icons.clear_all_rounded, size: 18, color: AppColors.error),
                        label: const Text(
                          'Clear',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: AppColors.error.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 8),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(_error, style: const TextStyle(color: AppColors.error)),
                            ),
                          )
                        : _notifications.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                        child: const Icon(
                                          Icons.notifications_none_rounded,
                                          color: AppColors.primary,
                                          size: 36,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'All caught up!',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'You have no unread notifications or alerts.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                color: AppColors.primary,
                                onRefresh: _fetchNotifications,
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                                  itemCount: _notifications.length,
                                  itemBuilder: (context, index) {
                                    final notif = _notifications[index];
                                    return RepaintBoundary(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: GlassContainer(
                                          borderRadius: 18,
                                          padding: const EdgeInsets.all(16),
                                          child: _buildNotificationItem(
                                            id: notif['id'],
                                            title: notif['title'] ?? 'Notification',
                                            message: notif['message'] ?? '',
                                            isRead: notif['is_read'] ?? true,
                                            date: notif['created_at'],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String id,
    required String title,
    required String message,
    required bool isRead,
    required String? date,
  }) {
    String formattedDate = '';
    if (date != null) {
      try {
        final dt = DateTime.parse(date).toLocal();
        formattedDate = DateFormat('MMM dd · hh:mm a').format(dt);
      } catch (e) {
        formattedDate = '';
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6, right: 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRead ? Colors.transparent : AppColors.primary,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              if (formattedDate.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _deleteNotification(id),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
