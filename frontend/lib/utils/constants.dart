import 'package:flutter/foundation.dart';

class AppConstants {
  // Supabase Configuration (required for Supabase integration)
  static String get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    return url;
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    return key;
  }

  static bool get useSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // API Configuration (used when Supabase is not configured - legacy backend)
  static String get baseUrl {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api'
        : 'http://localhost:3000/api';
  }

  static const String apiVersion = 'v1';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_completed';

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;

  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Roles
  static const String roleCustomer = 'customer';
  static const String roleProvider = 'provider';
  static const String roleAdmin = 'admin';

  // Booking Status
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusInProgress = 'in-progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Verification Status
  static const String verificationPending = 'pending';
  static const String verificationApproved = 'approved';
  static const String verificationRejected = 'rejected';

  // Image
  static const int maxImageSize = 5 * 1024 * 1024;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];

  // Location
  static const double defaultSearchRadius = 10.0;
  static const double maxSearchRadius = 100.0;
}

class ErrorMessages {
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String unauthorized = 'Session expired. Please login again.';
  static const String notFound = 'Resource not found.';
  static const String validationError = 'Please check your input and try again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String timeoutError = 'Request timed out. Please try again.';

  // Auth
  static const String invalidCredentials = 'Invalid email or password.';
  static const String emailExists = 'An account with this email already exists.';
  static const String weakPassword = 'Password must be at least 6 characters.';
  static const String passwordsDoNotMatch = 'Passwords do not match.';

  // Booking
  static const String bookingNotFound = 'Booking not found.';
  static const String cannotCancelBooking = 'Cannot cancel this booking.';
  static const String providerNotAvailable = 'Provider is not available at this time.';
}

class SuccessMessages {
  static const String loginSuccess = 'Login successful!';
  static const String registerSuccess = 'Account created successfully!';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String bookingCreated = 'Booking created successfully!';
  static const String bookingCancelled = 'Booking cancelled successfully!';
  static const String reviewSubmitted = 'Review submitted successfully!';
  static const String providerRegistered = 'Provider registration successful!';
}
