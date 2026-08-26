import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/models/problem_model.dart';

class ProblemCard extends StatelessWidget {
  final ProblemModel problem;
  final VoidCallback? onTap;

  const ProblemCard({super.key, required this.problem, this.onTap});

  int _stepFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'submitted': return 0;
      case 'under_review': return 1;
      case 'government_handling': case 'in_progress': case 'released': case 'interest_expressed': return 2;
      case 'resolved': return 3;
      default: return 0;
    }
  }

  String _badgeLabel(String status) {
    switch (status.toLowerCase()) {
      case 'submitted': return 'SUBMITTED';
      case 'under_review': return 'UNDER REVIEW';
      case 'government_handling': return 'ACCEPTED';
      case 'in_progress': return 'IN PROGRESS';
      case 'resolved': return 'RESOLVED';
      case 'released': return 'RELEASED';
      default: return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _stepFromStatus(problem.status);
    final labels = ['Submitted', 'Review', 'Action', 'Resolved'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Top row: image + title + badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: problem.imageUrl,
                      width: 56, height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(width: 56, height: 56, color: AppTheme.primaryTint),
                      errorWidget: (context, url, error) => Container(width: 56, height: 56, color: AppTheme.primaryTint, child: const Icon(Icons.image, color: AppTheme.primaryColor, size: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(problem.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('ID: ${problem.ticketNo ?? 'N/A'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.statusBadgeBgColor(problem.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _badgeLabel(problem.status),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.statusBadgeColor(problem.status), letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Progress bar
              Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
                      decoration: BoxDecoration(
                        color: i <= step ? AppTheme.primaryColor : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              // Labels
              Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: i == step ? FontWeight.w700 : FontWeight.w400,
                        color: i == step ? AppTheme.primaryColor : Colors.grey.shade400,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
