import 'package:flutter/material.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  String get _label {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'government_handling':
        return 'Gov. Handling';
      case 'released':
        return 'Released';
      case 'interest_expressed':
        return 'Interest';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  IconData get _icon {
    switch (status) {
      case 'submitted':
        return Icons.upload_outlined;
      case 'under_review':
        return Icons.visibility_outlined;
      case 'government_handling':
        return Icons.account_balance_outlined;
      case 'released':
        return Icons.launch_outlined;
      case 'interest_expressed':
        return Icons.handshake_outlined;
      case 'in_progress':
        return Icons.engineering_outlined;
      case 'resolved':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
