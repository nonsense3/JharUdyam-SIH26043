import 'package:flutter/material.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';

class LifecycleTracker extends StatelessWidget {
  final String currentStatus;

  const LifecycleTracker({super.key, required this.currentStatus});

  static const List<_StepData> _steps = [
    _StepData('Submitted', Icons.upload_outlined),
    _StepData('Dept. Review', Icons.visibility_outlined),
    _StepData('Work Started', Icons.engineering_outlined),
    _StepData('Resolved', Icons.check_circle_outline),
  ];

  int get _activeIndex {
    switch (currentStatus) {
      case 'submitted':
        return 0;
      case 'under_review':
        return 1;
      case 'government_handling':
        return 2;
      case 'released':
      case 'interest_expressed':
        return 2;
      case 'in_progress':
        return 2;
      case 'resolved':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIdx = _activeIndex;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryTint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepBefore = index ~/ 2;
            final isCompleted = stepBefore < activeIdx;
            return Expanded(
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final step = _steps[stepIndex];
          final isCompleted = stepIndex < activeIdx;
          final isActive = stepIndex == activeIdx;

          return _buildStepNode(step, isCompleted, isActive);
        }),
      ),
    );
  }

  Widget _buildStepNode(_StepData step, bool isCompleted, bool isActive) {
    final Color circleColor;
    final Color iconColor;

    if (isCompleted) {
      circleColor = AppTheme.primaryColor;
      iconColor = Colors.white;
    } else if (isActive) {
      circleColor = AppTheme.primaryColor.withValues(alpha: 0.15);
      iconColor = AppTheme.primaryColor;
    } else {
      circleColor = Colors.grey.shade200;
      iconColor = Colors.grey.shade400;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : step.icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive || isCompleted
                ? AppTheme.primaryDark
                : Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StepData {
  final String label;
  final IconData icon;
  const _StepData(this.label, this.icon);
}
