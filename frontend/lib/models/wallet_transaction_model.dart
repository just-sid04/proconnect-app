class WalletTransaction {
  final String id;
  final String userId;
  final double amount;
  final String type; // credit, debit
  final String source; // referral, booking_payment, refund, bonus, admin
  final String? description;
  final String? referenceId;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.source,
    this.description,
    this.referenceId,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'credit',
      source: json['source'] ?? 'bonus',
      description: json['description'],
      referenceId: json['reference_id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'source': source,
      'description': description,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
