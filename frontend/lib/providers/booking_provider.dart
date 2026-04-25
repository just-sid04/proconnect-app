import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/supabase_service.dart';
import '../services/payment_service.dart';
import '../models/payment_model.dart';
import '../utils/constants.dart';
import '../services/provider_service.dart';
import '../utils/supabase_mapper.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<Booking> _bookings = [];
  Booking? _currentBooking;
  bool _isLoading = false;
  String? _error;

  // Cached provider row ID for the logged-in provider user
  String? _cachedProviderId;
  String? _lastRole; // tracks the last role so we can re-subscribe if changed

  // Separate realtime channels per role so they don't interfere
  RealtimeChannel? _customerChannel;
  RealtimeChannel? _providerChannel;

  // Reassignment Logic
  final Map<String, Timer> _acceptanceTimers = {};
  final Map<String, bool> _isSearching = {};
  final ProviderService _providerService = ProviderService();

  @override
  void dispose() {
    _customerChannel?.unsubscribe();
    _providerChannel?.unsubscribe();
    for (var timer in _acceptanceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  // ─── Getters ───────────────────────────────────────────────────────────────

  List<Booking> get bookings => _bookings;
  Booking? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isSearching(String bookingId) => _isSearching[bookingId] ?? false;

  List<Booking> getBookingsByStatus(String status) =>
      _bookings.where((b) => b.status == status).toList();

  List<Booking> get pendingBookings =>
      getBookingsByStatus(AppConstants.statusPending);

  List<Booking> get activeBookings => _bookings
      .where((b) =>
          b.status == AppConstants.statusAccepted ||
          b.status == AppConstants.statusInProgress)
      .toList();

  List<Booking> get completedBookings =>
      getBookingsByStatus(AppConstants.statusCompleted);

  List<Booking> get cancelledBookings =>
      getBookingsByStatus(AppConstants.statusCancelled);

  // ─── Load Bookings ─────────────────────────────────────────────────────────

  Future<void> loadBookings({
    String? status,
    String role = 'customer',
    bool refresh = false,
  }) async {
    // If already loading, skip duplicate calls
    if (_isLoading) return;

    debugPrint('BookingProvider: Loading bookings (role: $role, status: $status)');
    _setLoading(true);
    _error = null;

    try {
      final response = await _bookingService.getBookings(
        status: status,
        role: role,
      );

      if (response.success) {
        _bookings = response.data ?? [];
        _error = null;
        debugPrint('BookingProvider: Loaded ${_bookings.length} bookings');
      } else {
        _error = response.message;
        debugPrint('BookingProvider: Load failed - $_error');
      }
    } catch (e) {
      _error = 'Could not load bookings. Please try again.';
      debugPrint('BookingProvider: Load exception - $e');
    } finally {
      _setLoading(false);
    }

    // Setup realtime subscription (idempotent — only creates if needed)
    if (_lastRole != role || refresh) {
      _lastRole = role;
      await _setupRealtimeForRole(role);
    }
  }

  // ─── CRUD Operations ───────────────────────────────────────────────────────

  Future<bool> getBookingById(String id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _bookingService.getBookingById(id);
      if (response.success) {
        _currentBooking = response.data;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Could not load booking details.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createBooking({
    required String providerId,
    required String categoryId,
    required String description,
    required Location serviceLocation,
    required String scheduledDate,
    required String scheduledTime,
    int? estimatedDuration,
    String? notes,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _bookingService.createBooking(
        providerId: providerId,
        categoryId: categoryId,
        description: description,
        serviceLocation: serviceLocation,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        estimatedDuration: estimatedDuration,
        notes: notes,
      );

      if (response.success && response.data != null) {
        final booking = response.data!;
        // Insert at top only if not already present (realtime may have added it)
        if (!_bookings.any((b) => b.id == booking.id)) {
          _bookings.insert(0, booking);
        }
        _currentBooking = booking;
        _error = null;
        
        // Start reassignment timer for new pending booking
        if (booking.status == AppConstants.statusPending) {
          _startAcceptanceTimer(booking.id);
        }
        
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Could not create booking. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateBookingStatus({
    required String id,
    required String status,
    String? cancellationReason,
  }) async {
    final oldBookings = List<Booking>.from(_bookings);
    final index = _bookings.indexWhere((b) => b.id == id);
    
    debugPrint('BookingProvider: Updating status for $id to $status (Optimistic)');
    
    // --- OPTIMISTIC UI: Update local state immediately ---
    if (index != -1) {
      final oldBooking = _bookings[index];
      _bookings[index] = oldBooking.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      // This notification ensures the UI reflects the change INSTANTLY
      notifyListeners();

      // If status changed from pending, cancel timer
      if (status != AppConstants.statusPending) {
        _acceptanceTimers[id]?.cancel();
        _acceptanceTimers.remove(id);
      }
    }

    // Start background loading WITHOUT notifying again immediately
    _setLoading(true, notify: false);
    _error = null;

    try {
      final response = await _bookingService.updateBookingStatus(
        id: id,
        status: status,
        cancellationReason: cancellationReason,
      );

      if (response.success && response.data != null) {
        final updated = response.data!;
        debugPrint('BookingProvider: Status update confirmed by server');
        final idx = _bookings.indexWhere((b) => b.id == id);
        if (idx != -1) {
          _bookings[idx] = updated;
        } else {
          _bookings.insert(0, updated);
        }
        if (_currentBooking?.id == id) _currentBooking = updated;
        _error = null;
        notifyListeners();
        return true;
      } else {
        debugPrint('BookingProvider: Update failed, rolling back - ${response.message}');
        // --- ROLLBACK on failure ---
        _bookings = oldBookings;
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('BookingProvider: Update exception, rolling back - $e');
      _bookings = oldBookings;
      _error = 'Could not update booking. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptBooking(String id) =>
      updateBookingStatus(id: id, status: AppConstants.statusAccepted);

  Future<bool> startBooking(String id) =>
      updateBookingStatus(id: id, status: AppConstants.statusInProgress);

  Future<bool> completeBooking(String id) =>
      updateBookingStatus(id: id, status: AppConstants.statusCompleted);

  Future<bool> cancelBooking(String id, {String? reason}) =>
      updateBookingStatus(
        id: id,
        status: AppConstants.statusCancelled,
        cancellationReason: reason,
      );

  // ─── Payment Operations ───────────────────────────────────────────────────

  final _paymentService = PaymentService();

  Future<bool> payAdvance(Booking booking) async {
    _setLoading(true);
    _error = null;

    try {
      final success = await _paymentService.simulatePayment(
        bookingId: booking.id,
        customerId: booking.customerId,
        providerId: booking.provider?.userId ?? booking.providerId,
        amount: booking.price.totalAmount * 0.2, // 20% Advance
        type: PaymentType.advance_20,
      );

      if (success) {
        // Refresh to get updated flags (advance_paid)
        await getBookingById(booking.id);
        return true;
      } else {
        _error = 'Simulated payment failed.';
        return false;
      }
    } catch (e) {
      _error = 'Error during payment simulation.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> payBalance(Booking booking) async {
    _setLoading(true);
    _error = null;

    try {
      final success = await _paymentService.simulatePayment(
        bookingId: booking.id,
        customerId: booking.customerId,
        providerId: booking.provider?.userId ?? booking.providerId,
        amount: booking.price.totalAmount * 0.8, // 80% Balance
        type: PaymentType.final_80,
      );

      if (success) {
        // Refresh to get updated flags (final_paid)
        await getBookingById(booking.id);
        return true;
      } else {
        _error = 'Simulated payment failed.';
        return false;
      }
    } catch (e) {
      _error = 'Error during payment simulation.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteBooking(String id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _bookingService.deleteBooking(id);
      if (response.success) {
        _bookings.removeWhere((b) => b.id == id);
        if (_currentBooking?.id == id) _currentBooking = null;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Could not delete booking.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearCurrentBooking() {
    _currentBooking = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Full reset — call this on logout so stale bookings are cleared.
  void reset() {
    _customerChannel?.unsubscribe();
    _providerChannel?.unsubscribe();
    _customerChannel = null;
    _providerChannel = null;
    _cachedProviderId = null;
    _lastRole = null;
    _bookings = [];
    _currentBooking = null;
    _isLoading = false;
    _error = null;
    for (var timer in _acceptanceTimers.values) {
      timer.cancel();
    }
    _acceptanceTimers.clear();
    _isSearching.clear();
    notifyListeners();
  }

  void _setLoading(bool value, {bool notify = true}) {
    if (_isLoading == value) return;
    _isLoading = value;
    if (notify) notifyListeners();
  }

  // ─── Realtime ──────────────────────────────────────────────────────────────

  /// Sets up the correct realtime channel for [role], tearing down the other.
  Future<void> _setupRealtimeForRole(String role) async {
    if (!AppConstants.useSupabase) return;

    final sb = SupabaseService.instance.client;
    final userId = sb.auth.currentUser?.id;
    if (userId == null) return;

    if (role == 'customer') {
      // Tear down provider channel if active
      if (_providerChannel != null) {
        await _providerChannel!.unsubscribe();
        _providerChannel = null;
      }
      // Only create customer channel once
      if (_customerChannel != null) return;

      _customerChannel = sb
          .channel('bookings:customer:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'customer_id',
              value: userId,
            ),
            callback: _handleRealtimeEvent,
          )
          .subscribe();
    } else {
      // Tear down customer channel if active
      if (_customerChannel != null) {
        await _customerChannel!.unsubscribe();
        _customerChannel = null;
      }
      // Only create provider channel once (need provider row ID)
      if (_providerChannel != null) return;

      // Resolve provider row ID (cache it)
      _cachedProviderId ??= await _resolveProviderId(userId, sb);
      final pid = _cachedProviderId;
      if (pid == null) return; // User has no provider profile yet

      _providerChannel = sb
          .channel('bookings:provider:$pid')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'provider_id',
              value: pid,
            ),
            callback: _handleRealtimeEvent,
          )
          .subscribe();
    }
  }

  /// Resolves the service_providers.id for a given auth user.id.
  Future<String?> _resolveProviderId(String userId, dynamic sb) async {
    try {
      final data = await sb
          .from('service_providers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return (data as Map)['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Handles all Supabase realtime events (INSERT / UPDATE / DELETE).
  Future<void> _handleRealtimeEvent(PostgresChangePayload payload) async {
    final event = payload.eventType;
    final Map<String, dynamic> newRecord = Map<String, dynamic>.from(payload.newRecord);
    final String newId = (newRecord['id'] ?? '').toString();
    if (newId.isEmpty) return;

    // Convert keys to camelCase for consistency with our local models
    final mappedRecord = supabaseRowToJson(newRecord);

    if (event == PostgresChangeEvent.insert) {
      // Avoid duplicates
      if (_bookings.any((b) => b.id == newId)) return;

      // For new bookings, we need the full joined data (customer/provider details)
      final res = await _bookingService.getBookingById(newId);
      if (res.success && res.data != null) {
        _bookings.insert(0, res.data!);
        
        // Start timer for new pending booking found via realtime
        if (res.data!.status == AppConstants.statusPending) {
          _startAcceptanceTimer(res.data!.id);
        }
        notifyListeners();
      }
    } else if (event == PostgresChangeEvent.update) {
      final index = _bookings.indexWhere((b) => b.id == newId);
      if (index != -1) {
        final existingBooking = _bookings[index];
        final newStatus = mappedRecord['status'] as String?;
        final isAdvancePaid = mappedRecord['advancePaid'] as bool?;
        final isFinalPaid = mappedRecord['finalPaid'] as bool?;
        
        // Cancel timer if status changed via realtime
        if (newStatus != null && newStatus != AppConstants.statusPending) {
          _acceptanceTimers[newId]?.cancel();
          _acceptanceTimers.remove(newId);
        }

        // Optimization: If only status, payment flags, or timestamps changed, update locally
        // This avoids UI flicker and redundant network calls for joined data we already have
        bool needsFullFetch = false;
        
        // If provider changed (reassignment), we MUST re-fetch for full joined data
        if (mappedRecord['providerId'] != null && mappedRecord['providerId'] != existingBooking.providerId) {
          needsFullFetch = true;
        }

        if (needsFullFetch) {
          final res = await _bookingService.getBookingById(newId);
          if (res.success && res.data != null) {
            _bookings[index] = res.data!;
            if (_currentBooking?.id == newId) _currentBooking = res.data;
            notifyListeners();
          }
        } else {
          // Update known changed fields locally
          _bookings[index] = existingBooking.copyWith(
            status: newStatus ?? existingBooking.status,
            updatedAt: DateTime.tryParse(mappedRecord['updatedAt'] ?? '') ?? existingBooking.updatedAt,
            advancePaid: isAdvancePaid ?? existingBooking.advancePaid,
            finalPaid: isFinalPaid ?? existingBooking.finalPaid,
            acceptedAt: mappedRecord['acceptedAt'] != null 
                ? DateTime.tryParse(mappedRecord['acceptedAt']) 
                : existingBooking.acceptedAt,
          );
          
          if (_currentBooking?.id == newId) {
            _currentBooking = _bookings[index];
          }
          notifyListeners();
        }
      }
    } else if (event == PostgresChangeEvent.delete) {
      _bookings.removeWhere((b) => b.id == newId);
      if (_currentBooking?.id == newId) _currentBooking = null;
      notifyListeners();
    }
  }

  // ─── Reassignment Internals ────────────────────────────────────────────────

  void _startAcceptanceTimer(String bookingId) {
    _acceptanceTimers[bookingId]?.cancel();
    _acceptanceTimers[bookingId] = Timer(const Duration(seconds: 120), () {
      _handleBookingTimeout(bookingId);
    });
  }

  Future<void> _handleBookingTimeout(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    
    final booking = _bookings[index];
    if (booking.status != AppConstants.statusPending) return;

    debugPrint('BookingProvider: Timeout reached for booking $bookingId. Reassigning...');
    
    _isSearching[bookingId] = true;
    notifyListeners();

    try {
      // 1. Find next best provider
      final nearbyResponse = await _providerService.getNearbyProviders(
        latitude: booking.serviceLocation.latitude ?? 0.0,
        longitude: booking.serviceLocation.longitude ?? 0.0,
        radius: 20, // Search a bit wider for reassignment
      );

      if (nearbyResponse.success && nearbyResponse.data != null) {
        final potentials = nearbyResponse.data!
            .where((p) => p.id != booking.providerId && p.isOnline)
            .toList();

        if (potentials.isNotEmpty) {
          final nextProvider = potentials.first;
          debugPrint('BookingProvider: Reassigning to ${nextProvider.id}');

          // 2. Update booking in DB
          final sb = SupabaseService.instance.client;
          await sb.from('bookings').update({
            'provider_id': nextProvider.id,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', bookingId);

          // Realtime will handle the local state update
        } else {
          debugPrint('BookingProvider: No other providers available for reassignment.');
        }
      }
    } catch (e) {
      debugPrint('BookingProvider: Error during reassignment: $e');
    } finally {
      _isSearching[bookingId] = false;
      _acceptanceTimers.remove(bookingId);
      notifyListeners();
    }
  }
}
