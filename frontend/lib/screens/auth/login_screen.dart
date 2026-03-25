import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (success) {
      if (auth.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin-home');
      } else if (auth.isProvider)
        Navigator.pushReplacementNamed(context, '/provider-home');
      else
        Navigator.pushReplacementNamed(context, '/customer-home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Login failed'),
        backgroundColor: AppTheme.errorColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      body: Stack(children: [
        // Background gradient + orbs
        Container(
          decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        ),
        const Positioned(
            top: -80,
            right: -60,
            child: _Orb(color: AppTheme.primaryColor, size: 200)),
        const Positioned(
            bottom: -60,
            left: -60,
            child: _Orb(color: AppTheme.accentColor, size: 180)),

        // Content
        SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Logo
                    Center(child: _buildLogo()),
                    const SizedBox(height: 32),

                    // Title
                    Text('Welcome Back',
                        style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Sign in to your ProConnect account',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppTheme.textSecondary),
                        textAlign: TextAlign.center),

                    const SizedBox(height: 44),

                    // Form card (glassmorphism)
                    _GlassCard(
                      child: Column(children: [
                        CustomTextField(
                          controller: _emailCtrl,
                          label: 'Email address',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Enter your email';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          hint: '••••••••',
                          obscureText: _obscurePass,
                          prefixIcon: Icons.lock_outline_rounded,
                          textInputAction: TextInputAction.done,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Enter your password';
                            if (v.length < 6) return 'At least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotDialog,
                            child: Text('Forgot password?',
                                style: GoogleFonts.inter(
                                    color: AppTheme.accentColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // Sign In button
                    CustomButton(
                      text: 'Sign In',
                      isGold: false,
                      onPressed: auth.isLoading ? null : _login,
                      isLoading: auth.isLoading,
                    ),

                    const SizedBox(height: 32),

                    // Sign up link
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Don't have an account?",
                          style: GoogleFonts.inter(
                              color: AppTheme.textSecondary, fontSize: 14)),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/role-selection'),
                        child: Text('Sign up',
                            style: GoogleFonts.inter(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow:
            AppTheme.glowShadow(AppTheme.primaryColor, blur: 24, spread: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showForgotDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Need help signing in?'),
        content: Text(
          'Use a demo account:\n\n'
          '• Customer: customer@example.com / customer123\n'
          '• Provider: provider@example.com / provider123\n'
          '• Admin: admin@proconnect.com / admin123',
          style: GoogleFonts.inter(fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.navySurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.dividerColor, width: 1),
          boxShadow: AppTheme.cardShadow,
        ),
        child: child,
      );
}
