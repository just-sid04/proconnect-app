import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final String userId;
  
  Map<String, int> _unreadCounts = {}; // bookingId -> count
  int _totalUnread = 0;
  final bool _isLoading = false;
  StreamSubscription? _unreadSubscription;

  ChatProvider(this.userId) {
    _initUnreadStream();
  }

  Map<String, int> get unreadCounts => _unreadCounts;
  int get totalUnread => _totalUnread;
  int get unreadConversationsCount => _unreadCounts.length; // Number of people/bookings with unread messages
  bool get isLoading => _isLoading;

  void _initUnreadStream() {
    _unreadSubscription?.cancel();
    _unreadSubscription = ChatService.getUnreadMessagesStream().listen((allUnreadMessages) {
      // Filter out messages SENT by the current user
      final newMessages = allUnreadMessages.where((m) => m['sender_id'] != userId).toList();
      // Map counts by bookingId
      final Map<String, int> counts = {};
      for (var json in newMessages) {
        final bId = json['booking_id'] as String;
        counts[bId] = (counts[bId] ?? 0) + 1;
      }
      
      _unreadCounts = counts;
      _totalUnread = newMessages.length;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String bookingId) async {
    await ChatService.markAsRead(bookingId, userId);
    // Local update to avoid flicker while waiting for stream
    _unreadCounts.remove(bookingId);
    _totalUnread = _unreadCounts.values.fold(0, (sum, val) => sum + val);
    notifyListeners();
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    super.dispose();
  }
}
