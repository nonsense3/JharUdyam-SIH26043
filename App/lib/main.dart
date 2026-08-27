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
import 'package:jharudyam_citizen/screens/splash_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] Message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationProvider.globalNavigatorKey = appNavigatorKey;

  // Initialize Firebase & Supabase in parallel for fast bootup
  await Future.wait([
    (() async {
      try {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      } catch (e) {
        debugPrint('[Firebase] Init error: $e');
      }
    })(),
    Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    ),
    DeviceService.getDeviceId(),
  ]);

  // Initialize notification provider (non-blocking)
  final notificationProvider = NotificationProvider();
  notificationProvider.initialize();

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
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
