import '../models/booking_model.dart';
import '../utils/constants.dart';
import '../utils/supabase_mapper.dart';
import 'api_service.dart';
import 'supabase_service.dart';

/// Supabase PostgREST join string used for all booking queries.
/// CRITICAL: PostgREST does NOT allow whitespace inside the selection parens.
/// Any space inside a nested (...) will silently break the entire query.
const _kBookingJoin =
    '*,'
    'customer:profiles!customer_id(id,name,email,phone,profile_photo,role,location),'
    'provider:service_providers!provider_id('
    'id,user_id,category_id,hourly_rate,rating,total_reviews,total_bookings,'
    'description,skills,service_area,experience,is_verified,verification_status,'
    'user:profiles!user_id(id,name,email,phone,profile_photo,role,location),'
    'category:categories!category_id(id,name,icon,color)'
    ')';

class BookingService {
  final ApiService _api = ApiService();

  bool get _useSupabase => AppConstants.useSupabase;
  dynamic get _sb => SupabaseService.instance.client;

  // ─── GET ALL BOOKINGS ───────────────────────────────────────────────────────

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

        // Build filter first (before .order() — filters must come before transforms)
        dynamic query = _sb
            .from('bookings')
            .select(_kBookingJoin);

        if (role == 'customer') {
          query = query.eq('customer_id', userId);
        } else {
          // Provider: resolve provider row ID first
          final providerData = await _sb
              .from('service_providers')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();
          if (providerData == null) return ApiResponse.success([]);
          final providerId = (providerData as Map)['id'] as String;
          query = query.eq('provider_id', providerId);
        }

        if (status != null) query = query.eq('status', status);

        // Apply ordering last (PostgrestTransformBuilder)
        final data = await query.order('created_at', ascending: false);
        final list = (data as List)
            .map((r) => Booking.fromJson(
                  supabaseRowToJson(Map<String, dynamic>.from(r as Map)),
                ))
            .toList();
        return ApiResponse.success(list);
      } catch (e) {
        return ApiResponse.error('Failed to load bookings: $e');
      }
    }

    // ── Legacy REST path ──
    final response = await _api.get('/bookings', queryParams: {
      if (status != null) 'status': status,
      'role': role,
      'page': page,
      'limit': limit,
    });
    if (response.success) {
      final bookings = (response.data as List? ?? [])
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(bookings, message: response.message);
    }
    return ApiResponse.error(response.message);
  }

  // ─── GET BOOKING BY ID ──────────────────────────────────────────────────────

  Future<ApiResponse<Booking>> getBookingById(String id) async {
    if (_useSupabase) {
      try {
        final data = await _sb
            .from('bookings')
            .select(_kBookingJoin)
            .eq('id', id)
            .maybeSingle();
        if (data == null) return ApiResponse.error('Booking not found');
        return ApiResponse.success(
          Booking.fromJson(supabaseRowToJson(Map<String, dynamic>.from(data as Map))),
        );
      } catch (e) {
        return ApiResponse.error('Failed to load booking: $e');
      }
    }

    final response = await _api.get('/bookings/$id');
    if (response.success) {
      return ApiResponse.success(
        Booking.fromJson(response.data as Map<String, dynamic>),
        message: response.message,
      );
    }
    return ApiResponse.error(response.message);
  }

  // ─── CREATE BOOKING ─────────────────────────────────────────────────────────

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

        final providerRow = await _sb
            .from('service_providers')
            .select('hourly_rate')
            .eq('id', providerId)
            .single();
        final hourlyRate = (providerRow as Map)['hourly_rate'] as num? ?? 0.0;
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

        final data = await _sb
            .from('bookings')
            .insert(row)
            .select(_kBookingJoin)
            .single();
        return ApiResponse.success(
          Booking.fromJson(supabaseRowToJson(Map<String, dynamic>.from(data as Map))),
        );
      } catch (e) {
        return ApiResponse.error('Failed to create booking: $e');
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
      return ApiResponse.success(
        Booking.fromJson(response.data as Map<String, dynamic>),
        message: response.message,
      );
    }
    return ApiResponse.error(response.message);
  }

  // ─── UPDATE BOOKING STATUS ──────────────────────────────────────────────────

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
        if (status == 'accepted') {
          updates['accepted_at'] = DateTime.now().toIso8601String();
        }
        if (status == 'in-progress') {
          updates['started_at'] = DateTime.now().toIso8601String();
        }
        if (status == 'completed') {
          updates['completed_at'] = DateTime.now().toIso8601String();
        }
        if (status == 'cancelled') {
          updates['cancelled_at'] = DateTime.now().toIso8601String();
          if (cancellationReason != null) {
            updates['cancellation_reason'] = cancellationReason;
          }
        }

        // Step 1: Update the record
        await _sb.from('bookings').update(updates).eq('id', id);

        // Step 2: Re-fetch with full join (avoids the broken chained .select() issue)
        final data = await _sb
            .from('bookings')
            .select(_kBookingJoin)
            .eq('id', id)
            .single();

        return ApiResponse.success(
          Booking.fromJson(supabaseRowToJson(Map<String, dynamic>.from(data as Map))),
        );
      } catch (e) {
        return ApiResponse.error('Failed to update booking: $e');
      }
    }

    final body = <String, dynamic>{'status': status};
    if (cancellationReason != null) body['cancellationReason'] = cancellationReason;

    final response = await _api.put('/bookings/$id/status', body: body);
    if (response.success) {
      return ApiResponse.success(
        Booking.fromJson(response.data as Map<String, dynamic>),
        message: response.message,
      );
    }
    return ApiResponse.error(response.message);
  }

  // ─── DELETE BOOKING ─────────────────────────────────────────────────────────

  Future<ApiResponse<void>> deleteBooking(String id) async {
    if (_useSupabase) {
      try {
        await _sb.from('bookings').delete().eq('id', id);
        return ApiResponse.success(null);
      } catch (e) {
        return ApiResponse.error('Failed to delete booking: $e');
      }
    }

    final response = await _api.delete('/bookings/$id');
    if (response.success) return ApiResponse.success(null, message: response.message);
    return ApiResponse.error(response.message);
  }

  // ─── CONVENIENCE SHORTCUTS ──────────────────────────────────────────────────

  Future<ApiResponse<Booking>> acceptBooking(String id) =>
      updateBookingStatus(id: id, status: 'accepted');

  Future<ApiResponse<Booking>> startBooking(String id) =>
      updateBookingStatus(id: id, status: 'in-progress');

  Future<ApiResponse<Booking>> completeBooking(String id) =>
      updateBookingStatus(id: id, status: 'completed');

  Future<ApiResponse<Booking>> cancelBooking(String id, {String? reason}) =>
      updateBookingStatus(id: id, status: 'cancelled', cancellationReason: reason);

  // ─── UPDATE BOOKING DETAILS ─────────────────────────────────────────────────

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
      return ApiResponse.success(
        Booking.fromJson(response.data as Map<String, dynamic>),
        message: response.message,
      );
    }
    return ApiResponse.error(response.message);
  }
}
