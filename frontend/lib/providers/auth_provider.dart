import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service_supabase.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthServiceSupabase _authService = AuthServiceSupabase();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _user != null;
  bool get isCustomer => _user?.isCustomer ?? false;
  bool get isProvider => _user?.isProvider ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  // Initialize auth state
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        final response = await _authService.getCurrentUser();
        if (response.success) {
          _user = response.data;
          _error = null;
        } else {
          _error = response.message;
          await logout();
        }
      }
    } catch (e) {
      _error = ErrorMessages.genericError;
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      
      if (response.success) {
        _user = response.data;
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

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    Location? location,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        location: location,
      );
      
      if (response.success) {
        _user = response.data;
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

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    Location? location,
    String? profilePhoto,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _authService.updateProfile(
        name: name,
        phone: phone,
        location: location,
        profilePhoto: profilePhoto,
      );
      
      if (response.success) {
        _user = response.data;
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

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      if (response.success) {
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

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors
    } finally {
      _user = null;
      _error = null;
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (_user == null) return;
    
    try {
      final response = await _authService.getCurrentUser();
      if (response.success) {
        _user = response.data;
        notifyListeners();
      }
    } catch (e) {
      // Ignore refresh errors
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
