import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/provider_provider.dart';
import 'providers/review_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/provider/provider_home_screen.dart';
import 'screens/provider/provider_profile_screen.dart';
import 'screens/provider/create_provider_profile_screen.dart';
import 'screens/admin/admin_home_screen.dart';

import 'utils/theme.dart';
import 'services/supabase_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if configured
  if (AppConstants.useSupabase) {
    try {
      await SupabaseService.initialize();
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }
  }

  runApp(const ProConnectApp());
}

class ProConnectApp extends StatelessWidget {
  const ProConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ProviderProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        title: 'ProConnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/role-selection': (context) => const RoleSelectionScreen(),
          '/register': (context) => const RegisterScreen(role: 'customer'),
          '/customer-home': (context) => const CustomerHomeScreen(),
          '/provider-home': (context) => const ProviderHomeScreen(),
          '/admin-home': (context) => const AdminHomeScreen(),
          '/provider-profile': (context) => const ProviderProfileScreen(),
          '/create-provider-profile': (context) => const CreateProviderProfileScreen(),
        },
      ),
    );
  }
}
