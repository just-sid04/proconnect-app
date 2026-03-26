import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../models/review_model.dart';
import '../services/provider_service.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';
import '../services/location_service.dart';

class ProviderProvider extends ChangeNotifier {
  final ProviderService _providerService = ProviderService();
  
  List<ServiceProvider> _providers = [];
  List<Category> _categories = [];
  ServiceProvider? _currentProvider;
  Category? _selectedCategory;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  List<Review> _currentProviderReviews = [];
  bool _reviewsLoading = false;
  bool _isTracking = false;

  // Getters
  List<ServiceProvider> get providers => _providers;
  List<Category> get categories => _categories;
  ServiceProvider? get currentProvider => _currentProvider;
  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  List<Review> get currentProviderReviews => _currentProviderReviews;
  bool get reviewsLoading => _reviewsLoading;
  bool get isTracking => _isTracking;

  // Load providers
  Future<void> loadProviders({
    String? category,
    double? minRating,
    double? maxRate,
    List<String>? skills,
    bool? verified,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _providers = [];
      _isLoading = false; // Reset loading state for fresh load
    }

    if (_isLoading || (!_hasMore && !refresh)) return;

    _setLoading(true);
    _error = null;

    try {
      final response = await _providerService.getProviders(
        category: category,
        minRating: minRating,
        maxRate: maxRate,
        skills: skills,
        verified: verified,
        search: search,
        page: _currentPage,
        limit: AppConstants.defaultPageSize,
      );

      if (response.success) {
        final newProviders = response.data ?? [];
        
        if (refresh) {
          _providers = newProviders;
        } else {
          _providers.addAll(newProviders);
        }

        _hasMore = newProviders.length >= AppConstants.defaultPageSize;
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

  // Load nearby providers
  Future<void> loadNearbyProviders({
    required double latitude,
    required double longitude,
    double radius = 10,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _providers = [];
    }

    if (_isLoading || !_hasMore) return;

    _setLoading(true);
    _error = null;

    try {
      final response = await _providerService.getNearbyProviders(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        page: _currentPage,
        limit: AppConstants.defaultPageSize,
      );

      if (response.success) {
        final newProviders = response.data ?? [];
        
        if (refresh) {
          _providers = newProviders;
        } else {
          _providers.addAll(newProviders);
        }

        _hasMore = newProviders.length >= AppConstants.defaultPageSize;
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

  // Get provider by ID
  Future<bool> getProviderById(String id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _providerService.getProviderById(id);

      if (response.success) {
        _currentProvider = response.data;
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

  // Load categories
  Future<void> loadCategories() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _providerService.getCategories();

      if (response.success) {
        _categories = response.data ?? [];
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

  // Set selected category
  void setSelectedCategory(Category? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Create provider profile
     // Create provider profile
  Future<bool> createProviderProfile({
    String? categoryId,
    required List<String> skills,
    required int experience,
    double? hourlyRate,
    String? description,
    double? serviceArea,
    Map<String, dynamic>? availability,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _providerService.createProviderProfile(
        categoryId: categoryId ?? 'general',
        skills: skills,
        experience: experience,
        hourlyRate: hourlyRate,
        description: description,
        serviceArea: serviceArea?.toInt(),
        availability: availability != null ? Availability.fromJson(availability) : null,
      );

      if (response.success && response.data != null) {
        final refreshedResponse = await _providerService.getMyProviderProfile();
        _currentProvider = refreshedResponse.success && refreshedResponse.data != null
            ? refreshedResponse.data
            : response.data;
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

  // Update provider profile
  Future<bool> updateProviderProfile({
    required String id,
    List<String>? skills,
    int? experience,
    double? hourlyRate,
    String? description,
    int? serviceArea,
    Availability? availability,
    List<String>? portfolio,
    List<String>? documents,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _providerService.updateProviderProfile(
        id: id,
        skills: skills,
        experience: experience,
        hourlyRate: hourlyRate,
        description: description,
        serviceArea: serviceArea,
        availability: availability,
        portfolio: portfolio,
        documents: documents,
      );

      if (response.success && response.data != null) {
        final refreshedResponse = await _providerService.getMyProviderProfile();
        _currentProvider = refreshedResponse.success && refreshedResponse.data != null
            ? refreshedResponse.data
            : response.data;
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

  // Update Portfolio (Convenience method for UI)
  Future<bool> updatePortfolio(List<XFile> images) async {
    if (_currentProvider == null) return false;
    
    _setLoading(true);
    _error = null;

    try {
      // 1. Upload new images
      final List<String> newUrls = await UploadService.uploadImages(
        xFiles: images,
        bucket: 'profiles',
        userId: _currentProvider!.userId,
        folderPrefix: 'portfolio',
      );

      // 2. Combine with existing portfolio
      final List<String> updatedPortfolio = [..._currentProvider!.portfolio, ...newUrls];

      // 3. Update profile
      return await updateProviderProfile(
        id: _currentProvider!.id,
        portfolio: updatedPortfolio,
      );
    } catch (e) {
      _error = ErrorMessages.genericError;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload Verification Documents
  Future<bool> uploadVerificationDocuments(List<XFile> images) async {
    if (_currentProvider == null) return false;
    
    _setLoading(true);
    _error = null;

    try {
      // 1. Upload documents to PRIVATE 'verifications' bucket
      final List<String> newUrls = await UploadService.uploadImages(
        xFiles: images,
        bucket: 'verifications',
        userId: _currentProvider!.userId,
        folderPrefix: 'verify',
      );

      // 2. Update profile with new documents
      // Note: verificationStatus is updated via a separate field in updateProviderProfile if needed,
      // but usually the DB trigger handles it or we set it explicitly.
      final List<String> updatedDocs = [..._currentProvider!.documents, ...newUrls];

      return await updateProviderProfile(
        id: _currentProvider!.id,
        documents: updatedDocs,
      );
    } catch (e) {
      _error = ErrorMessages.genericError;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get my provider profile
  Future<bool> getMyProviderProfile() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _providerService.getMyProviderProfile();

      if (response.success) {
        _currentProvider = response.data;
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

  // Clear current provider
  void clearCurrentProvider() {
    _currentProvider = null;
    _currentProviderReviews = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset
  void reset() {
    _providers = [];
    _categories = [];
    _currentProvider = null;
    _selectedCategory = null;
    _isLoading = false;
    _reviewsLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    _currentProviderReviews = [];
    _isTracking = false;
    LocationService.instance.stopTracking();
    notifyListeners();
  }

  // Toggle Tracking (Online/Offline)
  Future<void> toggleTracking(bool value) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (value) {
      final hasPermission = await LocationService.instance.checkPermissions();
      if (hasPermission) {
        await LocationService.instance.startTracking(userId: userId, isProvider: true);
        _isTracking = true;
      } else {
        _error = "Location permission denied. Cannot go online.";
      }
    } else {
      LocationService.instance.stopTracking();
      _isTracking = false;
    }
    notifyListeners();
  }


  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Get available slots for a provider on a specific date
  Future<List<String>> getAvailableSlots(String providerId, DateTime date) async {
    final supabase = Supabase.instance.client;
    final int dayOfWeek = date.weekday % 7; // Sunday is 0 in our DB, but 7 in Dart's DateTime.weekday

    try {
      // 1. Fetch Schedule
      final scheduleRes = await supabase
          .from('provider_schedules')
          .select()
          .eq('provider_id', providerId)
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true)
          .maybeSingle();

      if (scheduleRes == null) return [];

      final String startTimeStr = scheduleRes['start_time'] as String;
      final String endTimeStr = scheduleRes['end_time'] as String;

      // 2. Fetch Blocked Slots for this date
      final DateTime startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
      final DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59);
      
      final List<dynamic> blockedRes = await supabase
          .from('provider_blocked_slots')
          .select()
          .eq('provider_id', providerId)
          .lt('start_at', endOfDay.toIso8601String())
          .gt('end_at', startOfDay.toIso8601String());

      // 3. Fetch Existing Bookings for this date
      final String dateStr = DateFormat('yyyy-MM-dd').format(date);
      final List<dynamic> bookingsRes = await supabase
          .from('bookings')
          .select('scheduled_time, estimated_duration')
          .eq('provider_id', providerId)
          .eq('scheduled_date', dateStr)
          .or('status.eq.accepted,status.eq.in-progress');

      // 4. Generate candidate slots (e.g., hourly)
      final int startHour = int.parse(startTimeStr.split(':')[0]);
      final int endHour = int.parse(endTimeStr.split(':')[0]);
      
      List<String> availableSlots = [];
      for (int h = startHour; h < endHour; h++) {
        final String slotTime = '${h.toString().padLeft(2, '0')}:00';
        final DateTime slotDateTime = DateTime(date.year, date.month, date.day, h, 0);
        
        // Check if slot overlaps with blocked slots
        bool isBlocked = false;
        for (var b in blockedRes) {
          final DateTime bStart = DateTime.parse(b['start_at'] as String);
          final DateTime bEnd = DateTime.parse(b['end_at'] as String);
          if (slotDateTime.isBefore(bEnd) && slotDateTime.add(const Duration(hours: 1)).isAfter(bStart)) {
            isBlocked = true;
            break;
          }
        }
        if (isBlocked) continue;

        // Check if slot overlaps with existing bookings
        bool isBooked = false;
        for (var b in bookingsRes) {
          final String bTimeStr = b['scheduled_time'] as String;
          final int bDuration = b['estimated_duration'] as int;
          final List<String> timeParts = bTimeStr.split(':');
          final int bStartHour = int.parse(timeParts[0]);
          final int bStartMinute = int.parse(timeParts[1]);
          
          final DateTime bStart = DateTime(date.year, date.month, date.day, bStartHour, bStartMinute);
          final DateTime bEnd = bStart.add(Duration(hours: bDuration));

          if (slotDateTime.isBefore(bEnd) && slotDateTime.add(const Duration(hours: 1)).isAfter(bStart)) {
            isBooked = true;
            break;
          }
        }
        if (isBooked) continue;

        availableSlots.add(slotTime);
      }

      return availableSlots;
    } catch (e) {
      debugPrint('Error getting available slots: $e');
      return [];
    }
  }
}
