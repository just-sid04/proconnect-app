import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../services/provider_service.dart';
import '../utils/constants.dart';

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

  // Getters
  List<ServiceProvider> get providers => _providers;
  List<Category> get categories => _categories;
  ServiceProvider? get currentProvider => _currentProvider;
  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

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
    }

    if (_isLoading || !_hasMore) return;

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
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
