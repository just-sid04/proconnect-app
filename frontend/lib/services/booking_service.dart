import '../models/booking_model.dart';
import '../utils/constants.dart';
import '../utils/supabase_mapper.dart';
import 'api_service.dart';
import 'supabase_service.dart';

class BookingService {
  final ApiService _api = ApiService();

  bool get _useSupabase => AppConstants.useSupabase;
  dynamic get _sb => SupabaseService.instance.client;

  // Get all bookings for current user
  Future<ApiResponse<List<Booking>>> getBookings({
    String? status,
    String role = 'customer',
    int page = 1,
    int limit = 10,
  }) async {
    if (_useSupabase) {
      try {
        final userId = _sb.auth.currentUser?.id;
        if (userId == null) return ApiResponse.error('Not authenticated');

        var query = _sb
            .from('bookings')
            .select('*, customer:profiles!customer_id(*), provider:service_providers!provider_id(*, user:profiles!user_id(*), category:categories!category_id(*))')
            .order('created_at', ascending: false)
            .range((page - 1) * limit, page * limit - 1);

        if (role == 'customer') {
          query = query.eq('customer_id', userId);
        } else {
          final providers = await _sb.from('service_providers').select('id').eq('user_id', userId);
          final providerIds = (providers as List)
              .map((p) => ((p as Map)['id'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toList();
          if (providerIds.isEmpty) return ApiResponse.success([]);
          query = query.in_('provider_id', providerIds);
        }
        if (status != null) query = query.eq('status', status);

        final data = await query;
        final list = (data as List)
            .map((r) => Booking.fromJson(supabaseRowToJson(Map<String, dynamic>.from(r as Map))))
            .toList();
        return ApiResponse.success(list);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.get('/bookings', queryParams: {
      if (status != null) 'status': status,
      'role': role,
      'page': page,
      'limit': limit,
    });

    if (response.success) {
      final List<dynamic> bookingsJson = response.data ?? [];
      final bookings = bookingsJson.map((json) => Booking.fromJson(json)).toList();
      return ApiResponse.success(bookings, message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Get booking by ID
  Future<ApiResponse<Booking>> getBookingById(String id) async {
    if (_useSupabase) {
      try {
        final data = await _sb
            .from('bookings')
            .select('*, customer:profiles!customer_id(*), provider:service_providers!provider_id(*, user:profiles!user_id(*), category:categories!category_id(*))')
            .eq('id', id)
            .maybeSingle();
        if (data == null) return ApiResponse.error('Booking not found');
        return ApiResponse.success(
            Booking.fromJson(supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.get('/bookings/$id');

    if (response.success) {
      return ApiResponse.success(Booking.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Create new booking
  Future<ApiResponse<Booking>> createBooking({
    required String providerId,
    required String categoryId,
    required String description,
    required Location serviceLocation,
    required String scheduledDate,
    required String scheduledTime,
    int? estimatedDuration,
    String? notes,
  }) async {
    if (_useSupabase) {
      try {
        final customerId = _sb.auth.currentUser?.id;
        if (customerId == null) return ApiResponse.error('Not authenticated');

        final provider = await _sb.from('service_providers').select('hourly_rate').eq('id', providerId).single();
        final hourlyRate = (provider as Map)['hourly_rate'] as num? ?? 0.0;
        final hours = estimatedDuration ?? 2;
        final totalAmount = hourlyRate * hours;

        final row = {
          'customer_id': customerId,
          'provider_id': providerId,
          'category_id': categoryId,
          'description': description,
          'service_location': serviceLocation.toJson(),
          'scheduled_date': scheduledDate,
          'scheduled_time': scheduledTime,
          'estimated_duration': hours,
          'price': {
            'hourlyRate': hourlyRate,
            'estimatedHours': hours,
            'totalAmount': totalAmount,
            'materialsCost': 0,
          },
          'notes': notes ?? '',
        };

        final data = await _sb.from('bookings').insert(row).select('*, customer:profiles!customer_id(*), provider:service_providers!provider_id(*, user:profiles!user_id(*), category:categories!category_id(*))').single();
        return ApiResponse.success(
            Booking.fromJson(supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.post('/bookings', body: {
      'providerId': providerId,
      'categoryId': categoryId,
      'description': description,
      'serviceLocation': serviceLocation.toJson(),
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'estimatedDuration': estimatedDuration ?? 2,
      'notes': notes,
    });

    if (response.success) {
      return ApiResponse.success(Booking.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Update booking status
  Future<ApiResponse<Booking>> updateBookingStatus({
    required String id,
    required String status,
    String? cancellationReason,
  }) async {
    if (_useSupabase) {
      try {
        final updates = <String, dynamic>{
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (status == 'accepted') updates['accepted_at'] = DateTime.now().toIso8601String();
        if (status == 'in-progress') updates['started_at'] = DateTime.now().toIso8601String();
        if (status == 'completed') updates['completed_at'] = DateTime.now().toIso8601String();
        if (status == 'cancelled') {
          updates['cancelled_at'] = DateTime.now().toIso8601String();
          if (cancellationReason != null) updates['cancellation_reason'] = cancellationReason;
        }

        final data = await _sb
            .from('bookings')
            .update(updates)
            .eq('id', id)
            .select('*, customer:profiles!customer_id(*), provider:service_providers!provider_id(*, user:profiles!user_id(*), category:categories!category_id(*))')
            .single();
        return ApiResponse.success(
            Booking.fromJson(supabaseRowToJson(Map<String, dynamic>.from(data as Map))));
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final body = <String, dynamic>{'status': status};
    if (cancellationReason != null) {
      body['cancellationReason'] = cancellationReason;
    }

    final response = await _api.put('/bookings/$id/status', body: body);

    if (response.success) {
      return ApiResponse.success(Booking.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Update booking details
  Future<ApiResponse<Booking>> updateBooking({
    required String id,
    String? description,
    Location? serviceLocation,
    String? scheduledDate,
    String? scheduledTime,
    int? estimatedDuration,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (serviceLocation != null) body['serviceLocation'] = serviceLocation.toJson();
    if (scheduledDate != null) body['scheduledDate'] = scheduledDate;
    if (scheduledTime != null) body['scheduledTime'] = scheduledTime;
    if (estimatedDuration != null) body['estimatedDuration'] = estimatedDuration;
    if (notes != null) body['notes'] = notes;

    final response = await _api.put('/bookings/$id', body: body);

    if (response.success) {
      return ApiResponse.success(Booking.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Delete booking
  Future<ApiResponse<void>> deleteBooking(String id) async {
    if (_useSupabase) {
      try {
        await _sb.from('bookings').delete().eq('id', id);
        return ApiResponse.success(null);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.delete('/bookings/$id');

    if (response.success) {
      return ApiResponse.success(null, message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Accept booking (provider only)
  Future<ApiResponse<Booking>> acceptBooking(String id) async {
    return updateBookingStatus(id: id, status: 'accepted');
  }

  // Start booking (provider only)
  Future<ApiResponse<Booking>> startBooking(String id) async {
    return updateBookingStatus(id: id, status: 'in-progress');
  }

  // Complete booking (provider only)
  Future<ApiResponse<Booking>> completeBooking(String id) async {
    return updateBookingStatus(id: id, status: 'completed');
  }

  // Cancel booking
  Future<ApiResponse<Booking>> cancelBooking(String id, {String? reason}) async {
    return updateBookingStatus(
      id: id,
      status: 'cancelled',
      cancellationReason: reason,
    );
  }
}
