import '../models/message_model.dart';
import 'supabase_service.dart';

class ChatService {
  static final client = SupabaseService.instance.client;

  /// Stream of messages for a specific booking
  static Stream<List<Message>> getMessagesStream(String bookingId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
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
}
