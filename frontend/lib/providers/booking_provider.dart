import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../utils/constants.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  
  List<Booking> _bookings = [];
  Booking? _currentBooking;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<Booking> get bookings => _bookings;
  Booking? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Get bookings by status
  List<Booking> getBookingsByStatus(String status) {
    return _bookings.where((b) => b.status == status).toList();
  }

  // Get pending bookings
  List<Booking> get pendingBookings => getBookingsByStatus(AppConstants.statusPending);

  // Get active bookings (accepted + in-progress)
  List<Booking> get activeBookings => _bookings.where(
    (b) => b.status == AppConstants.statusAccepted || b.status == AppConstants.statusInProgress
  ).toList();

  // Get completed bookings
  List<Booking> get completedBookings => getBookingsByStatus(AppConstants.statusCompleted);

  // Load bookings
  Future<void> loadBookings({
    String? status,
    String role = 'customer',
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _bookings = [];
    }

    if (_isLoading || !_hasMore) return;

    _setLoading(true);
    _error = null;

    try {
      final response = await _bookingService.getBookings(
        status: status,
        role: role,
        page: _currentPage,
        limit: AppConstants.defaultPageSize,
      );

      if (response.success) {
        final newBookings = response.data ?? [];
        
        if (refresh) {
          _bookings = newBookings;
        } else {
          _bookings.addAll(newBookings);
        }

        _hasMore = newBookings.length >= AppConstants.defaultPageSize;
        _currentPage++;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = ErrorMessages.genericError;
    } finally {
      _setLoading(false);
    }
  }

  // Get booking by ID
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
      _error = ErrorMessages.genericError;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create booking
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
        final detailedBooking = await _getDetailedBookingOrFallback(response.data!);
        _bookings.insert(0, detailedBooking);
        _currentBooking = detailedBooking;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ErrorMessages.genericError;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus({
    required String id,
    required String status,
    String? cancellationReason,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _bookingService.updateBookingStatus(
        id: id,
        status: status,
        cancellationReason: cancellationReason,
      );

      if (response.success && response.data != null) {
        final detailedBooking = await _getDetailedBookingOrFallback(response.data!);
        final index = _bookings.indexWhere((b) => b.id == id);
        if (index != -1) {
          _bookings[index] = detailedBooking;
        }
        if (_currentBooking?.id == id || _currentBooking == null) {
          _currentBooking = detailedBooking;
        }
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ErrorMessages.genericError;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Accept booking (provider)
  Future<bool> acceptBooking(String id) async {
    return updateBookingStatus(id: id, status: AppConstants.statusAccepted);
  }

  // Start booking (provider)
  Future<bool> startBooking(String id) async {
    return updateBookingStatus(id: id, status: AppConstants.statusInProgress);
  }

  // Complete booking (provider)
  Future<bool> completeBooking(String id) async {
    return updateBookingStatus(id: id, status: AppConstants.statusCompleted);
  }

  // Cancel booking
  Future<bool> cancelBooking(String id, {String? reason}) async {
    return updateBookingStatus(
      id: id,
      status: AppConstants.statusCancelled,
      cancellationReason: reason,
    );
  }

  // Delete booking
  Future<bool> deleteBooking(String id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _bookingService.deleteBooking(id);

      if (response.success) {
        _bookings.removeWhere((b) => b.id == id);
        if (_currentBooking?.id == id) {
          _currentBooking = null;
        }
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ErrorMessages.genericError;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear current booking
  void clearCurrentBooking() {
    _currentBooking = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset
  void reset() {
    _bookings = [];
    _currentBooking = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  Future<Booking> _getDetailedBookingOrFallback(Booking fallbackBooking) async {
    final detailedResponse = await _bookingService.getBookingById(fallbackBooking.id);
    return detailedResponse.success && detailedResponse.data != null
        ? detailedResponse.data!
        : fallbackBooking;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
