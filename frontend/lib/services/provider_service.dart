import '../models/provider_model.dart';
import '../utils/constants.dart';
import '../utils/supabase_mapper.dart';
import 'api_service.dart';
import 'supabase_service.dart';

class ProviderService {
  final ApiService _api = ApiService();

  bool get _useSupabase => AppConstants.useSupabase;
  dynamic get _sb => SupabaseService.instance.client;

  // Get all providers with filters
  Future<ApiResponse<List<ServiceProvider>>> getProviders({
    String? category,
    double? minRating,
    double? maxRate,
    List<String>? skills,
    bool? verified,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    if (_useSupabase) {
      try {
        var query = _sb
            .from('service_providers')
            .select('*, user:profiles!user_id(*), category:categories!category_id(*)')
            .order('rating', ascending: false)
            .range((page - 1) * limit, page * limit - 1);

        if (category != null) query = query.eq('category_id', category);
        if (minRating != null) query = query.gte('rating', minRating);
        if (maxRate != null) query = query.lte('hourly_rate', maxRate);
        if (verified == true) query = query.eq('is_verified', true);
        if (search != null && search.isNotEmpty) {
          final term = search.replaceAll('%', '\\%');
          query = query.ilike('description', '%$term%');
        }

        final data = await query;
        final providers = (data as List)
            .map((r) => ServiceProvider.fromJson(
                supabaseRowToJson(Map<String, dynamic>.from(r as Map))))
            .toList();
        return ApiResponse.success(providers);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (category != null) 'category': category,
      if (minRating != null) 'minRating': minRating,
      if (maxRate != null) 'maxRate': maxRate,
      if (skills != null) 'skills': skills.join(','),
      if (verified != null) 'verified': verified,
      if (search != null) 'q': search,
    };

    final response = await _api.get('/providers', queryParams: queryParams);

    if (response.success) {
      final List<dynamic> providersJson = response.data ?? [];
      final providers = providersJson.map((json) => ServiceProvider.fromJson(json)).toList();
      return ApiResponse.success(providers, message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Get nearby providers
  Future<ApiResponse<List<ServiceProvider>>> getNearbyProviders({
    required double latitude,
    required double longitude,
    double radius = 10,
    int page = 1,
    int limit = 10,
  }) async {
    if (_useSupabase) {
      // Geo filtering requires PostGIS - use getProviders for now
      return getProviders(page: page, limit: limit);
    }

    final response = await _api.get('/providers/nearby', queryParams: {
      'lat': latitude,
      'lng': longitude,
      'radius': radius,
      'page': page,
      'limit': limit,
    });

    if (response.success) {
      final List<dynamic> providersJson = response.data ?? [];
      final providers = providersJson.map((json) => ServiceProvider.fromJson(json)).toList();
      return ApiResponse.success(providers, message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Get provider by ID
  Future<ApiResponse<ServiceProvider>> getProviderById(String id) async {
    if (_useSupabase) {
      try {
        final data = await _sb
            .from('service_providers')
            .select('*, user:profiles!user_id(*), category:categories!category_id(*)')
            .eq('id', id)
            .maybeSingle();
        if (data == null) return ApiResponse.error('Provider not found');
        return ApiResponse.success(ServiceProvider.fromJson(
            supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.get('/providers/$id');

    if (response.success) {
      return ApiResponse.success(ServiceProvider.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Create provider profile
  Future<ApiResponse<ServiceProvider>> createProviderProfile({
    required String categoryId,
    required List<String> skills,
    required int experience,
    double? hourlyRate,
    String? description,
    int? serviceArea,
    Availability? availability,
  }) async {
    if (_useSupabase) {
      try {
        final userId = _sb.auth.currentUser?.id;
        if (userId == null) return ApiResponse.error('Not authenticated');

        final row = {
          'user_id': userId,
          'category_id': categoryId,
          'skills': skills,
          'experience': experience,
          'hourly_rate': hourlyRate ?? 0,
          'description': description ?? '',
          'service_area': serviceArea ?? 10,
          'availability': availability?.toJson() ?? {},
        };

        final data = await _sb.from('service_providers').insert(row).select('*, user:profiles!user_id(*), category:categories!category_id(*)').single();
        return ApiResponse.success(ServiceProvider.fromJson(
            supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.post('/providers', body: {
      'categoryId': categoryId,
      'skills': skills,
      'experience': experience,
      'hourlyRate': hourlyRate,
      'description': description,
      'serviceArea': serviceArea,
      'availability': availability?.toJson(),
    });

    if (response.success) {
      return ApiResponse.success(ServiceProvider.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Update provider profile
  Future<ApiResponse<ServiceProvider>> updateProviderProfile({
    required String id,
    List<String>? skills,
    int? experience,
    double? hourlyRate,
    String? description,
    int? serviceArea,
    Availability? availability,
  }) async {
    if (_useSupabase) {
      try {
        final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
        if (skills != null) updates['skills'] = skills;
        if (experience != null) updates['experience'] = experience;
        if (hourlyRate != null) updates['hourly_rate'] = hourlyRate;
        if (description != null) updates['description'] = description;
        if (serviceArea != null) updates['service_area'] = serviceArea;
        if (availability != null) updates['availability'] = availability.toJson();

        final data = await _sb
            .from('service_providers')
            .update(updates)
            .eq('id', id)
            .select('*, user:profiles!user_id(*), category:categories!category_id(*)')
            .single();
        return ApiResponse.success(ServiceProvider.fromJson(
            supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final body = <String, dynamic>{};
    if (skills != null) body['skills'] = skills;
    if (experience != null) body['experience'] = experience;
    if (hourlyRate != null) body['hourlyRate'] = hourlyRate;
    if (description != null) body['description'] = description;
    if (serviceArea != null) body['serviceArea'] = serviceArea;
    if (availability != null) body['availability'] = availability.toJson();

    final response = await _api.put('/providers/$id', body: body);

    if (response.success) {
      return ApiResponse.success(ServiceProvider.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Update availability
  Future<ApiResponse<Availability>> updateAvailability(String id, Availability availability) async {
    if (_useSupabase) {
      try {
        await _sb
            .from('service_providers')
            .update({'availability': availability.toJson(), 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', id);
        return ApiResponse.success(availability);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.put('/providers/$id/availability', body: {
      'availability': availability.toJson(),
    });

    if (response.success) {
      return ApiResponse.success(Availability.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Get my provider profile
  Future<ApiResponse<ServiceProvider>> getMyProviderProfile() async {
    if (_useSupabase) {
      try {
        final userId = _sb.auth.currentUser?.id;
        if (userId == null) return ApiResponse.error('Not authenticated');

        final data = await _sb
            .from('service_providers')
            .select('*, user:profiles!user_id(*), category:categories!category_id(*)')
            .eq('user_id', userId)
            .maybeSingle();
        if (data == null) return ApiResponse.error('Provider profile not found');
        return ApiResponse.success(ServiceProvider.fromJson(
            supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.get('/providers/me/profile');

    if (response.success) {
      return ApiResponse.success(ServiceProvider.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Delete provider profile
  Future<ApiResponse<void>> deleteProviderProfile(String id) async {
    if (_useSupabase) {
      try {
        await _sb.from('service_providers').delete().eq('id', id);
        return ApiResponse.success(null);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.delete('/providers/$id');

    if (response.success) {
      return ApiResponse.success(null, message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Get all categories
  Future<ApiResponse<List<Category>>> getCategories() async {
    if (_useSupabase) {
      try {
        final data = await _sb.from('categories').select().eq('is_active', true);
        final list = (data as List)
            .map((r) => Category.fromJson(supabaseRowToJson(Map<String, dynamic>.from(r as Map))))
            .toList();
        return ApiResponse.success(list);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.get('/categories');

    if (response.success) {
      final List<dynamic> categoriesJson = response.data ?? [];
      final categories = categoriesJson.map((json) => Category.fromJson(json)).toList();
      return ApiResponse.success(categories, message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Get category by ID
  Future<ApiResponse<Category>> getCategoryById(String id) async {
    if (_useSupabase) {
      try {
        final data = await _sb.from('categories').select().eq('id', id).maybeSingle();
        if (data == null) return ApiResponse.error('Category not found');
        return ApiResponse.success(
            Category.fromJson(supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.get('/categories/$id');

    if (response.success) {
      return ApiResponse.success(Category.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Get providers by category
  Future<ApiResponse<List<ServiceProvider>>> getProvidersByCategory(
    String categoryId, {
    bool? verified,
    int page = 1,
    int limit = 10,
  }) async {
    if (_useSupabase) {
      return getProviders(
        category: categoryId,
        verified: verified,
        page: page,
        limit: limit,
      );
    }

    final response = await _api.get('/categories/$categoryId/providers', queryParams: {
      'verified': verified,
      'page': page,
      'limit': limit,
    });

    if (response.success) {
      final List<dynamic> providersJson = response.data ?? [];
      final providers = providersJson.map((json) => ServiceProvider.fromJson(json)).toList();
      return ApiResponse.success(providers, message: response.message);
    }

    return ApiResponse.error(response.message);
  }
}
