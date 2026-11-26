import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.forMedicineStatus(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
        return const StatusBadge(
          label: 'Taken',
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      case 'skipped':
        return const StatusBadge(
          label: 'Skipped',
          color: AppColors.warning,
          icon: Icons.skip_next_rounded,
        );
      case 'missed':
        return const StatusBadge(
          label: 'Missed',
          color: AppColors.danger,
          icon: Icons.cancel_rounded,
        );
      case 'snoozed':
        return const StatusBadge(
          label: 'Snoozed',
          color: AppColors.info,
          icon: Icons.snooze_rounded,
        );
      default:
        return const StatusBadge(
          label: 'Upcoming',
          color: AppColors.primary,
          icon: Icons.schedule_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
