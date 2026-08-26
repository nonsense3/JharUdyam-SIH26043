import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/services/device_service.dart';
import 'package:jharudyam_citizen/providers/problems_provider.dart';
import 'package:jharudyam_citizen/screens/problem_detail_screen.dart';
import 'package:jharudyam_citizen/widgets/problem_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _citizenId = '...';

  @override
  void initState() {
    super.initState();
    _loadCitizenId();
  }

  Future<void> _loadCitizenId() async {
    final id = await DeviceService.getDeviceId();
    if (mounted) {
      setState(() {
        final short = id.replaceAll('-', '').substring(0, 8).toUpperCase();
        _citizenId = 'JH-${short.substring(0, 4)}-${short.substring(4, 8)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jhar Udayam', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryTint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.person, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Citizen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('Citizen ID: $_citizenId', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // MY ACTIVITY
            Text('MY ACTIVITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor, letterSpacing: 1)),
            const SizedBox(height: 12),
            _buildMenuCard([
              _menuItem(Icons.description_outlined, 'My Reports', () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _MyReportsPage()));
              }),
              _menuItem(Icons.notifications_outlined, 'Notifications', () {
                // Navigate to Updates tab - handled by parent MainShell
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Switch to Updates tab for notifications'), duration: Duration(seconds: 2)),
                );
              }),
            ]),
            const SizedBox(height: 24),

            // SUPPORT
            Text('SUPPORT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor, letterSpacing: 1)),
            const SizedBox(height: 12),
            _buildMenuCard([
              _menuItem(Icons.info_outline, 'About Jhar Udayam', () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('About Jhar Udayam', style: TextStyle(fontWeight: FontWeight.w700)),
                    content: const Text('JharUdyam is a smart civic reporting platform for Jharkhand citizens. Report infrastructure issues, track resolutions, and help improve your community.\n\nBuilt for SIH 2026 (Problem ID: SIH26043).', style: TextStyle(height: 1.5)),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                  ),
                );
              }),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppTheme.primaryTint, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// Internal My Reports page
class _MyReportsPage extends StatefulWidget {
  const _MyReportsPage();

  @override
  State<_MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<_MyReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProblemsProvider>().fetchMyReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Consumer<ProblemsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          if (provider.myReports.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No reports yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
              ]),
            );
          }
          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () => provider.fetchMyReports(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: provider.myReports.length,
              itemBuilder: (context, index) {
                final problem = provider.myReports[index];
                return ProblemCard(
                  problem: problem,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProblemDetailScreen(problem: problem)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
