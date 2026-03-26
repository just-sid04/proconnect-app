import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import '../utils/constants.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Register new user
  Future<ApiResponse<User>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    Location? location,
    Map<String, dynamic>? jsonMetadata,
  }) async {
    final response = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
      'location': location?.toJson(),
      if (jsonMetadata != null) ...jsonMetadata,
    });

    if (response.success) {
      final userData = response.data['user'];
      final token = response.data['token'];
      
      await _api.setToken(token);
      await _saveUser(userData);
      
      return ApiResponse.success(User.fromJson(userData), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Login user
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    if (response.success) {
      final userData = response.data['user'];
      final token = response.data['token'];
      
      await _api.setToken(token);
      await _saveUser(userData);
      
      return ApiResponse.success(User.fromJson(userData), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Get current user
  Future<ApiResponse<User>> getCurrentUser() async {
    final response = await _api.get('/auth/me');

    if (response.success) {
      await _saveUser(response.data);
      return ApiResponse.success(User.fromJson(response.data));
    }

    return ApiResponse.error(response.message);
  }

  // Update profile
  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? phone,
    Location? location,
    String? profilePhoto,
    String? fcmToken,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (location != null) body['location'] = location.toJson();
    if (profilePhoto != null) body['profilePhoto'] = profilePhoto;
    if (fcmToken != null) body['fcm_token'] = fcmToken;

    final response = await _api.put('/users/me', body: body);

    if (response.success) {
      await _saveUser(response.data);
      return ApiResponse.success(User.fromJson(response.data), message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Change password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _api.post('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });

    if (response.success) {
      return ApiResponse.success(null, message: response.message);
    }

    return ApiResponse.error(response.message);
  }

  // Logout
  Future<ApiResponse<void>> logout() async {
    final response = await _api.post('/auth/logout');
    await _api.clearToken();
    return ApiResponse.success(null, message: response.message);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }

  // Get saved user
  Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Save user to local storage
  Future<void> _saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(userData));
  }
}
