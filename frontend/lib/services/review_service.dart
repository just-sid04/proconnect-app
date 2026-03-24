import '../models/review_model.dart';
import '../utils/constants.dart';
import '../utils/supabase_mapper.dart';
import 'api_service.dart';
import 'supabase_service.dart';

class ReviewService {
  final ApiService _api = ApiService();

  bool get _useSupabase => AppConstants.useSupabase;
  dynamic get _sb => SupabaseService.instance.client;

  // Get all reviews
  Future<ApiResponse<List<Review>>> getReviews({
    String? providerId,
    String? customerId,
    int page = 1,
    int limit = 10,
  }) async {
    if (_useSupabase) {
      try {
        var query = _sb
            .from('reviews')
            .select('*, customer:profiles!customer_id(*), provider:service_providers!provider_id(*, user:profiles!user_id(*), category:categories!category_id(*))')
            .order('created_at', ascending: false)
            .range((page - 1) * limit, page * limit - 1);
        if (providerId != null) query = query.eq('provider_id', providerId);
        if (customerId != null) query = query.eq('customer_id', customerId);

        final data = await query;
        final list = (data as List)
            .map((r) => Review.fromJson(supabaseRowToJson(Map<String, dynamic>.from(r as Map))))
            .toList();
        return ApiResponse.success(list);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.get('/reviews', queryParams: {
      if (providerId != null) 'providerId': providerId,
      if (customerId != null) 'customerId': customerId,
      'page': page,
      'limit': limit,
    });

    if (response.success) {
      final List<dynamic> reviewsJson = response.data ?? [];
      final reviews = reviewsJson.map((json) => Review.fromJson(json)).toList();
      return ApiResponse.success(reviews, message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Get review by ID
  Future<ApiResponse<Review>> getReviewById(String id) async {
    if (_useSupabase) {
      try {
        final data = await _sb
            .from('reviews')
            .select('*, customer:profiles!customer_id(*), provider:service_providers!provider_id(*, user:profiles!user_id(*), category:categories!category_id(*))')
            .eq('id', id)
            .maybeSingle();
        if (data == null) return ApiResponse.error('Review not found');
        return ApiResponse.success(
            Review.fromJson(supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.get('/reviews/$id');

    if (response.success) {
      return ApiResponse.success(Review.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Create new review
  Future<ApiResponse<Review>> createReview({
    required String bookingId,
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    if (_useSupabase) {
      try {
        final customerId = _sb.auth.currentUser?.id;
        if (customerId == null) return ApiResponse.error('Not authenticated');

        final row = {
          'booking_id': bookingId,
          'customer_id': customerId,
          'provider_id': providerId,
          'rating': rating,
          'comment': comment ?? '',
        };

        final data = await _sb.from('reviews').insert(row).select('*, customer:profiles!customer_id(*), provider:service_providers!provider_id(*, user:profiles!user_id(*), category:categories!category_id(*))').single();
        return ApiResponse.success(
            Review.fromJson(supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.post('/reviews', body: {
      'bookingId': bookingId,
      'providerId': providerId,
      'rating': rating,
      'comment': comment,
    });

    if (response.success) {
      return ApiResponse.success(Review.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Update review
  Future<ApiResponse<Review>> updateReview({
    required String id,
    int? rating,
    String? comment,
  }) async {
    if (_useSupabase) {
      try {
        final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
        if (rating != null) updates['rating'] = rating;
        if (comment != null) updates['comment'] = comment;

        final data = await _sb
            .from('reviews')
            .update(updates)
            .eq('id', id)
            .select('*, customer:profiles!customer_id(*), provider:service_providers!provider_id(*, user:profiles!user_id(*), category:categories!category_id(*))')
            .single();
        return ApiResponse.success(
            Review.fromJson(supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (comment != null) body['comment'] = comment;

    final response = await _api.put('/reviews/$id', body: body);

    if (response.success) {
      return ApiResponse.success(Review.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Delete review
  Future<ApiResponse<void>> deleteReview(String id) async {
    if (_useSupabase) {
      try {
        await _sb.from('reviews').delete().eq('id', id);
        return ApiResponse.success(null);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.delete('/reviews/$id');

    if (response.success) {
      return ApiResponse.success(null, message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Get provider rating summary
  Future<ApiResponse<RatingSummary>> getProviderRatingSummary(String providerId) async {
    if (_useSupabase) {
      try {
        final data = await _sb.from('reviews').select('rating').eq('provider_id', providerId);
        final list = data as List;
        if (list.isEmpty) {
          return ApiResponse.success(RatingSummary(averageRating: 0, totalReviews: 0, ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0}));
        }
        final ratings = list.map((r) => (r as Map)['rating'] as int).toList();
        final total = ratings.length;
        final avg = ratings.reduce((a, b) => a + b) / total;
        final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        for (final r in ratings) {
          dist[r] = (dist[r] ?? 0) + 1;
        }
        return ApiResponse.success(RatingSummary(
          averageRating: avg,
          totalReviews: total,
          ratingDistribution: dist,
        ));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.get('/reviews/summary/$providerId');

    if (response.success) {
      return ApiResponse.success(RatingSummary.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }
}
