import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deadlinealert/models/deadline.dart';
import 'package:deadlinealert/services/supabase_service.dart';
import 'package:deadlinealert/providers/auth_provider.dart';
import 'package:deadlinealert/services/notification_service.dart';

// Deadline state class
class DeadlineState {
  final List<Deadline> deadlines;
  final bool isLoading;
  final String? errorMessage;

  DeadlineState({
    this.deadlines = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DeadlineState copyWith({
    List<Deadline>? deadlines,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DeadlineState(
      deadlines: deadlines ?? this.deadlines,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  // Filtered deadlines by completed status
  List<Deadline> get completedDeadlines =>
      deadlines.where((deadline) => deadline.isCompleted).toList();

  List<Deadline> get pendingDeadlines =>
      deadlines.where((deadline) => !deadline.isCompleted).toList();

  // Filtered deadlines by date
  List<Deadline> get overdueDeadlines =>
      pendingDeadlines.where((deadline) => deadline.isOverdue).toList();

  List<Deadline> get todayDeadlines =>
      pendingDeadlines.where((deadline) => deadline.isToday).toList();

  List<Deadline> get upcomingDeadlines =>
      pendingDeadlines
          .where((deadline) => !deadline.isOverdue && !deadline.isToday)
          .toList();

  // Filtered deadlines by category
  List<Deadline> getDeadlinesByCategory(String? categoryId) {
    if (categoryId == null) return [];
    return pendingDeadlines
        .where((deadline) => deadline.categoryId == categoryId)
        .toList();
  }
}

class DeadlineNotifier extends StateNotifier<DeadlineState> {
  final SupabaseClient _client;
  final String _deviceId;
  final NotificationService _notificationService = NotificationService.instance;

  DeadlineNotifier(this._client, this._deviceId) : super(DeadlineState()) {
    fetchDeadlines();
  }

  // Fetch all deadlines
  Future<void> fetchDeadlines() async {
    state = state.copyWith(isLoading: true);

    try {
      final supabaseService = SupabaseService(_client);
      final deadlines = await supabaseService.getDeadlines(deviceId: _deviceId);

      state = state.copyWith(deadlines: deadlines, isLoading: false);

      // Schedule notifications for all pending deadlines
      _scheduleNotifications();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Create a new deadline
  Future<void> addDeadline(Deadline deadline) async {
    state = state.copyWith(isLoading: true);

    try {
      final supabaseService = SupabaseService(_client);
      final newDeadline = deadline.copyWith(deviceId: _deviceId);
      final createdDeadline = await supabaseService.createDeadline(newDeadline);

      state = state.copyWith(
        deadlines: [...state.deadlines, createdDeadline],
        isLoading: false,
      );

      // Schedule notification for the new deadline
      _scheduleNotification(createdDeadline);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Update an existing deadline
  Future<void> updateDeadline(Deadline deadline) async {
    state = state.copyWith(isLoading: true);

    try {
      final supabaseService = SupabaseService(_client);
      final updatedDeadline = await supabaseService.updateDeadline(deadline);

      state = state.copyWith(
        deadlines:
            state.deadlines
                .map((d) => d.id == updatedDeadline.id ? updatedDeadline : d)
                .toList(),
        isLoading: false,
      );

      // Update notification for the deadline
      _scheduleNotification(updatedDeadline);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Mark a deadline as completed
  Future<void> toggleDeadlineCompletion(
    String deadlineId,
    bool isCompleted,
  ) async {
    state = state.copyWith(isLoading: true);

    try {
      final deadline = state.deadlines.firstWhere((d) => d.id == deadlineId);
      final updatedDeadline = deadline.copyWith(isCompleted: isCompleted);

      final supabaseService = SupabaseService(_client);
      final result = await supabaseService.updateDeadline(updatedDeadline);

      state = state.copyWith(
        deadlines:
            state.deadlines.map((d) => d.id == result.id ? result : d).toList(),
        isLoading: false,
      );

      // If completed, cancel notifications; otherwise reschedule
      if (isCompleted) {
        await _notificationService.cancelNotificationsForDeadline(deadlineId);
      } else {
        _scheduleNotification(result);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Delete a deadline
  Future<void> deleteDeadline(String deadlineId) async {
    state = state.copyWith(isLoading: true);

    try {
      final supabaseService = SupabaseService(_client);
      await supabaseService.deleteDeadline(deadlineId);

      state = state.copyWith(
        deadlines: state.deadlines.where((d) => d.id != deadlineId).toList(),
        isLoading: false,
      );

      // Cancel notifications for the deleted deadline
      await _notificationService.cancelNotificationsForDeadline(deadlineId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Reschedule all overdue deadlines to a new date
  Future<int> rescheduleOverdueDeadlines(DateTime newDueDate) async {
    state = state.copyWith(isLoading: true);

    try {
      final supabaseService = SupabaseService(_client);
      final overdueDeadlines = state.overdueDeadlines;
      final updatedDeadlines = <Deadline>[];

      for (final deadline in overdueDeadlines) {
        // Create updated deadline with new due date at the same time as original
        final updatedDueDate = DateTime(
          newDueDate.year,
          newDueDate.month,
          newDueDate.day,
          deadline.dueDate.hour,
          deadline.dueDate.minute,
        );

        final updatedDeadline = deadline.copyWith(
          dueDate: updatedDueDate,
          updatedAt: DateTime.now(),
        );

        final result = await supabaseService.updateDeadline(updatedDeadline);
        updatedDeadlines.add(result);
      }

      // Update state with rescheduled deadlines
      state = state.copyWith(
        deadlines:
            state.deadlines.map((d) {
              final updated = updatedDeadlines.firstWhere(
                (updatedD) => updatedD.id == d.id,
                orElse: () => d,
              );
              return updated;
            }).toList(),
        isLoading: false,
      );

      // Reschedule notifications for updated deadlines
      for (final deadline in updatedDeadlines) {
        await _scheduleNotification(deadline);
      }

      return updatedDeadlines.length;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return 0;
    }
  }

  // Schedule notifications for all pending deadlines
  Future<void> _scheduleNotifications() async {
    await _notificationService.initialize();

    for (final deadline in state.pendingDeadlines) {
      await _scheduleNotification(deadline);
    }
  }

  // Schedule notification for a single deadline
  Future<void> _scheduleNotification(Deadline deadline) async {
    // Only schedule notifications for pending deadlines
    if (!deadline.isCompleted) {
      await _notificationService.scheduleNotification(deadline);
    }
  }
}

// Provider for deadline state
final deadlineProvider =
    StateNotifierProvider.family<DeadlineNotifier, DeadlineState, String>((
      ref,
      deviceId,
    ) {
      final supabase = SupabaseService.client;
      return DeadlineNotifier(supabase, deviceId);
    });

// Combined provider that uses the auth state to get deadlines
final deadlinesProvider = Provider<DeadlineState>((ref) {
  final authState = ref.watch(authProvider);
  final deadlineState = ref.watch(deadlineProvider(authState.deviceId));

  return deadlineState;
});
