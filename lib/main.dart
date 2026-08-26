import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jharudyam_citizen/constants/app_constants.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/providers/problems_provider.dart';
import 'package:jharudyam_citizen/providers/report_provider.dart';
import 'package:jharudyam_citizen/providers/notification_provider.dart';
import 'package:jharudyam_citizen/services/device_service.dart';
import 'package:jharudyam_citizen/screens/main_shell.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] Message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('[Firebase] Initialized successfully');
  } catch (e) {
    debugPrint('[Firebase] Initialization error: $e');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  // Pre-generate device ID on first launch
  await DeviceService.getDeviceId();

  // Initialize notification provider
  final notificationProvider = NotificationProvider();
  await notificationProvider.initialize();

  runApp(JharUdyamApp(notificationProvider: notificationProvider));
}

class JharUdyamApp extends StatelessWidget {
  final NotificationProvider? notificationProvider;

  const JharUdyamApp({super.key, this.notificationProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProblemsProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        if (notificationProvider != null)
          ChangeNotifierProvider.value(value: notificationProvider!)
        else
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'JharUdyam',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainShell(),
      ),
    );
  }
}
