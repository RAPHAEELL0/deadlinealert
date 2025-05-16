import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String? userId;
  final String name;
  final String color; // Color stored as hex string
  final String? deviceId;
  final DateTime createdAt;

  Category({
    String? id,
    this.userId,
    required this.name,
    this.color = '#FF0000',
    this.deviceId,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      color: json['color'] ?? '#FF0000',
      deviceId: json['device_id'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'device_id': deviceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    String? deviceId,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper to convert stored hex color to Flutter Color
  Color get colorValue {
    String hexColor = color.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
