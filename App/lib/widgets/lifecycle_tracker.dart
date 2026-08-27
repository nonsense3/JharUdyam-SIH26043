import 'package:flutter/material.dart';

class LifecycleTracker extends StatelessWidget {
  final String currentStatus;
  const LifecycleTracker({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    // Timeline is now rendered directly in ProblemDetailScreen
    return const SizedBox.shrink();
  }
}
