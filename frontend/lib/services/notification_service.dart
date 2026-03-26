import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }
  final SupabaseClient _supabase = SupabaseService.instance.client;

  Future<void> initialize() async {
    final fcm = _fcm;
    if (fcm == null) return;

    // 1. Request Permission
    NotificationSettings settings = await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });

    // 3. Handle notification click when app is in background or terminated
    fcm.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageOpen(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    // 4. Update Token
    await updateToken();
  }

  Future<void> updateToken() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final fcm = _fcm;
      if (fcm == null) return;

      String? token = await fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        
        // Save to Supabase profiles
        await _supabase.from('profiles').update({
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  void _handleMessageOpen(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.data}');
    // Here we can navigate to specific screens (e.g., Booking Details or Chat)
  }
}
