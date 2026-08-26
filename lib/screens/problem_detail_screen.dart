import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/models/problem_model.dart';
import 'package:jharudyam_citizen/widgets/priority_badge.dart';
import 'package:jharudyam_citizen/widgets/status_indicator.dart';
import 'package:jharudyam_citizen/widgets/lifecycle_tracker.dart';
import 'package:jharudyam_citizen/widgets/location_card.dart';

class ProblemDetailScreen extends StatelessWidget {
  final ProblemModel problem;

  const ProblemDetailScreen({super.key, required this.problem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing hero image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: problem.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.primaryTint,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.primaryTint,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket + Priority + Status row
                  Row(
                    children: [
                      if (problem.ticketNo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTint,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            problem.ticketNo!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: AppTheme.primaryDark,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      PriorityBadge(priority: problem.priority),
                      const Spacer(),
                      StatusIndicator(status: problem.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    problem.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lifecycle Custody Track
                  const Text(
                    'Issue Lifecycle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LifecycleTracker(currentStatus: problem.status),
                  const SizedBox(height: 24),

                  // Metadata section
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMetadataCard(),
                  const SizedBox(height: 24),

                  // Description section
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      problem.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location section
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LocationCard(
                    latitude: problem.latitude,
                    longitude: problem.longitude,
                    address: problem.address,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    final formattedDate = problem.createdAt != null
        ? DateFormat('MMM dd, yyyy · hh:mm a').format(problem.createdAt!.toLocal())
        : 'Unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _metadataRow(Icons.category_outlined, 'Category', problem.category),
            const Divider(height: 16),
            _metadataRow(
              Icons.flag_outlined,
              'Priority',
              problem.priority[0].toUpperCase() + problem.priority.substring(1),
            ),
            const Divider(height: 16),
            _metadataRow(
              Icons.account_balance_outlined,
              'Department',
              problem.department,
            ),
            const Divider(height: 16),
            _metadataRow(Icons.access_time, 'Reported', formattedDate),
          ],
        ),
      ),
    );
  }

  Widget _metadataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
