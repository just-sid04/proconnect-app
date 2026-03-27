import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService.instance;
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _subscription;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    await loadNotifications();
    _subscribe();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribe() {
    _subscription?.unsubscribe();
    _subscription = _service.subscribeToNotifications((newNotif) {
      _notifications.insert(0, newNotif);
      notifyListeners();
      // Optional: Show a local toast/notification if app is in background
    });
  }

  Future<void> markAsRead(String id) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        await _service.markAsRead(id);
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          body: _notifications[index].body,
          type: _notifications[index].type,
          isRead: true,
          priority: _notifications[index].priority,
          data: _notifications[index].data,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        userId: n.userId,
        title: n.title,
        body: n.body,
        type: n.type,
        isRead: true,
        priority: n.priority,
        data: n.data,
        createdAt: n.createdAt,
      )).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
