import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/models/problem_model.dart';

class ProblemDetailScreen extends StatelessWidget {
  final ProblemModel problem;

  const ProblemDetailScreen({super.key, required this.problem});

  static const _timelineSteps = [
    {'status': 'submitted', 'label': 'Report Submitted'},
    {'status': 'under_review', 'label': 'Initial Review'},
    {'status': 'government_handling', 'label': 'Challenge Categorized'},
    {'status': 'in_progress', 'label': 'Government Review'},
    {'status': 'resolved', 'label': 'Resolution & Action'},
  ];

  int _currentStepIndex() {
    final statusOrder = ['submitted', 'under_review', 'government_handling', 'in_progress', 'resolved'];
    final idx = statusOrder.indexOf(problem.status.toLowerCase());
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStepIndex();
    final formattedDate = problem.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(problem.createdAt!.toLocal())
        : 'Unknown';
    final formattedTime = problem.createdAt != null
        ? DateFormat('hh:mm a').format(problem.createdAt!.toLocal())
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jhar Udayam', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tracking ID + Status Badge
            Text('TRACKING ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    problem.ticketNo ?? 'N/A',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.statusBadgeBgColor(problem.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(problem.status),
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppTheme.statusBadgeColor(problem.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Latest Update card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryTint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Latest Update', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(_latestUpdateMessage(), style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Timeline
            const Text('Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 16),
            ...List.generate(_timelineSteps.length, (index) {
              final step = _timelineSteps[index];
              final isDone = index <= currentStep;
              final isLast = index == _timelineSteps.length - 1;
              return _buildTimelineStep(
                label: step['label']!,
                isDone: isDone,
                isLast: isLast,
                date: index == 0 ? '$formattedDate • $formattedTime' : (isDone ? formattedDate : 'Upcoming'),
              );
            }),
            const SizedBox(height: 32),

            // Report Details
            const Text('Report Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 16),
            _detailRow(Icons.text_fields, 'Problem Title', problem.title),
            _detailRow(Icons.category_outlined, 'Category', problem.category),
            _detailRow(Icons.location_on_outlined, 'Location', problem.address),
            _detailRow(Icons.calendar_today_outlined, 'Submitted Date', formattedDate),
            _detailRow(Icons.account_balance_outlined, 'Department', problem.department),
            _detailRow(Icons.flag_outlined, 'Priority', problem.priority[0].toUpperCase() + problem.priority.substring(1)),
            const SizedBox(height: 20),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text(problem.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({required String label, required bool isDone, required bool isLast, required String date}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.primaryColor : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check : Icons.circle,
                  size: isDone ? 16 : 8,
                  color: isDone ? Colors.white : Colors.grey.shade400,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: isDone ? AppTheme.primaryColor : Colors.grey.shade200),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDone ? Colors.black87 : Colors.grey.shade400)),
                  const SizedBox(height: 2),
                  Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const Spacer(),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'submitted': return 'Submitted';
      case 'under_review': return 'Under Review';
      case 'government_handling': return 'Accepted';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'released': return 'Released';
      default: return status.replaceAll('_', ' ');
    }
  }

  String _latestUpdateMessage() {
    switch (problem.status.toLowerCase()) {
      case 'submitted': return 'Your report has been submitted and is awaiting review by the municipal team.';
      case 'under_review': return 'Your report is currently under review. The team is assessing the issue.';
      case 'government_handling': return 'Your report has been verified and accepted for action. A municipal team will be assigned shortly.';
      case 'in_progress': return 'A government team is actively working on resolving this issue.';
      case 'resolved': return 'Your report has been resolved. The issue has been fixed by the municipal team. Thank you for your contribution!';
      default: return 'Your report is being processed.';
    }
  }
}
