import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

/// Supabase client singleton - initialized in main()
class SupabaseService {
  SupabaseService._();
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    final url = AppConstants.supabaseUrl;
    final anonKey = AppConstants.supabaseAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint(
        '⚠️ Supabase not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY '
        'via --dart-define or in constants.dart',
      );
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _initialized = true;
  }
}
