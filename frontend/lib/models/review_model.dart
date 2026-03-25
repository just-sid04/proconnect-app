import 'user_model.dart';
import 'provider_model.dart';

class Review {
  final String id;
  final String bookingId;
  final String customerId;
  final String providerId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? customer;
  final ServiceProvider? provider;

  Review({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.provider,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      customerId: json['customerId'] ?? '',
      providerId: json['providerId'] ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      customer: json['customer'] != null ? User.fromJson(json['customer']) : null,
      provider: json['provider'] != null ? ServiceProvider.fromJson(json['provider']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'customerId': customerId,
      'providerId': providerId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class RatingSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  RatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    final distribution = json['ratingDistribution'] ?? {};
    return RatingSummary(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: {
        5: distribution['5'] ?? 0,
        4: distribution['4'] ?? 0,
        3: distribution['3'] ?? 0,
        2: distribution['2'] ?? 0,
        1: distribution['1'] ?? 0,
      },
    );
  }
}
