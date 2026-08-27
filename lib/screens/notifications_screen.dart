import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _showClearAllDialog(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Updates?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('This will remove all notification records from your device.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All updates cleared'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

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
              if (provider.notifications.isEmpty) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.unreadCount > 0)
                    TextButton(
                      onPressed: () => provider.markAllRead(),
                      child: const Text('Mark read', style: TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFDC2626), size: 22),
                    tooltip: 'Clear All',
                    onPressed: () => _showClearAllDialog(context, provider),
                  ),
                  const SizedBox(width: 4),
                ],
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
                  onTap: () {
                    provider.markRead(notif.id);
                    if (notif.problemId != null || notif.ticketNo != null) {
                      provider.navigateToProblem(
                        problemId: notif.problemId,
                        ticketNo: notif.ticketNo,
                      );
                    }
                  },
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
                      if (notif.problemId != null || notif.ticketNo != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
                      ],
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

