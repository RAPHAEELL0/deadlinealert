import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Types of haptic feedback for microinteractions
enum HapticFeedbackType { light, medium, heavy, success, error, selection }

/// Service for haptic feedback during microinteractions
class HapticFeedbackService {
  static final HapticFeedbackService _instance =
      HapticFeedbackService._internal();

  factory HapticFeedbackService() => _instance;

  HapticFeedbackService._internal();

  /// Get the singleton instance
  static HapticFeedbackService get instance => _instance;

  bool _isEnabled = true;

  /// Provides haptic feedback based on the action type
  Future<void> feedback(HapticFeedbackType type) async {
    if (!_isEnabled) return;

    try {
      switch (type) {
        case HapticFeedbackType.light:
          await HapticFeedback.lightImpact();
        case HapticFeedbackType.medium:
          await HapticFeedback.mediumImpact();
        case HapticFeedbackType.heavy:
          await HapticFeedback.heavyImpact();
        case HapticFeedbackType.success:
          await HapticFeedback.mediumImpact();
        case HapticFeedbackType.error:
          await HapticFeedback.vibrate();
        case HapticFeedbackType.selection:
          await HapticFeedback.selectionClick();
      }
    } catch (e) {
      debugPrint('Error providing haptic feedback: $e');
    }
  }

  /// Enable or disable haptic feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
}
