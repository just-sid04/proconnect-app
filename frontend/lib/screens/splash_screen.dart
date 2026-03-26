import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    _ctrl.forward();
    
    // ─── Initialize Auth & Navigate ──────────────────────────────────────────
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('SplashScreen: Starting _initAndNavigate...');
    
    // 1. Kick off initialization in background
    final initFuture = auth.initialize();
    
    // 2. Wait for at least 2.4s for splash feel
    final splashFuture = Future.delayed(const Duration(milliseconds: 2400));
    
    await Future.wait([initFuture, splashFuture]);
    debugPrint('SplashScreen: Initialization & Delay finished. LoggedIn: ${auth.isLoggedIn}');
    
    if (!mounted) return;
    _navigate(auth);
  }

  void _navigate(AuthProvider auth) {
    debugPrint('SplashScreen: Navigating based on auth state...');
    if (!auth.isLoggedIn) {
      debugPrint('SplashScreen: Not logged in, going to /login');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    
    final role = auth.user?.role;
    debugPrint('SplashScreen: Logged in as $role, navigating home...');
    if (auth.isAdmin) {
      Navigator.pushReplacementNamed(context, '/admin-home');
    } else if (auth.isProvider) {
      Navigator.pushReplacementNamed(context, '/provider-home');
    } else {
      Navigator.pushReplacementNamed(context, '/customer-home');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: Stack(
          children: [
            // Decorative glowing orbs
            const Positioned(
                top: -60,
                left: -60,
                child: _GlowOrb(color: AppTheme.primaryColor, size: 220)),
            const Positioned(
                bottom: -80,
                right: -80,
                child: _GlowOrb(color: AppTheme.accentColor, size: 200)),
            const Positioned(
                top: 200,
                right: -40,
                child: _GlowOrb(color: Color(0xFF7C3AED), size: 140)),

            // Center content
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // PC Logo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const _PCLogo(size: 110),
                  ),
                ),
                const SizedBox(height: 28),

                // App name + tagline
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(children: [
                      Text(
                        'ProConnect',
                        style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your trusted service network',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),

            // Bottom loading dots
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFade,
                child: const Center(child: _LoadingDots()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withAlpha(30),
            color.withAlpha(0),
          ]),
        ),
      );
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
              final opacity = (1 - (t - 0.5).abs() * 2).clamp(0.2, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      AppTheme.accentColor.withAlpha((opacity * 255).toInt()),
                ),
              );
            }));
      },
    );
  }
}

/// Reusable "PC" monogram logo badge — used across all auth screens.
class _PCLogo extends StatelessWidget {
  final double size;
  const _PCLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(100),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Export the logo for use in other screens.
class PCLogo extends StatelessWidget {
  final double size;
  const PCLogo({super.key, this.size = 70});
  @override
  Widget build(BuildContext context) => _PCLogo(size: size);
}
