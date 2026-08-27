import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/providers/notification_provider.dart';
import 'package:jharudyam_citizen/screens/home_screen.dart';
import 'package:jharudyam_citizen/screens/create_report_screen.dart';
import 'package:jharudyam_citizen/screens/notifications_screen.dart';
import 'package:jharudyam_citizen/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SizedBox.shrink(), // placeholder, Report opens as push
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 1) {
      // Report tab — push CreateReportScreen
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateReportScreen()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notifProvider, _) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                ),
                label: 'Report',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: notifProvider.unreadCount > 0,
                  label: Text('${notifProvider.unreadCount}'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: notifProvider.unreadCount > 0,
                  label: Text('${notifProvider.unreadCount}'),
                  child: const Icon(Icons.notifications),
                ),
                label: 'Updates',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
