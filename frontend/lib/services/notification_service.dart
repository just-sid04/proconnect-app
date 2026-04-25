import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final SupabaseClient _sb = Supabase.instance.client;

  /// Safely gets the FirebaseMessaging instance.
  /// Returns null if Firebase is not initialized or if Messaging isn't available.
  FirebaseMessaging? get _fcm {
    try {
      // 1. Basic check: Any apps at all?
      if (Firebase.apps.isEmpty) {
        return null;
      }

      // 2. Extra check for Web: Avoid calling Firebase.app() as it throws if [DEFAULT] is missing.
      if (kIsWeb) {
        final hasDefault = Firebase.apps.any((app) => app.name == '[DEFAULT]');
        if (hasDefault) {
          return FirebaseMessaging.instance;
        }
        return null;
      }

      // 3. Mobile fallback
      return FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('NotificationService: FCM access failed: $e');
      return null;
    }
  }

  Future<void> initialize() async {
    // Wrap the whole thing in a global try-catch just in case
    try {
      final fcm = _fcm;
      if (fcm == null) {
        debugPrint('NotificationService: Skipping Firebase FCM (No valid Firebase app)');
        return;
      }

      // 1. Request permission
      final settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permissions');
      }

      // 2. Handle foreground messages
      // Note: FirebaseMessaging.onMessage is a static getter that internally calls .instance
      // Since we confirmed fcm is not null, it SHOULD be safe, but we'll use fcm-based stream if possible.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message received: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('NotificationService: Initialization crash avoided: $e');
    }
  }

  Future<void> updateToken() async {
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) return;

      final fcm = _fcm;
      if (fcm == null) return;

      final token = await fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _sb.from('profiles').update({'fcm_token': token}).eq('id', userId);
      }
    } catch (e) {
      debugPrint('NotificationService: updateToken error: $e');
    }
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
    if (userId == null) return _sb.channel('dummy');
    
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
