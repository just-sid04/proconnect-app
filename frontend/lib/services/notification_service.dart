import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final SupabaseClient _sb = Supabase.instance.client;

  Future<void> initialize() async {
    // Initial setup if needed (e.g. FCM permission requests)
    // For now it's just a placeholder to satisfy main.dart
  }

  Future<void> updateToken() async {
    // Placeholder for FCM token sync logic.
    // In a real implementation with firebase_messaging, this would:
    // 1. Get current token
    // 2. Update profiles table with the token for the current user.
    debugPrint('NotificationService: updateToken() called (Stub)');
  }

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _sb
          .from('notifications')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((n) => AppNotification.fromJson(n))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _sb
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return;
    await _sb
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  RealtimeChannel subscribeToNotifications(Function(AppNotification) onNew) {
    final userId = _sb.auth.currentUser?.id;
    final channel = _sb.channel('public:notifications:user=$userId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        onNew(AppNotification.fromJson(payload.newRecord));
      },
    ).subscribe();

    return channel;
  }
}
