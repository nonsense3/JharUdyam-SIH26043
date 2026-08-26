import 'dart:async';
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
  String? _deviceId;
  int _notificationIdCounter = 0;
  bool _initialized = false;

  // Polling state
  Timer? _pollTimer;
  // Track known problem statuses to detect changes
  final Map<String, String> _knownStatuses = {};
  bool _firstPoll = true;

  // Realtime (bonus layer, may or may not work)
  RealtimeChannel? _channel;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initialize the notification system
  Future<void> initialize() async {
    if (_initialized) return;
    _deviceId = await DeviceService.getDeviceId();
    await _initLocalNotifications();

    // Do first poll silently (seed known statuses without notifying)
    await _seedInitialState();

    // Start polling every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollForChanges());

    // Also try Realtime as a bonus (instant delivery if it works)
    _subscribeToRealtime();

    _initialized = true;
    debugPrint('[NotificationProvider] Initialized. Device ID: $_deviceId');
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

    // Explicitly create notification channel for Android 8+
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        'jharudyam_alerts_v2',
        'JharUdyam Alerts',
        description: 'Civic report updates and new submissions',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );
      await androidPlugin.createNotificationChannel(channel);

      // Request Android 13+ notification permission
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('[NotificationProvider] Notification permission granted: $granted');
    }
  }

  /// Seed initial state: load all current problems and their statuses
  /// so the first real poll only detects NEW changes.
  Future<void> _seedInitialState() async {
    try {
      final response = await SupabaseService.client
          .from('problems')
          .select('id, status')
          .order('created_at', ascending: false);

      for (final row in (response as List)) {
        final id = row['id']?.toString() ?? '';
        final status = row['status']?.toString() ?? '';
        if (id.isNotEmpty) {
          _knownStatuses[id] = status;
        }
      }
      _firstPoll = false;
      debugPrint('[NotificationProvider] Seeded ${_knownStatuses.length} problems.');
    } catch (e) {
      debugPrint('[NotificationProvider] Seed failed: $e');
      _firstPoll = false;
    }
  }

  /// Poll for new problems and status changes
  Future<void> _pollForChanges() async {
    if (_firstPoll) return; // Wait for seed to complete
    try {
      final response = await SupabaseService.client
          .from('problems')
          .select()
          .order('created_at', ascending: false);

      final currentIds = <String>{};

      for (final row in (response as List)) {
        final id = row['id']?.toString() ?? '';
        final status = row['status']?.toString() ?? '';
        final reporterId = row['reporter_id']?.toString() ?? '';
        if (id.isEmpty) continue;
        currentIds.add(id);

        if (!_knownStatuses.containsKey(id)) {
          // --- NEW PROBLEM ---
          debugPrint('[NotificationProvider] Poll: new problem detected: $id');
          // Don't notify for own reports
          if (reporterId != _deviceId) {
            final title = row['title']?.toString() ?? 'New Report';
            final category = row['category']?.toString() ?? '';
            final ticketNo = row['ticket_no']?.toString() ?? '';

            _addNotification(
              title: 'New Civic Report',
              body: '$title${category.isNotEmpty ? ' · $category' : ''}${ticketNo.isNotEmpty ? ' ($ticketNo)' : ''}',
              type: 'new_report',
            );
          }
          _knownStatuses[id] = status;
        } else if (_knownStatuses[id] != status) {
          // --- STATUS CHANGED ---
          final oldStatus = _knownStatuses[id]!;
          debugPrint('[NotificationProvider] Poll: status change $oldStatus → $status for $id');

          final title = row['title']?.toString() ?? 'Report Update';
          final ticketNo = row['ticket_no']?.toString() ?? '';
          final statusLabel = _formatStatus(status);

          String notifBody;
          if (status == 'rejected') {
            final reason = row['rejection_reason']?.toString() ?? '';
            notifBody = '${ticketNo.isNotEmpty ? '$ticketNo: ' : ''}$title → Rejected${reason.isNotEmpty ? ' — $reason' : ''}';
          } else {
            notifBody = '${ticketNo.isNotEmpty ? '$ticketNo: ' : ''}$title → $statusLabel';
          }

          _addNotification(
            title: 'Status Updated',
            body: notifBody,
            type: 'status_change',
          );
          _knownStatuses[id] = status;
        }
      }

      // Clean up deleted problems from known list
      _knownStatuses.removeWhere((id, _) => !currentIds.contains(id));

    } catch (e) {
      debugPrint('[NotificationProvider] Poll error: $e');
    }
  }

  void _addNotification({required String title, required String body, required String type}) {
    // Avoid duplicate notifications (same body within last 60 seconds)
    final isDuplicate = _notifications.any((n) =>
        n.body == body &&
        DateTime.now().difference(n.timestamp).inSeconds < 60);
    if (isDuplicate) return;

    final item = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );

    _notifications.insert(0, item);
    _showSystemNotification(title, body);
    notifyListeners();
  }

  // ─── Realtime (bonus layer) ───

  void _subscribeToRealtime() {
    try {
      _channel?.unsubscribe();
      _channel = SupabaseService.client.channel(
        'problems-realtime',
        opts: const RealtimeChannelConfig(self: true),
      );

      _channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'problems',
            callback: (payload) {
              debugPrint('[NotificationProvider] Realtime INSERT received');
              final record = payload.newRecord;
              final reporterId = record['reporter_id']?.toString() ?? '';
              if (reporterId == _deviceId) return;

              final id = record['id']?.toString() ?? '';
              if (_knownStatuses.containsKey(id)) return; // Already handled by poll

              final title = record['title']?.toString() ?? 'New Report';
              final category = record['category']?.toString() ?? '';
              final ticketNo = record['ticket_no']?.toString() ?? '';
              final status = record['status']?.toString() ?? 'submitted';

              _knownStatuses[id] = status;
              _addNotification(
                title: 'New Civic Report',
                body: '$title${category.isNotEmpty ? ' · $category' : ''}${ticketNo.isNotEmpty ? ' ($ticketNo)' : ''}',
                type: 'new_report',
              );
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'problems',
            callback: (payload) {
              debugPrint('[NotificationProvider] Realtime UPDATE received');
              final record = payload.newRecord;
              final id = record['id']?.toString() ?? '';
              final newStatus = record['status']?.toString() ?? '';

              if (_knownStatuses[id] == newStatus) return; // Already handled

              final title = record['title']?.toString() ?? 'Report Update';
              final ticketNo = record['ticket_no']?.toString() ?? '';
              final statusLabel = _formatStatus(newStatus);

              String notifBody;
              if (newStatus == 'rejected') {
                final reason = record['rejection_reason']?.toString() ?? '';
                notifBody = '${ticketNo.isNotEmpty ? '$ticketNo: ' : ''}$title → Rejected${reason.isNotEmpty ? ' — $reason' : ''}';
              } else {
                notifBody = '${ticketNo.isNotEmpty ? '$ticketNo: ' : ''}$title → $statusLabel';
              }

              _knownStatuses[id] = newStatus;
              _addNotification(
                title: 'Status Updated',
                body: notifBody,
                type: 'status_change',
              );
            },
          )
          .subscribe((status, [error]) {
            debugPrint('[NotificationProvider] Realtime status: $status, error: $error');
          });
    } catch (e) {
      debugPrint('[NotificationProvider] Realtime setup failed: $e');
    }
  }

  // ─── Helpers ───

  String _formatStatus(String status) {
    switch (status) {
      case 'submitted': return 'Submitted';
      case 'under_review': return 'Under Review';
      case 'government_handling': return 'Accepted';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'released': return 'Released';
      case 'interest_expressed': return 'Interest Expressed';
      case 'rejected': return 'Rejected';
      default:
        final label = status.replaceAll('_', ' ');
        return label.isNotEmpty ? '${label[0].toUpperCase()}${label.substring(1)}' : status;
    }
  }

  Future<void> _showSystemNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'jharudyam_alerts_v2',
      'JharUdyam Alerts',
      channelDescription: 'Civic report updates and new submissions',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(_notificationIdCounter++, title, body, details);
    debugPrint('[NotificationProvider] System notification shown: $title — $body');
  }

  /// Fire a test notification to verify system sound & banner
  Future<void> testNotification() async {
    final item = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'JharUdyam Test Alert',
      body: 'Notifications and system sound are working correctly!',
      timestamp: DateTime.now(),
      type: 'status_change',
    );
    _notifications.insert(0, item);
    await _showSystemNotification(item.title, item.body);
    notifyListeners();
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
    _pollTimer?.cancel();
    _channel?.unsubscribe();
    _initialized = false;
    super.dispose();
  }
}

