import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:deadlinealert/models/deadline.dart';
import 'package:deadlinealert/providers/auth_provider.dart';
import 'package:deadlinealert/providers/deadline_provider.dart';
import 'package:deadlinealert/providers/category_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class OverdueDeadlinesScreen extends ConsumerWidget {
  const OverdueDeadlinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final deadlineState = ref.watch(deadlineProvider(authState.deviceId));
    final overdueDeadlines = deadlineState.overdueDeadlines;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Overdue Tasks (${overdueDeadlines.length})',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showRescheduleDialog(context, ref),
            icon: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 16,
            ),
            label: const Text(
              'Reschedule All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8B0000), // Dark red
              const Color(0xFF6B0000), // Even darker red
            ],
          ),
        ),
        child:
            overdueDeadlines.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                  itemCount: overdueDeadlines.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    return _buildDeadlineItem(
                      context,
                      ref,
                      overdueDeadlines[index],
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 70,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'No overdue tasks',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(
    BuildContext context,
    WidgetRef ref,
    Deadline deadline,
  ) {
    final authState = ref.read(authProvider);
    final categoryState = ref.watch(categoryProvider(authState.deviceId));
    final category = categoryState.findById(deadline.categoryId);

    final dateFormat = DateFormat('d MMM, h:mm a');
    final formattedDate = dateFormat.format(deadline.dueDate);

    // Define priority colors
    final priorityColors = {
      Priority.low: Colors.green,
      Priority.medium: Colors.orange,
      Priority.high: Colors.red.shade500,
    };

    final priorityColor = priorityColors[deadline.priority] ?? Colors.orange;

    final daysOverdue = DateTime.now().difference(deadline.dueDate).inDays;
    final overdueText =
        daysOverdue == 0
            ? 'Due today'
            : daysOverdue == 1
            ? 'Overdue by 1 day'
            : 'Overdue by $daysOverdue days';

    return Slidable(
      key: ValueKey(deadline.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _editDeadline(context, deadline.id),
            backgroundColor: Colors.white.withOpacity(0.3),
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) => _deleteDeadline(context, ref, deadline),
            backgroundColor: Colors.red.withOpacity(0.7),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Colors.white.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _editDeadline(context, deadline.id),
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Checkbox
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: deadline.isCompleted,
                        onChanged: (value) {
                          if (value != null) {
                            _toggleDeadlineCompletion(
                              ref,
                              deadline.id,
                              deadline.isCompleted,
                            );
                          }
                        },
                        fillColor: MaterialStateProperty.resolveWith<Color>((
                          states,
                        ) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.white.withOpacity(0.8);
                          }
                          return Colors.white.withOpacity(0.3);
                        }),
                        checkColor: const Color(0xFF8B0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Priority indicator
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            deadline.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Due date
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                overdueText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (deadline.description != null &&
                    deadline.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 36),
                    child: Text(
                      deadline.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category
                      if (category != null)
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: category.colorValue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      // Due date
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleDeadlineCompletion(WidgetRef ref, String id, bool currentStatus) {
    final authState = ref.read(authProvider);
    ref
        .read(deadlineProvider(authState.deviceId).notifier)
        .toggleDeadlineCompletion(id, !currentStatus);
  }

  void _editDeadline(BuildContext context, String id) {
    context.go('/deadline/$id');
  }

  void _deleteDeadline(BuildContext context, WidgetRef ref, Deadline deadline) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF8B0000).withOpacity(0.9),
          title: const Text(
            'Confirm Delete',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${deadline.title}"?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                // Delete the deadline
                final authState = ref.read(authProvider);
                ref
                    .read(deadlineProvider(authState.deviceId).notifier)
                    .deleteDeadline(deadline.id);
                Navigator.of(context).pop();
                // Show feedback to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${deadline.title}"'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showRescheduleDialog(BuildContext context, WidgetRef ref) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B0000),
              onPrimary: Colors.white,
              surface: Color(0xFF6B0000),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF4B0000),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && context.mounted) {
      final authState = ref.read(authProvider);
      final rescheduledCount = await ref
          .read(deadlineProvider(authState.deviceId).notifier)
          .rescheduleOverdueDeadlines(pickedDate);

      if (!context.mounted) return;

      final formattedDate =
          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      String message =
          rescheduledCount > 0
              ? '$rescheduledCount task${rescheduledCount > 1 ? 's' : ''} rescheduled to $formattedDate'
              : 'No tasks to reschedule';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF006400), // Dark green
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
