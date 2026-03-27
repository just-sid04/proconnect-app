import '../models/message_model.dart';
import 'supabase_service.dart';

class ChatService {
  static final client = SupabaseService.instance.client;

  /// Stream of messages for a specific booking using standard .stream()
  static Stream<List<Message>> getMessagesStream(String bookingId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .map((data) {
          final msgs = data.map((json) => Message.fromJson(json)).toList();
          // Sort in Dart to ensure consistency
          msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return msgs;
        });
  }

  /// Send a message
  static Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String text,
  }) async {
    await client.from('messages').insert({
      'booking_id': bookingId,
      'sender_id': senderId,
      'text': text,
    });
  }

  /// Mark all messages in a booking as read for the reader
  static Future<void> markAsRead(String bookingId, String readerId) async {
    await client
        .from('messages')
        .update({'is_read': true})
        .eq('booking_id', bookingId)
        .neq('sender_id', readerId)
        .eq('is_read', false);
  }

  /// Stream of unread message counts for the current user
  /// Filtering messages for bookings where the user is a participant
  static Stream<List<Map<String, dynamic>>> getUnreadMessagesStream() {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('is_read', false);
  }
}
