import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class EventService {
  static final _client = SupabaseService.instance.client;

  /// Log a specific event to the database.
  /// [eventType] is the name of the event (e.g. 'booking_created')
  /// [metadata] is an optional map of extra data (e.g. {'provider_id': '...'})
  static Future<void> logEvent(String eventType, [Map<String, dynamic>? metadata]) async {
    try {
      final userId = _client.auth.currentUser?.id;
      
      await _client.from('events').insert({
        'user_id': userId,
        'event_type': eventType,
        'metadata': metadata ?? {},
      });
      
      if (kDebugMode) {
        print('📊 Event Logged: $eventType | Metadata: $metadata');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging event: $e');
      }
    }
  }

  /// Convenience methods for common events
  static Future<void> logAppOpen() => logEvent('app_open');
  
  static Future<void> logProfileView(String providerId) => 
      logEvent('profile_view', {'provider_id': providerId});
      
  static Future<void> logCategoryClick(String categoryId, String categoryName) => 
      logEvent('category_click', {'category_id': categoryId, 'category_name': categoryName});
      
  static Future<void> logBookingCreated(String bookingId, String categoryId) => 
      logEvent('booking_created', {'booking_id': bookingId, 'category_id': categoryId});

  static Future<void> logPaymentSuccess(String paymentId, double amount) => 
      logEvent('payment_success', {'payment_id': paymentId, 'amount': amount});
}
