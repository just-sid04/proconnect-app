import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/provider_provider.dart';
import 'providers/review_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/wallet_provider.dart';

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
import 'services/notification_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize Notifications
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification Service initialization failed: $e');
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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider?>(
          create: (_) => null,
          update: (_, auth, previous) {
            final userId = auth.user?.id;
            if (userId == null) return null;
            if (previous?.userId == userId) return previous;
            return ChatProvider(userId);
          },
        ),
      ],
      child: _AppWithAuthWiring(),
    );
  }
}

/// Separate widget so we can access providers and wire them up after creation.
class _AppWithAuthWiring extends StatefulWidget {
  @override
  State<_AppWithAuthWiring> createState() => _AppWithAuthWiringState();
}

class _AppWithAuthWiringState extends State<_AppWithAuthWiring> {
  @override
  void initState() {
    super.initState();
    // Wire BookingProvider into AuthProvider so session-expiry events
    // can call bookingProvider.reset() without a circular dependency.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final bookings = Provider.of<BookingProvider>(context, listen: false);
      auth.setBookingProvider(bookings);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      navigatorKey: _navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/register': (context) {
          final role = ModalRoute.of(context)?.settings.arguments as String? ??
              'customer';
          return RegisterScreen(role: role);
        },
        '/customer-home': (context) => const CustomerHomeScreen(),
        '/provider-home': (context) => const ProviderHomeScreen(),
        '/admin-home': (context) => const AdminHomeScreen(),
        '/provider-profile': (context) => const ProviderProfileScreen(),
        '/create-provider-profile': (context) => const CreateProviderProfileScreen(),
      },
      builder: (context, child) {
        // Listen for session-expired signal from AuthProvider
        return _SessionExpiredListener(child: child!);
      },
    );
  }
}

/// Global navigator key — lets AuthProvider navigate to login without context.
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

/// Wraps the entire app and shows a dialog when session expires.
class _SessionExpiredListener extends StatefulWidget {
  final Widget child;
  const _SessionExpiredListener({required this.child});

  @override
  State<_SessionExpiredListener> createState() => _SessionExpiredListenerState();
}

class _SessionExpiredListenerState extends State<_SessionExpiredListener> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // If auth was initialized, user is now null, AND there's an auth error
        // → session expired while the app was running
        if (auth.isInitialized &&
            !auth.isLoggedIn &&
            auth.error == ErrorMessages.unauthorized &&
            !_shown) {
          _shown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showExpiredDialog(context, auth);
          });
        }
        if (auth.isLoggedIn) _shown = false; // reset after re-login
        return child!;
      },
      child: widget.child,
    );
  }

  void _showExpiredDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
            'Your session has expired. Please log in again to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              auth.clearError();
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login', (route) => false);
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }
}
