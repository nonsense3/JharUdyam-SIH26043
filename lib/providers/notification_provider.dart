import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  String? _fcmToken;
  int _notificationIdCounter = 0;
  bool _initialized = false;

  // Polling state
  Timer? _pollTimer;
  final Map<String, String> _knownStatuses = {};
  bool _firstPoll = true;

  // Realtime channel
  RealtimeChannel? _channel;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  String? get fcmToken => _fcmToken;

  /// Initialize the notification system (Local, FCM, Realtime, Polling)
  Future<void> initialize() async {
    if (_initialized) return;
    _deviceId = await DeviceService.getDeviceId();
    await _initLocalNotifications();
    await _initFirebaseMessaging();

    // Seed database state silently for polling
    await _seedInitialState();

    // Start polling every 30s as a reliable fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollForChanges());

    // Subscribe to Supabase Realtime for instant updates
    _subscribeToRealtime();

    _initialized = true;
    debugPrint('[NotificationProvider] Initialized. Device ID: $_deviceId, FCM: $_fcmToken');
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
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> _initFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('[FCM] User granted permission: ${settings.authorizationStatus}');

      // Get FCM device registration token
      _fcmToken = await messaging.getToken();
      debugPrint('[FCM] Token: $_fcmToken');

      // Subscribe to global civic topics
      await messaging.subscribeToTopic('all_problems');
      await messaging.subscribeToTopic('civic_updates');
      debugPrint('[FCM] Subscribed to topics: all_problems, civic_updates');

      // Handle foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Got message: ${message.messageId}');
        final title = message.notification?.title ?? message.data['title'] ?? 'JharUdyam Alert';
        final body = message.notification?.body ?? message.data['body'] ?? 'You have a new civic update.';

        _addNotification(
          title: title,
          body: body,
          type: message.data['type'] ?? 'status_change',
        );
      });

      // Handle notification taps when app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM OpenedApp] Message clicked: ${message.messageId}');
      });

      // Handle token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('[FCM] Token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('[FCM] Setup error: $e');
    }
  }

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
      debugPrint('[NotificationProvider] Seed error: $e');
      _firstPoll = false;
    }
  }

  Future<void> _pollForChanges() async {
    if (_firstPoll) return;
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
          // New problem
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
          // Status changed
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

      _knownStatuses.removeWhere((id, _) => !currentIds.contains(id));
    } catch (e) {
      debugPrint('[NotificationProvider] Poll error: $e');
    }
  }

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
              final record = payload.newRecord;
              final reporterId = record['reporter_id']?.toString() ?? '';
              if (reporterId == _deviceId) return;

              final id = record['id']?.toString() ?? '';
              if (_knownStatuses.containsKey(id)) return;

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
              final record = payload.newRecord;
              final id = record['id']?.toString() ?? '';
              final newStatus = record['status']?.toString() ?? '';

              if (_knownStatuses[id] == newStatus) return;

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
          .subscribe();
    } catch (e) {
      debugPrint('[NotificationProvider] Realtime setup error: $e');
    }
  }

  void _addNotification({required String title, required String body, required String type}) {
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
