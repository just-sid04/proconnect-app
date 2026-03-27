import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import 'dart:async';
import 'event_service.dart';

class PaymentService {
  final _supabase = Supabase.instance.client;

  /// Simulates the Razorpay payment flow.
  /// 1. Creates a pending payment record.
  /// 2. Mimics network delay.
  /// 3. Updates payment to success and flags the booking as paid.
  Future<bool> simulatePayment({
    required String bookingId,
    required String customerId,
    required String providerId,
    required double amount,
    required PaymentType type,
  }) async {
    try {
      // 1. Create Initial Pending Record
      final txId = 'sim_order_${DateTime.now().millisecondsSinceEpoch}';
      
      final res = await _supabase.from('payments').insert({
        'booking_id': bookingId,
        'customer_id': customerId,
        'provider_id': providerId,
        'amount': amount,
        'status': 'pending',
        'payment_type': type.name,
        'transaction_id': txId,
      }).select().single();

      final paymentId = res['id'];

      // 2. Simulate User Interaction / Network Delay
      await Future.delayed(const Duration(seconds: 2));

      // 3. Update to Success
      final mockPayId = 'sim_pay_${DateTime.now().millisecondsSinceEpoch}';
      await _supabase.from('payments').update({
        'status': 'success',
        'payment_id': mockPayId,
      }).eq('id', paymentId);

      EventService.logPaymentSuccess(mockPayId, amount);

      // 4. Update Booking Table Flags
      final updateData = <String, dynamic>{};
      if (type == PaymentType.advance_20) {
        updateData['advance_paid'] = true;
      } else if (type == PaymentType.final_80) {
        updateData['final_paid'] = true;
      }
      
      await _supabase.from('bookings').update(updateData).eq('id', bookingId);

      return true;
    } catch (e) {
      print('Payment Simulation Error: $e');
      return false;
    }
  }

  /// Fetches payments for a specific booking.
  Future<List<Payment>> getPaymentsForBooking(String bookingId) async {
    final res = await _supabase
        .from('payments')
        .select()
        .eq('booking_id', bookingId)
        .order('created_at');
    
    return (res as List).map((json) => Payment.fromJson(json)).toList();
  }
}
