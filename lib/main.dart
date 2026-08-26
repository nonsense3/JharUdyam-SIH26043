import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jharudyam_citizen/constants/app_constants.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/providers/problems_provider.dart';
import 'package:jharudyam_citizen/providers/report_provider.dart';
import 'package:jharudyam_citizen/providers/notification_provider.dart';
import 'package:jharudyam_citizen/services/device_service.dart';
import 'package:jharudyam_citizen/screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
