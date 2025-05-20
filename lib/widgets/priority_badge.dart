import 'package:flutter/material.dart';
import 'package:deadlinealert/models/deadline.dart';
import 'package:deadlinealert/utils/animation_utils.dart' as anim;

class PriorityBadge extends StatelessWidget {
  final Priority priority;
  final bool mini;
  final bool animate;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.mini = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    // Define priority colors
    final priorityColors = {
      Priority.low: Colors.green,
      Priority.medium: Colors.orange,
      Priority.high: Colors.red.shade500,
    };

    // Define priority labels
    final priorityLabels = {
      Priority.low: 'Low',
      Priority.medium: 'Medium',
      Priority.high: 'High',
    };

    // Define priority icons
    final priorityIcons = {
      Priority.low: Icons.arrow_downward,
      Priority.medium: Icons.remove,
      Priority.high: Icons.arrow_upward,
    };

    final priorityColor = priorityColors[priority] ?? Colors.orange;
    final priorityLabel = priorityLabels[priority] ?? 'Medium';
    final priorityIcon = priorityIcons[priority];

    // For mini version (just a colored dot)
    if (mini) {
      return anim.AnimatedPulse(
        active: animate && priority == Priority.high,
        repeat: true,
        color: Colors.transparent,
        duration: const Duration(milliseconds: 1200),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: priorityColor,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    // For full badge version
    return anim.AnimatedPulse(
      active: animate && priority == Priority.high,
      repeat: true,
      color: Colors.transparent,
      duration: const Duration(milliseconds: 1200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: priorityColor.withOpacity(0.2),
          border: Border.all(color: priorityColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(priorityIcon, color: priorityColor, size: 16),
            const SizedBox(width: 4),
            Text(
              priorityLabel,
              style: TextStyle(
                color: priorityColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
