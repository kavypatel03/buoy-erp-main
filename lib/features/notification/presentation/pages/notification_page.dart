import 'package:flutter/material.dart';
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
      // Mark all as read optionally here
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Top Header Bar with Back Arrow Tap
              ErpHeaderBar(
                title: 'Notification',
                isNotificationActive: true,
                onBackTap: () => Navigator.pop(context),
              ),

              const SizedBox(height: 16),

            // Notification List Content
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3DF5)))
                  : _error.isNotEmpty 
                  ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                  : _notifications.isEmpty 
                  ? const Center(child: Text('No notifications yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 40.0, left: 20, right: 20, top: 10),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassContainer(
                            useGradientBorder: true,
                            borderRadius: 16,
                            padding: const EdgeInsets.all(18),
                            child: _buildNotificationItem(
                              title: notif['title'] ?? 'Notification',
                              message: notif['message'] ?? '',
                              isRead: notif['is_read'] ?? true,
                              date: notif['created_at'],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required bool isRead,
    required String? date,
  }) {
    String formattedDate = '';
    if (date != null) {
      try {
        final dt = DateTime.parse(date).toLocal();
        formattedDate = DateFormat('MMM dd, hh:mm a').format(dt);
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
            color: isRead ? Colors.transparent : const Color(0xFF5B3DF5),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              if (formattedDate.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}


