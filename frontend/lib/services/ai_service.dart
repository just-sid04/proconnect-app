import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider_model.dart';
import 'supabase_service.dart';

class AiService {
  static SupabaseClient get _supabase => SupabaseService.instance.client;

  /// Fetches personalized category recommendations based on user booking history and platform popularity.
  static Future<List<Category>> getRecommendedCategories(String userId) async {
    try {
      // ignore: avoid_print
      print('AI Service: Fetching recommendations for $userId...');
      final List<dynamic> result = await _supabase.rpc(
        'get_user_recommendations',
        params: {'p_user_id': userId},
      );
      
      // ignore: avoid_print
      print('AI Service: Received ${result.length} categories');
      return result.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('AI Service Error (get_user_recommendations): $e');
      return [];
    }
  }

  /// Placeholder for future review summarization feature
  static Future<String?> summarizeReviews(String providerId) async {
    // This will eventually call an Edge Function or AI Model
    return null;
  }
}
