import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jharudyam_citizen/services/supabase_service.dart';
import 'package:jharudyam_citizen/services/device_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'new_report' or 'status_change'
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class NotificationProvider extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final List<NotificationItem> _notifications = [];
  RealtimeChannel? _channel;
  String? _deviceId;
  int _notificationIdCounter = 0;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initialize the notification system
  Future<void> initialize() async {
    _deviceId = await DeviceService.getDeviceId();
    await _initLocalNotifications();
    _subscribeToRealtime();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(initSettings);

    // Request Android 13+ notification permission
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _subscribeToRealtime() {
    _channel = SupabaseService.client.channel('problems-changes');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'problems',
          callback: (payload) => _handleInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'problems',
          callback: (payload) => _handleUpdate(payload.oldRecord, payload.newRecord),
        )
        .subscribe();
  }

  void _handleInsert(Map<String, dynamic> record) {
    final reporterId = record['reporter_id']?.toString() ?? '';
    // Don't notify for own reports
    if (reporterId == _deviceId) return;

    final title = record['title']?.toString() ?? 'New Report';
    final category = record['category']?.toString() ?? '';
    final ticketNo = record['ticket_no']?.toString() ?? '';

    final item = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Civic Report',
      body: '$title${category.isNotEmpty ? ' · $category' : ''}${ticketNo.isNotEmpty ? ' ($ticketNo)' : ''}',
      timestamp: DateTime.now(),
      type: 'new_report',
    );

    _notifications.insert(0, item);
    _showSystemNotification(item.title, item.body);
    notifyListeners();
  }

  void _handleUpdate(Map<String, dynamic> oldRecord, Map<String, dynamic> newRecord) {
    final oldStatus = oldRecord['status']?.toString() ?? '';
    final newStatus = newRecord['status']?.toString() ?? '';

    if (oldStatus == newStatus) return; // Not a status change

    final title = newRecord['title']?.toString() ?? 'Report Update';
    final ticketNo = newRecord['ticket_no']?.toString() ?? '';
    final statusLabel = newStatus.replaceAll('_', ' ');

    final item = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Status Updated',
      body: '${ticketNo.isNotEmpty ? '$ticketNo: ' : ''}$title → ${statusLabel[0].toUpperCase()}${statusLabel.substring(1)}',
      timestamp: DateTime.now(),
      type: 'status_change',
    );

    _notifications.insert(0, item);
    _showSystemNotification(item.title, item.body);
    notifyListeners();
  }

  Future<void> _showSystemNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'jharudyam_updates',
      'JharUdyam Updates',
      channelDescription: 'Civic report updates and new submissions',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(presentSound: true);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(_notificationIdCounter++, title, body, details);
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markRead(String id) {
    final n = _notifications.where((n) => n.id == id).firstOrNull;
    if (n != null) {
      n.isRead = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
