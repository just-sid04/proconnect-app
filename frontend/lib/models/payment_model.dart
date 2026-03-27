import '../utils/supabase_mapper.dart';

enum PaymentStatus { pending, success, failed, refunded }

enum PaymentType { advance_20, final_80, full }

class Payment {
  final String id;
  final String bookingId;
  final String customerId;
  final String providerId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentType type;
  final String? transactionId;
  final String? paymentId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.type,
    this.transactionId,
    this.paymentId,
    this.metadata = const {},
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final mapped = supabaseRowToJson(json);
    return Payment(
      id: mapped['id'],
      bookingId: mapped['bookingId'],
      customerId: mapped['customerId'],
      providerId: mapped['providerId'],
      amount: (mapped['amount'] as num).toDouble(),
      currency: mapped['currency'] ?? 'INR',
      status: _parseStatus(mapped['status']),
      type: _parseType(mapped['paymentType']),
      transactionId: mapped['transactionId'],
      paymentId: mapped['paymentId'],
      metadata: mapped['metadata'] ?? {},
      createdAt: DateTime.parse(mapped['createdAt']),
    );
  }

  static PaymentStatus _parseStatus(String? status) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => PaymentStatus.pending,
    );
  }

  static PaymentType _parseType(String? type) {
    return PaymentType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => PaymentType.full,
    );
  }
}
