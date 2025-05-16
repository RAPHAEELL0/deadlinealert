import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:deadlinealert/models/deadline.dart' hide Priority;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._();

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Initialize notification settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification taps here
      },
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    // Request permissions for iOS
    final ios =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    // For Android, permissions are handled differently depending on the version
    return true;
  }

  Future<void> scheduleNotification(Deadline deadline) async {
    if (!_initialized) await initialize();

    // Cancel any existing notifications for this deadline
    await cancelNotificationsForDeadline(deadline.id);

    // For each reminder interval, schedule a notification
    for (final minutes in deadline.reminderMinutes) {
      final notificationTime = deadline.dueDate.subtract(
        Duration(minutes: minutes),
      );

      // Only schedule if the time is in the future
      if (notificationTime.isAfter(DateTime.now())) {
        final notificationId = _generateNotificationId(
          deadline.id,
          minutes,
          deadline.reminderMinutes,
        );

        // Title and description for the notification
        final title = deadline.title;
        final body =
            deadline.description != null && deadline.description!.isNotEmpty
                ? deadline.description!
                : 'Due in $minutes minutes';

        await _notifications.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(notificationTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'deadline_channel',
              'Deadline Reminders',
              channelDescription: 'Notifications for deadline reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: deadline.id,
        );
      }
    }
  }

  Future<void> cancelNotificationsForDeadline(String deadlineId) async {
    if (!_initialized) await initialize();

    // Cancel all potential notification IDs for this deadline
    // We use a range of IDs starting from a base ID derived from the deadline ID
    final baseId = _generateBaseNotificationId(deadlineId);
    for (int i = 0; i < 10; i++) {
      await _notifications.cancel(baseId + i);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  // Generate a unique notification ID based on the deadline ID and minutes
  int _generateNotificationId(
    String deadlineId,
    int minutes,
    List<int> reminderMinutes,
  ) {
    final baseId = _generateBaseNotificationId(deadlineId);
    // Use the minutes as an offset (max 10 different reminder times per deadline)
    final reminderIndex = reminderMinutes.indexOf(minutes) % 10;
    return baseId + reminderIndex;
  }

  // Generate a base notification ID from the deadline ID
  // We use a hash of the ID to get an integer
  int _generateBaseNotificationId(String deadlineId) {
    // Simple hash function to convert string to integer
    int hash = 0;
    for (int i = 0; i < deadlineId.length; i++) {
      hash = 31 * hash + deadlineId.codeUnitAt(i);
    }
    // Ensure positive value and limit to 7 digits to avoid overflow
    // This gives us room for 10 notifications per deadline
    return (hash.abs() % 1000000) * 10;
  }
}
