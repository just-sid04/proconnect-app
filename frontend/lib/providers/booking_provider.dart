import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

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

  @override
  void dispose() {
    _customerChannel?.unsubscribe();
    _providerChannel?.unsubscribe();
    super.dispose();
  }

  // ─── Getters ───────────────────────────────────────────────────────────────

  List<Booking> get bookings => _bookings;
  Booking? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    if (payload.eventType == PostgresChangeEvent.insert) {
      final newId = payload.newRecord['id'] as String?;
      if (newId == null) return;
      // Avoid duplicates
      if (_bookings.any((b) => b.id == newId)) return;

      // Fetch with full join so we have provider/customer details
      final res = await _bookingService.getBookingById(newId);
      if (res.success && res.data != null) {
        _bookings.insert(0, res.data!);
        notifyListeners();
      }
    } else if (payload.eventType == PostgresChangeEvent.update) {
      final id = payload.newRecord['id'] as String?;
      if (id == null) return;

      // IDEMPOTENCY: Check if we already have this update locally (from optimistic UI)
      final existingIndex = _bookings.indexWhere((b) => b.id == id);
      if (existingIndex != -1) {
        final existingStatus = _bookings[existingIndex].status;
        final newStatus = payload.newRecord['status'] as String?;
        if (existingStatus == newStatus) {
          // Update matches what we have — no need to re-fetch full object
          return;
        }
      }

      final res = await _bookingService.getBookingById(id);
      if (res.success && res.data != null) {
        final updated = res.data!;
        if (existingIndex != -1) {
          _bookings[existingIndex] = updated;
        } else {
          _bookings.insert(0, updated);
        }
        if (_currentBooking?.id == id) _currentBooking = updated;
        notifyListeners();
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final id = payload.oldRecord['id'] as String?;
      if (id == null) return;
      _bookings.removeWhere((b) => b.id == id);
      if (_currentBooking?.id == id) _currentBooking = null;
      notifyListeners();
    }
  }
}
