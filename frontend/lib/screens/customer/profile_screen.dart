import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import '../../widgets/location_picker_map.dart';
import 'package:latlong2/latlong.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bp   = Provider.of<BookingProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const Center(child: Text('Please login'));
    }

    final hasPhoto = user.profilePhoto?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Stack(children: [
              // Background gradient
              Container(
                height: 230,
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
              ),
              // Glow orb
              Positioned(top: -40, right: -40,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppTheme.primaryColor.withAlpha(60),
                      AppTheme.primaryColor.withAlpha(0),
                    ]),
                  ),
                ),
              ),
              SafeArea(
                child: Column(children: [
                  // Top edit button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(children: [
                      Text('My Profile',
                          style: GoogleFonts.inter(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showEditProfileDialog(context, auth),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.navySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 18, color: AppTheme.textPrimary),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Avatar + name
                  Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        border: Border.all(color: AppTheme.accentColor, width: 3),
                        boxShadow: AppTheme.glowShadow(AppTheme.primaryColor, blur: 20),
                      ),
                      child: hasPhoto
                          ? ClipOval(child: Image.network(user.profilePhoto!, fit: BoxFit.cover))
                          : Center(child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: GoogleFonts.inter(
                                  fontSize: 36, fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            )),
                    ),
                    Positioned(bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => _showPhotoDialog(context, auth),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.navyDeep, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(user.name,
                      style: GoogleFonts.inter(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(user.role.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ]),
          ),

          // ── Stats row ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.navySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _Stat(value: '${bp.completedBookings.length}', label: 'Jobs Done',  color: AppTheme.successColor),
                  _Vline(),
                  _Stat(value: '${bp.bookings.length}', label: 'Total Bookings', color: AppTheme.primaryColor),
                  _Vline(),
                  _Stat(value: user.phone.isNotEmpty ? '✓' : '—', label: 'Phone', color: AppTheme.accentColor),
                ]),
              ),
            ),
          ),

          // ── Sections ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _Section(title: 'Personal Information', items: [
                  _Tile(icon: Icons.phone_rounded,     label: 'Phone',
                      value: user.phone.isNotEmpty ? user.phone : 'Not set',
                      onTap: () => _showEditProfileDialog(context, auth)),
                  _Tile(icon: Icons.location_on_rounded, label: 'Location',
                      value: user.location?.fullAddress ?? 'Not set',
                      onTap: () => _updateLocationOnMap(context, auth)),
                ]),
                const SizedBox(height: 16),
                _Section(title: 'Settings', items: [
                  _Tile(icon: Icons.notifications_rounded, label: 'Notifications',
                      value: 'Enabled',
                      onTap: () => _info(context, 'Notifications',
                          'Push and email notifications are enabled for bookings and updates.')),
                  _Tile(icon: Icons.lock_rounded, label: 'Change Password',
                      value: 'Update securely',
                      onTap: () => _showChangePasswordDialog(context, auth)),
                  _Tile(icon: Icons.privacy_tip_rounded, label: 'Privacy',
                      value: 'Your data stays private',
                      onTap: () => _info(context, 'Privacy',
                          'Your data is only used for bookings and service matching within ProConnect.')),
                ]),
                const SizedBox(height: 16),
                _Section(title: 'Support', items: [
                  _Tile(icon: Icons.help_rounded, label: 'Help Center',
                      value: 'Browse tips & guides',
                      onTap: () => _info(context, 'Help Center',
                          'Use Browse to find providers, Bookings to manage jobs, and Profile to keep your account up to date.')),
                  _Tile(icon: Icons.feedback_rounded, label: 'Send Feedback',
                      value: 'Tell us what to improve',
                      onTap: () => _showFeedbackDialog(context)),
                  _Tile(icon: Icons.info_rounded, label: 'About',
                      value: 'App v1.0.0',
                      onTap: () => _info(context, 'About ProConnect',
                          'ProConnect helps customers discover trusted local service providers and manage bookings.')),
                ]),
                const SizedBox(height: 24),

                // Logout
                GestureDetector(
                  onTap: () => _showLogoutDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.errorColor.withAlpha(60)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.logout_rounded, color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 10),
                      Text('Sign Out',
                          style: GoogleFonts.inter(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ]),
                  ),
                ),
                const SizedBox(height: 36),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs (unchanged logic) ─────────────────────────────────────────────

  Future<void> _showEditProfileDialog(BuildContext context, AuthProvider auth) async {
    final user = auth.user!;
    final nameCtrl    = TextEditingController(text: user.name);
    final phoneCtrl   = TextEditingController(text: user.phone);
    final addrCtrl    = TextEditingController(text: user.location?.address ?? '');
    final cityCtrl    = TextEditingController(text: user.location?.city ?? '');
    final stateCtrl   = TextEditingController(text: user.location?.state ?? '');
    final zipCtrl     = TextEditingController(text: user.location?.zipCode ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl,  decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextField(controller: addrCtrl,  decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 12),
          TextField(controller: cityCtrl,  decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 12),
          TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State')),
          const SizedBox(height: 12),
          TextField(controller: zipCtrl,   decoration: const InputDecoration(labelText: 'Zip Code')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || !context.mounted) return;
    final hasLoc = addrCtrl.text.trim().isNotEmpty || cityCtrl.text.trim().isNotEmpty ||
        stateCtrl.text.trim().isNotEmpty || zipCtrl.text.trim().isNotEmpty;
    final ok = await auth.updateProfile(
      name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim(),
      location: hasLoc ? Location(address: addrCtrl.text.trim(), city: cityCtrl.text.trim(),
          state: stateCtrl.text.trim(), zipCode: zipCtrl.text.trim()) : null,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Profile updated!' : (auth.error ?? 'Failed to update')),
      backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
    ));
  }

  Future<void> _updateLocationOnMap(BuildContext context, AuthProvider auth) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerMap()),
    );

    if (result != null && result['location'] != null) {
      final latLng = result['location'] as LatLng;
      final address = result['address'] as String?;

      final ok = await auth.updateProfile(
        location: Location(
          address: address ?? '',
          city: '',
          state: '',
          zipCode: '',
          latitude: latLng.latitude,
          longitude: latLng.longitude,
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Location updated!' : 'Failed to update location'),
          backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
        ));
      }
    }
  }

  Future<void> _showPhotoDialog(BuildContext context, AuthProvider auth) async {
    final hasPhoto = auth.user?.profilePhoto?.isNotEmpty ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          color: AppTheme.navySurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2)),
          ),
          Text('Profile Photo',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded,
                color: AppTheme.primaryColor),
            title: const Text('Update from Gallery'),
            onTap: () async {
              Navigator.pop(ctx);
              final success = await auth.pickAndUploadAvatar();
              _showResult(context, success, auth.error);
            },
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.errorColor),
              title: const Text('Remove Current Photo',
                  style: TextStyle(color: AppTheme.errorColor)),
              onTap: () async {
                Navigator.pop(ctx);
                final success = await auth.removeAvatar();
                _showResult(context, success, auth.error);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showResult(BuildContext context, bool success, String? error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Photo updated!' : (error ?? 'Action cancelled')),
      backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
    ));
  }

  Future<void> _showChangePasswordDialog(BuildContext context, AuthProvider auth) async {
    final currCtrl = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: currCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password')),
          const SizedBox(height: 12),
          TextField(controller: newCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 12),
          TextField(controller: confCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );
    if (submit != true || !context.mounted) return;
    if (newCtrl.text != confCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match.'), backgroundColor: AppTheme.errorColor));
      return;
    }
    final ok = await auth.changePassword(currCtrl.text.trim(), newCtrl.text.trim());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Password changed!' : (auth.error ?? 'Failed')),
      backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
    ));
  }

  void _info(BuildContext context, String title, String msg) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(msg),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ),
  );

  Future<void> _showFeedbackDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(controller: ctrl, maxLines: 4,
            decoration: const InputDecoration(labelText: 'Your feedback',
                hintText: 'Tell us what should be improved...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Thanks for the feedback!'),
        backgroundColor: AppTheme.successColor,
      ));
    }
  }

  void _showLogoutDialog(BuildContext context) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          onPressed: () async {
            Navigator.pop(ctx);
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final bp   = Provider.of<BookingProvider>(context, listen: false);
            await auth.logout(bookingProvider: bp);
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false);
            }
          },
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
            fontSize: 11, color: AppTheme.textSecondary)),
      ]);
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 36, color: AppTheme.dividerColor);
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Tile> items;
  const _Section({required this.title, required this.items});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary, letterSpacing: 0.8)),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.navySurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(children: List.generate(items.length, (i) => Column(children: [
              items[i],
              if (i < items.length - 1)
                const Divider(height: 1, color: AppTheme.dividerColor, indent: 56),
            ]))),
          ),
        ],
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(value, style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
          ]),
        ),
      );
}
