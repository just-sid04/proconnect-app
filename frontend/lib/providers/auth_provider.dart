import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/user_model.dart';
import '../services/auth_service_supabase.dart';
import '../services/upload_service.dart';
import '../utils/constants.dart';
import 'booking_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthServiceSupabase _authService = AuthServiceSupabase();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Supabase auth state subscription
  StreamSubscription<sb.AuthState>? _authSubscription;

  // Weak reference to BookingProvider for logout cleanup
  BookingProvider? _bookingProvider;

  // ─── Getters ───────────────────────────────────────────────────────────────

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _user != null;
  bool get isCustomer => _user?.isCustomer ?? false;
  bool get isProvider => _user?.isProvider ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  /// Call this once after all providers are created so AuthProvider can
  /// trigger BookingProvider.reset() on session expiry without creating a
  /// circular dependency at construction time.
  void setBookingProvider(BookingProvider bp) {
    _bookingProvider = bp;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ─── Initialize ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      // Restore existing session
      final isSignedIn = await _authService.isLoggedIn();
      if (isSignedIn) {
        final response = await _authService.getCurrentUser();
        if (response.success) {
          _user = response.data;
          _error = null;
        } else {
          await logout();
        }
      }

      // ── Listen for auth state changes (token refresh / sign-out) ──────────
      _authSubscription = sb.Supabase.instance.client.auth.onAuthStateChange
          .listen(_handleAuthStateChange, onError: (_) {});
    } catch (e) {
      _error = ErrorMessages.genericError;
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  void _handleAuthStateChange(sb.AuthState state) {
    switch (state.event) {
      case sb.AuthChangeEvent.signedIn:
        // Session restored or token refreshed — re-fetch profile if needed
        if (_user == null && state.session != null) {
          _authService.getCurrentUser().then((r) {
            if (r.success && r.data != null) {
              _user = r.data;
              notifyListeners();
            }
          });
        }
        break;

      case sb.AuthChangeEvent.tokenRefreshed:
        // Token silently refreshed — no UI update needed
        break;

      case sb.AuthChangeEvent.signedOut:
        // Session expired or signed out from another tab/device
        if (_user != null) {
          _bookingProvider?.reset();
          _user = null;
          _error = ErrorMessages.unauthorized;
          notifyListeners();
        }
        break;

      case sb.AuthChangeEvent.userUpdated:
        // Profile changed externally — refresh
        refreshUser();
        break;

      default:
        break;
    }
  }

  // ─── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _authService.login(email: email, password: password);
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

  // ─── Register ──────────────────────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    XFile? profileImage,
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
      );

      if (response.success) {
        _user = response.data;
        
        // ── Upload photo if provided ──────────────────────────────────────────
        if (profileImage != null && _user != null) {
          final String? photoUrl = await UploadService.uploadImage(
            xFile: profileImage,
            bucket: 'avatars',
            userId: _user!.id,
          );
          if (photoUrl != null) {
            await updateProfile(profilePhoto: photoUrl);
          }
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

  // ─── Update Profile ────────────────────────────────────────────────────────

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

  // ─── Avatar Upload ─────────────────────────────────────────────────────────

  Future<bool> pickAndUploadAvatar() async {
    if (_user == null) return false;
    
    _setLoading(true);
    _error = null;

    try {
      // 1. Pick Image (XFile is platform-agnostic)
      final image = await UploadService.pickImage();
      if (image == null) {
        _setLoading(false);
        return false;
      }

      // 2. Upload to Supabase Storage
      final String? photoUrl = await UploadService.uploadImage(
        xFile: image,
        bucket: 'avatars',
        userId: _user!.id,
      );

      if (photoUrl == null) {
        _error = 'Failed to upload image';
        _setLoading(false);
        return false;
      }

      // 3. Update Profile with new URL
      return await updateProfile(profilePhoto: photoUrl);
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeAvatar() async {
    if (_user == null || (_user!.profilePhoto?.isEmpty ?? true)) return false;

    _setLoading(true);
    _error = null;

    try {
      final oldPhoto = _user!.profilePhoto!;
      
      // 1. Delete from Storage
      await UploadService.deleteImage(bucket: 'avatars', path: oldPhoto);

      // 2. Update Profile to null
      return await updateProfile(profilePhoto: '');
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // ─── Change Password ───────────────────────────────────────────────────────

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

  // ─── Logout ────────────────────────────────────────────────────────────────

  /// Pass [bookingProvider] to also wipe cached bookings & realtime channels.
  Future<void> logout({BookingProvider? bookingProvider}) async {
    _setLoading(true);

    // Reset booking state BEFORE signing out so realtime unsubscribes cleanly
    (bookingProvider ?? _bookingProvider)?.reset();

    try {
      await _authService.logout();
    } catch (_) {
      // Ignore logout errors — always clear local state
    } finally {
      _user = null;
      _error = null;
      _setLoading(false);
    }
  }

  // ─── Refresh ───────────────────────────────────────────────────────────────

  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final response = await _authService.getCurrentUser();
      if (response.success && response.data != null) {
        _user = response.data;
        notifyListeners();
      }
    } catch (_) {
      // Ignore refresh errors
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
