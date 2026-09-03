import 'package:flutter/material.dart';

class AppNotification {
  final int? notificationId;
  final int? employeeId;
  final String title;
  final String message;
  final String severity;
  final bool isRead;
  final String createdAt;

  AppNotification({
    this.notificationId,
    this.employeeId,
    required this.title,
    required this.message,
    required this.severity,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notification_id'],
      employeeId: json['employee_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'info',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  Color get severityColor {
    switch (severity) {
      case 'success':
        return const Color(0xFF2E9E6B);
      case 'warning':
        return const Color(0xFFD79A1E);
      case 'danger':
        return const Color(0xFFD9534F);
      default:
        return const Color(0xFF1E4D8C);
    }
  }
}
