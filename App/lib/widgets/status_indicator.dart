import 'package:flutter/material.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final String status;
  const StatusIndicator({super.key, required this.status});

  String _label() {
    switch (status.toLowerCase()) {
      case 'submitted': return 'Submitted';
      case 'under_review': return 'Under Review';
      case 'government_handling': return 'Accepted';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'released': return 'Released';
      case 'rejected': return 'Rejected';
      default: return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.statusBadgeBgColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.statusBadgeColor(status),
        ),
      ),
    );
  }
}
