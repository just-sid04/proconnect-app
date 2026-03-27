import 'dart:convert';

enum NotificationType { booking, payment, chat, system }

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String priority;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.priority = 'normal',
    this.data = const {},
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: _parseType(json['type']),
      isRead: json['is_read'] ?? false,
      priority: json['priority'] ?? 'normal',
      data: json['data'] is Map ? json['data'] : {},
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'booking':
        return NotificationType.booking;
      case 'payment':
        return NotificationType.payment;
      case 'chat':
        return NotificationType.chat;
      default:
        return NotificationType.system;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'is_read': isRead,
      'priority': priority,
      'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
