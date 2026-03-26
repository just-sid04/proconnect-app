import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart' as app;
import '../utils/constants.dart';
import 'api_service.dart';
import 'supabase_service.dart';

/// Auth service that uses Supabase Auth + profiles table.
/// Falls back to legacy API when Supabase is not configured.
class AuthServiceSupabase {
  final ApiService _api = ApiService();

  SupabaseClient get _supabase => SupabaseService.instance.client;

  bool get _useSupabase => AppConstants.useSupabase;


  app.User _profileToUser(Map<String, dynamic> profile, String email) {
    final loc = profile['location'];
    return app.User(
      id: profile['id'] ?? '',
      name: profile['name'] ?? '',
      email: email,
      phone: profile['phone'] ?? '',
      role: profile['role'] ?? 'customer',
      profilePhoto: profile['profile_photo'],
      location: loc != null ? app.Location.fromJson(Map<String, dynamic>.from(loc as Map)) : null,
      isActive: profile['is_active'] ?? true,
      isVerified: profile['is_verified'] ?? false,
      createdAt: DateTime.parse(profile['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(profile['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Future<ApiResponse<app.User>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    XFile? profileImage,
    app.Location? location,
    Map<String, dynamic>? jsonMetadata,
  }) async {
    if (_useSupabase) {
      try {
        await _supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'proconnect://confirm',
          data: {
            'name': name,
            'phone': phone ?? '',
            'role': role,
            'location': location?.toJson(),
            'latitude': location?.latitude,
            'longitude': location?.longitude,
            if (jsonMetadata != null) ...jsonMetadata,
          },
        );

        final session = _supabase.auth.currentSession;
        if (session == null) {
          return ApiResponse.error(
            'Please check your email to confirm your account, or sign in if already confirmed.',
          );
        }

        final profile = await _getProfile(session.user.id);
        if (profile != null) {
          final user = _profileToUser(profile, session.user.email ?? email);
          await _saveUser(user);
          return ApiResponse.success(user, message: 'Account created successfully!');
        }

        return ApiResponse.error('Profile not found. Please try signing in.');
      } on AuthException catch (e) {
        return ApiResponse.error(e.message);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    return _legacyRegister(
      name: name,
      email: email,
      password: password,
      role: role,
      phone: phone,
      location: location,
    );
  }

  Future<ApiResponse<app.User>> _legacyRegister({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    app.Location? location,
  }) async {
    final response = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
      'location': location?.toJson(),
    });

    if (response.success) {
      final userData = response.data['user'];
      final token = response.data['token'];
      await _api.setToken(token);
      await _saveUserLegacy(userData);
      return ApiResponse.success(
        app.User.fromJson(userData),
        message: response.message,
      );
    }
    return ApiResponse.error(response.message);
  }

  Future<ApiResponse<app.User>> login({
    required String email,
    required String password,
  }) async {
    if (_useSupabase) {
      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final session = _supabase.auth.currentSession;
        if (session == null) {
          return ApiResponse.error('Invalid email or password');
        }

        final profile = await _getProfile(session.user.id);
        if (profile != null) {
          final app.User user = _profileToUser(profile, session.user.email ?? email);
          await _saveUser(user);
          return ApiResponse.success(user, message: 'Login successful!');
        }

        return ApiResponse.error('Profile not found.');
      } on AuthException catch (e) {
        return ApiResponse.error(e.message);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    return _legacyLogin(email: email, password: password);
  }

  Future<ApiResponse<app.User>> _legacyLogin({
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
      await _saveUserLegacy(userData);
      return ApiResponse.success(
        app.User.fromJson(userData),
        message: response.message,
      );
    }
    return ApiResponse.error(response.message);
  }

  Future<Map<String, dynamic>?> _getProfile(String userId) async {
    final res = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return res != null ? Map<String, dynamic>.from(res as Map) : null;
  }

  Future<ApiResponse<app.User>> getCurrentUser() async {
    if (_useSupabase) {
      try {
        final session = _supabase.auth.currentSession;
        if (session == null) return ApiResponse.error('Not authenticated');

        final profile = await _getProfile(session.user.id);
        if (profile != null) {
          final user = _profileToUser(
            profile,
            session.user.email ?? '',
          );
          await _saveUser(user);
          return ApiResponse.success(user);
        }
        return ApiResponse.error('Profile not found');
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.get('/auth/me');
    if (response.success) {
      await _saveUserLegacy(response.data);
      return ApiResponse.success(app.User.fromJson(response.data));
    }
    return ApiResponse.error(response.message);
  }

  Future<ApiResponse<app.User>> updateProfile({
    String? name,
    String? phone,
    app.Location? location,
    String? profilePhoto,
    String? fcmToken,
  }) async {
    if (_useSupabase) {
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) return ApiResponse.error('Not authenticated');

        final updates = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (name != null) updates['name'] = name;
        if (phone != null) updates['phone'] = phone;
        if (location != null) {
          updates['location'] = location.toJson();
          updates['latitude'] = location.latitude;
          updates['longitude'] = location.longitude;
        }
        if (profilePhoto != null) updates['profile_photo'] = profilePhoto;
        if (fcmToken != null) updates['fcm_token'] = fcmToken;

        await _supabase.from('profiles').update(updates).eq('id', userId);

        return getCurrentUser();
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (location != null) body['location'] = location.toJson();
    if (profilePhoto != null) body['profilePhoto'] = profilePhoto;

    final response = await _api.put('/users/me', body: body);
    if (response.success) {
      await _saveUserLegacy(response.data);
      return ApiResponse.success(
        app.User.fromJson(response.data),
        message: response.message,
      );
    }
    return ApiResponse.error(response.message);
  }

  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_useSupabase) {
      try {
        await _supabase.auth.updateUser(UserAttributes(password: newPassword));
        return ApiResponse.success(null, message: 'Password changed successfully');
      } on AuthException catch (e) {
        return ApiResponse.error(e.message);
      } catch (e) {
        return ApiResponse.error(e.toString());
      }
    }

    final response = await _api.post('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (response.success) {
      return ApiResponse.success(null, message: response.message);
    }
    return ApiResponse.error(response.message);
  }

  Future<ApiResponse<void>> logout() async {
    if (_useSupabase) {
      await _supabase.auth.signOut();
    } else {
      await _api.post('/auth/logout');
      await _api.clearToken();
    }
    await _clearUser();
    return ApiResponse.success(null, message: 'Logged out successfully');
  }

  Future<bool> isLoggedIn() async {
    if (_useSupabase) {
      // Check Supabase session first
      if (_supabase.auth.currentSession != null) return true;
      
      // Fallback: Check if we have a saved user profile as a hint 
      // (useful during app startup while Supabase rehydrates)
      final savedUser = await getSavedUser();
      return savedUser != null;
    }
    return await _api.getToken() != null;
  }

  Future<app.User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson != null) {
      return app.User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> _saveUser(app.User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  Future<void> _saveUserLegacy(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(userData));
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.tokenKey);
  }
}
