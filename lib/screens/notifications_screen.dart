import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updates', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => provider.markAllRead(),
                child: const Text('Mark all read', style: TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No updates yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text('You\'ll be notified when new reports are filed\nor when report statuses change.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.5)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notifications.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notif = provider.notifications[index];
              final isNew = notif.type == 'new_report';
              final timeDiff = DateTime.now().difference(notif.timestamp);
              String timeLabel;
              if (timeDiff.inSeconds < 60) { timeLabel = 'just now'; }
              else if (timeDiff.inMinutes < 60) { timeLabel = '${timeDiff.inMinutes}m ago'; }
              else if (timeDiff.inHours < 24) { timeLabel = '${timeDiff.inHours}h ago'; }
              else { timeLabel = '${timeDiff.inDays}d ago'; }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: notif.isRead ? Colors.white : AppTheme.primaryTint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: notif.isRead ? Colors.grey.shade200 : AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: InkWell(
                  onTap: () => provider.markRead(notif.id),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isNew ? AppTheme.primaryTint : const Color(0xFFE8F0FE),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isNew ? Icons.add_circle_outline : Icons.sync,
                          size: 18,
                          color: isNew ? AppTheme.primaryColor : const Color(0xFF3D6B94),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(notif.title, style: TextStyle(fontSize: 14, fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700, color: Colors.black87))),
                                Text(timeLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(notif.body, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
