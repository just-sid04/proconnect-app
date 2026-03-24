import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slideLeft;
  late Animation<Offset> _slideRight;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _slideLeft = Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _slideRight = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.navyDeep, AppTheme.navyMid],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(children: [
              const SizedBox(height: 16),

              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.navySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: AppTheme.textPrimary),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Header
              FadeTransition(
                opacity: _fade,
                child: Column(children: [
                  // PC Logo small
                  Container(
                    width: 56, height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Center(
                      child: Text('PC',
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Join ProConnect',
                      style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Choose how you want to continue',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppTheme.textSecondary)),
                ]),
              ),

              const SizedBox(height: 48),

              // Role cards row
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Customer card
                    Expanded(
                      child: SlideTransition(
                        position: _slideLeft,
                        child: FadeTransition(
                          opacity: _fade,
                          child: _RoleCard(
                            title: 'Customer',
                            subtitle: 'Find & book trusted service professionals near you',
                            icon: Icons.person_search_rounded,
                            gradient: AppTheme.goldGradient,
                            features: const ['Browse by category', 'Real-time booking', 'Track progress'],
                            onTap: () => Navigator.pushNamed(context, '/register',
                                arguments: 'customer'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Provider card
                    Expanded(
                      child: SlideTransition(
                        position: _slideRight,
                        child: FadeTransition(
                          opacity: _fade,
                          child: _RoleCard(
                            title: 'Provider',
                            subtitle: 'Grow your service business and connect with customers',
                            icon: Icons.engineering_rounded,
                            gradient: AppTheme.primaryGradient,
                            features: const ['Manage bookings', 'Track earnings', 'Build reputation'],
                            onTap: () => Navigator.pushNamed(context, '/register',
                                arguments: 'provider'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Already have account
              FadeTransition(
                opacity: _fade,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already have an account?',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text('Sign In',
                        style: GoogleFonts.inter(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String title, subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final List<String> features;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title, required this.subtitle,
    required this.icon, required this.gradient,
    required this.features, required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.navySurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.dividerColor, width: 1),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon in gradient circle
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.gradient.colors.first).withAlpha(80),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),

              Text(widget.title,
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text(widget.subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5)),

              const SizedBox(height: 20),
              const Divider(color: AppTheme.dividerColor, height: 1),
              const SizedBox(height: 16),

              // Features
              ...widget.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(Icons.check_circle_rounded,
                      size: 16,
                      color: widget.gradient.colors.first),
                  const SizedBox(width: 8),
                  Text(f,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500)),
                ]),
              )),

              const Spacer(),

              // CTA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.colors.first.withAlpha(80),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Text('Get Started',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}