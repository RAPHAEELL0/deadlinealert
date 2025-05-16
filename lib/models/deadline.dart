import 'package:uuid/uuid.dart';

enum Priority { low, medium, high }

class Deadline {
  final String id;
  final String? userId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String? categoryId;
  final Priority priority;
  final bool isCompleted;
  final List<int> reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? deviceId;

  Deadline({
    String? id,
    this.userId,
    required this.title,
    this.description,
    required this.dueDate,
    this.categoryId,
    required this.priority,
    this.isCompleted = false,
    this.reminderMinutes = const [30],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deviceId,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Deadline.fromJson(Map<String, dynamic> json) {
    return Deadline(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']),
      categoryId: json['category_id'],
      priority: _parsePriority(json['priority']),
      isCompleted: json['is_completed'] ?? false,
      reminderMinutes:
          json['reminder_minutes'] != null
              ? List<int>.from(json['reminder_minutes'])
              : [30],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
      deviceId: json['device_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'category_id': categoryId,
      'priority': priority.name,
      'is_completed': isCompleted,
      'reminder_minutes': reminderMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'device_id': deviceId,
    };
  }

  Deadline copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? categoryId,
    Priority? priority,
    bool? isCompleted,
    List<int>? reminderMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
  }) {
    return Deadline(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deviceId: deviceId ?? this.deviceId,
    );
  }

  static Priority _parsePriority(String? priority) {
    if (priority == null) return Priority.medium;

    switch (priority.toLowerCase()) {
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      case 'medium':
      default:
        return Priority.medium;
    }
  }

  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));
    return dueDate.isAfter(today) && dueDate.isBefore(nextWeek);
  }
}
