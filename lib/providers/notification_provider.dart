import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jharudyam_citizen/models/problem_model.dart';
import 'package:jharudyam_citizen/services/problem_repository.dart';
import 'package:jharudyam_citizen/services/supabase_service.dart';
import 'package:jharudyam_citizen/services/device_service.dart';
import 'package:jharudyam_citizen/screens/problem_detail_screen.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'new_report' or 'status_change'
  final String? problemId;
  final String? ticketNo;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.problemId,
    this.ticketNo,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'problemId': problemId,
    'ticketNo': ticketNo,
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
        : DateTime.now(),
    type: json['type']?.toString() ?? 'status_change',
    problemId: json['problemId']?.toString(),
    ticketNo: json['ticketNo']?.toString(),
    isRead: json['isRead'] == true,
  );
}

class NotificationProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_notifications_list';
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final ProblemRepository _repository = ProblemRepository();
  final List<NotificationItem> _notifications = [];
  String? _deviceId;
  String? _fcmToken;
  int _notificationIdCounter = 0;
  bool _initialized = false;

  // Global navigator key setter
  static GlobalKey<NavigatorState>? globalNavigatorKey;

  // Polling state
  Timer? _pollTimer;
  final Map<String, String> _knownStatuses = {};
  bool _firstPoll = true;

  // Realtime channel
  RealtimeChannel? _channel;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  String? get fcmToken => _fcmToken;

  /// Initialize the notification system (Local, FCM, Realtime, Polling, Persistence)
  Future<void> initialize() async {
    if (_initialized) return;
    _deviceId = await DeviceService.getDeviceId();
    
    // Load persisted notifications from SharedPreferences
    await _loadFromStorage();
    
    await _initLocalNotifications();
    await _initFirebaseMessaging();

    // Seed database state silently for polling
    await _seedInitialState();

    // Start polling every 30s as a reliable fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollForChanges());

    // Subscribe to Supabase Realtime for instant updates
    _subscribeToRealtime();

    _initialized = true;
    debugPrint('[NotificationProvider] Initialized. Device ID: $_deviceId, FCM: $_fcmToken, Loaded: ${_notifications.length}');
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_storageKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final List decoded = jsonDecode(savedStr);
        _notifications.clear();
        for (final item in decoded) {
          _notifications.add(NotificationItem.fromJson(item));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error loading persisted notifications: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('[NotificationProvider] Error saving notifications to storage: $e');
    }
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

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!);
            final problemId = data['problemId']?.toString();
            final ticketNo = data['ticketNo']?.toString();
            navigateToProblem(problemId: problemId, ticketNo: ticketNo);
          } catch (e) {
            debugPrint('[NotificationProvider] Error handling notification tap: $e');
          }
        }
      },
    );

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

      // Handle foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Got message: ${message.messageId}');
        final title = message.notification?.title ?? message.data['title'] ?? 'JharUdyam Alert';
        final body = message.notification?.body ?? message.data['body'] ?? 'You have a new civic update.';
        final problemId = message.data['problem_id']?.toString() ?? message.data['problemId']?.toString();
        final ticketNo = message.data['ticket_no']?.toString() ?? message.data['ticketNo']?.toString();

        _addNotification(
          title: title,
          body: body,
          type: message.data['type'] ?? 'status_change',
          problemId: problemId,
          ticketNo: ticketNo,
        );
      });

      // Handle notification taps when app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM OpenedApp] Message clicked: ${message.messageId}');
        final problemId = message.data['problem_id']?.toString() ?? message.data['problemId']?.toString();
        final ticketNo = message.data['ticket_no']?.toString() ?? message.data['ticketNo']?.toString();
        navigateToProblem(problemId: problemId, ticketNo: ticketNo);
      });

      // Handle notification if app was opened directly from terminated state
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        final problemId = initialMessage.data['problem_id']?.toString() ?? initialMessage.data['problemId']?.toString();
        final ticketNo = initialMessage.data['ticket_no']?.toString() ?? initialMessage.data['ticketNo']?.toString();
        Future.delayed(const Duration(milliseconds: 1000), () {
          navigateToProblem(problemId: problemId, ticketNo: ticketNo);
        });
      }

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
        final ticketNo = row['ticket_no']?.toString() ?? '';
        if (id.isEmpty) continue;
        currentIds.add(id);

        if (!_knownStatuses.containsKey(id)) {
          // New problem
          if (reporterId != _deviceId) {
            final title = row['title']?.toString() ?? 'New Report';
            final category = row['category']?.toString() ?? '';

            _addNotification(
              title: 'New Civic Report',
              body: '$title${category.isNotEmpty ? ' · $category' : ''}${ticketNo.isNotEmpty ? ' ($ticketNo)' : ''}',
              type: 'new_report',
              problemId: id,
              ticketNo: ticketNo,
            );
          }
          _knownStatuses[id] = status;
        } else if (_knownStatuses[id] != status) {
          // Status changed
          final title = row['title']?.toString() ?? 'Report Update';
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
            problemId: id,
            ticketNo: ticketNo,
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
                problemId: id,
                ticketNo: ticketNo,
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
                problemId: id,
                ticketNo: ticketNo,
              );
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[NotificationProvider] Realtime setup error: $e');
    }
  }

  void _addNotification({
    required String title,
    required String body,
    required String type,
    String? problemId,
    String? ticketNo,
  }) {
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
      problemId: problemId,
      ticketNo: ticketNo,
    );

    _notifications.insert(0, item);
    _saveToStorage();
    _showSystemNotification(
      title,
      body,
      payload: jsonEncode({'problemId': problemId, 'ticketNo': ticketNo}),
    );
    notifyListeners();
  }

  Future<void> _showSystemNotification(String title, String body, {String? payload}) async {
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

    await _notificationsPlugin.show(
      _notificationIdCounter++,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Deep navigate to a specific problem
  Future<void> navigateToProblem({String? problemId, String? ticketNo}) async {
    if (problemId == null && ticketNo == null) return;
    try {
      ProblemModel? problem;
      if (problemId != null && problemId.isNotEmpty) {
        problem = await _repository.getProblemById(problemId);
      } else if (ticketNo != null && ticketNo.isNotEmpty) {
        problem = await _repository.getProblemByTicketNo(ticketNo);
      }

      if (problem != null && globalNavigatorKey?.currentState != null) {
        globalNavigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ProblemDetailScreen(problem: problem!),
          ),
        );
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Failed to navigate to problem: $e');
    }
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
    _saveToStorage();
    notifyListeners();
  }

  void markRead(String id) {
    final n = _notifications.where((n) => n.id == id).firstOrNull;
    if (n != null) {
      n.isRead = true;
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Manually clear all notifications from memory and SharedPreferences
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveToStorage();
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _channel?.unsubscribe();
    _initialized = false;
    super.dispose();
  }
}

