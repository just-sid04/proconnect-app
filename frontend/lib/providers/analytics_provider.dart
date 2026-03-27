import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Map<String, dynamic>? _providerStats;
  Map<String, dynamic>? get providerStats => _providerStats;

  List<Map<String, dynamic>> _categoryStats = [];
  List<Map<String, dynamic>> get categoryStats => _categoryStats;

  /// Load stats for a specific provider
  Future<void> loadProviderStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw 'Not authenticated';

      // Fetch from the provider_stats view
      final data = await _client
          .from('provider_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      _providerStats = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load global category performance (for admins or general insights)
  Future<void> loadCategoryPerformance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _client.from('category_performance').select();
      _categoryStats = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch heatmap data for a given region
  Future<List<Map<String, dynamic>>> getHeatmapData({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      final response = await _client.rpc('get_demand_heatmap', params: {
        'min_lat': minLat,
        'max_lat': maxLat,
        'min_lng': minLng,
        'max_lng': maxLng,
        'precision_digits': 3,
      });

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('❌ Error fetching heatmap: $e');
      return [];
    }
  }
}
