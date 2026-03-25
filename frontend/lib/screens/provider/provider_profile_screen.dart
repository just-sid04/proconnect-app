import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/provider_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});
  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async =>
      Provider.of<ProviderProvider>(context, listen: false)
          .getMyProviderProfile();

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pp = Provider.of<ProviderProvider>(context, listen: false);
    final bp = Provider.of<BookingProvider>(context, listen: false);
    await auth.logout(bookingProvider: bp);
    pp.reset();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pp = Provider.of<ProviderProvider>(context);
    final p = pp.currentProvider;
    final user = auth.user;

    if (pp.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.navyMid,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (p == null) return _buildNoProfile();

    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.accentColor,
        backgroundColor: AppTheme.navySurface,
        child: CustomScrollView(slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(user, p, pp, auth)),

          // ── Stats ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.navySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat(
                          value: p.rating.toStringAsFixed(1),
                          label: 'Rating',
                          icon: Icons.star_rounded,
                          color: AppTheme.accentColor),
                      _Vline(),
                      _Stat(
                          value: '${p.totalReviews}',
                          label: 'Reviews',
                          icon: Icons.reviews_rounded,
                          color: AppTheme.primaryColor),
                      _Vline(),
                      _Stat(
                          value: '${p.totalBookings}',
                          label: 'Jobs',
                          icon: Icons.work_rounded,
                          color: AppTheme.successColor),
                    ]),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              // Rate & Experience
              _card(children: [
                _Row(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Hourly Rate',
                    value: '₹${p.hourlyRate.toStringAsFixed(0)} / hour',
                    color: AppTheme.accentColor),
                const Divider(
                    height: 1, color: AppTheme.dividerColor, indent: 52),
                _Row(
                    icon: Icons.timeline_rounded,
                    label: 'Experience',
                    value: '${p.experience} years',
                    color: AppTheme.primaryColor),
              ]),
              const SizedBox(height: 14),

              // About
              if (p.description.isNotEmpty) ...[
                const _SectionLabel('About'),
                _card(children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(p.description,
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            height: 1.6)),
                  ),
                ]),
                const SizedBox(height: 14),
              ],

              // Skills
              if (p.skills.isNotEmpty) ...[
                const _SectionLabel('Skills'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: p.skills
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                  color: AppTheme.primaryColor.withAlpha(60)),
                            ),
                            child: Text(s,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
              ],

              // Coverage
              const _SectionLabel('Service Coverage'),
              _card(children: [
                _Row(
                    icon: Icons.location_on_rounded,
                    label: 'Service Radius',
                    value: '${p.serviceArea} miles',
                    color: AppTheme.successColor),
                if (user?.location?.fullAddress != null) ...[
                  const Divider(
                      height: 1, color: AppTheme.dividerColor, indent: 52),
                  _Row(
                      icon: Icons.home_rounded,
                      label: 'Base Location',
                      value: user?.location?.fullAddress ?? '',
                      color: AppTheme.textSecondary),
                ],
              ]),
              const SizedBox(height: 14),

              // Availability
              Row(children: [
                const Expanded(child: _SectionLabel('Availability')),
                GestureDetector(
                  onTap: () => _showEditAvailabilityDialog(context, pp),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.edit_rounded,
                          size: 12, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text('Edit',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor)),
                    ]),
                  ),
                ),
              ]),
              _card(children: _availabilityRows(p.availability)),
              const SizedBox(height: 24),

              // Logout
              GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppTheme.errorColor.withAlpha(60)),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded,
                            color: AppTheme.errorColor, size: 20),
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
            ])),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(
      dynamic user, dynamic provider, ProviderProvider pp, AuthProvider auth) {
    final name = user?.name ?? provider.displayName;
    final photo = user?.profilePhoto;
    final hasPhoto = (photo as String?)?.isNotEmpty ?? false;
    final verified = provider.isVerified as bool? ?? false;

    return Stack(children: [
      Container(
        height: 230,
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
      ),
      Positioned(
          top: -40,
          right: -40,
          child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.primaryColor.withAlpha(55),
                    AppTheme.primaryColor.withAlpha(0)
                  ])))),
      SafeArea(
          child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            Text('Provider Profile',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => _showEditProviderDialog(context, pp),
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
        const SizedBox(height: 14),
        Stack(alignment: Alignment.center, children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              border: Border.all(color: AppTheme.accentColor, width: 3),
              boxShadow: AppTheme.glowShadow(AppTheme.primaryColor, blur: 20),
            ),
            child: hasPhoto
                ? ClipOval(child: Image.network(photo!, fit: BoxFit.cover))
                : Center(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P',
                        style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
          ),
          Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showPhotoDialog(context, auth),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.navyDeep, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 14, color: Colors.white),
                ),
              )),
        ]),
        const SizedBox(height: 10),
        Text(name,
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(provider.category?.name ?? 'Service Provider',
            style:
                GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: verified
                ? AppTheme.successColor.withAlpha(30)
                : AppTheme.warningColor.withAlpha(30),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
                color: verified
                    ? AppTheme.successColor.withAlpha(80)
                    : AppTheme.warningColor.withAlpha(80)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              verified ? Icons.verified_rounded : Icons.pending_rounded,
              size: 12,
              color: verified ? AppTheme.successColor : AppTheme.warningColor,
            ),
            const SizedBox(width: 5),
            Text(
              verified
                  ? 'Verified Provider'
                  : 'Verification ${(provider.verificationStatus as String).toUpperCase()}',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      verified ? AppTheme.successColor : AppTheme.warningColor,
                  letterSpacing: 0.5),
            ),
          ]),
        ),
        const SizedBox(height: 20),
      ])),
    ]);
  }

  Widget _buildNoProfile() => Scaffold(
        backgroundColor: AppTheme.navyMid,
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: AppTheme.navySurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.dividerColor)),
              child: const Icon(Icons.work_outline_rounded,
                  size: 40, color: AppTheme.textHint),
            ),
            const SizedBox(height: 20),
            Text('No Provider Profile',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Create your provider profile to start receiving bookings.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow:
                      AppTheme.glowShadow(AppTheme.primaryColor, blur: 16)),
              child: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/create-provider-profile'),
                child: Text('Create Profile',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _logout,
              icon:
                  const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
              label: Text('Sign Out',
                  style: GoogleFonts.inter(
                      color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
            ),
          ]),
        )),
      );

  List<Widget> _availabilityRows(Availability availability) {
    final days = [
      ('Monday', availability.monday),
      ('Tuesday', availability.tuesday),
      ('Wednesday', availability.wednesday),
      ('Thursday', availability.thursday),
      ('Friday', availability.friday),
      ('Saturday', availability.saturday),
      ('Sunday', availability.sunday),
    ];
    return List.generate(days.length, (i) {
      final (day, avail) = days[i];
      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(children: [
            Text(day,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: avail.available
                    ? AppTheme.successColor.withAlpha(25)
                    : AppTheme.errorColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                avail.available
                    ? '${avail.startTime} – ${avail.endTime}'
                    : 'Unavailable',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: avail.available
                        ? AppTheme.successColor
                        : AppTheme.errorColor),
              ),
            ),
          ]),
        ),
        if (i < days.length - 1)
          const Divider(height: 1, color: AppTheme.dividerColor),
      ]);
    });
  }

  Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
            color: AppTheme.navySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.dividerColor)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  // ── Dialogs (same logic as before) ────────────────────────────────────────

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

  Future<void> _showEditProviderDialog(
      BuildContext context, ProviderProvider pp) async {
    final p = pp.currentProvider;
    if (p == null) return;
    final rateCtrl = TextEditingController(text: p.hourlyRate.toString());
    final expCtrl = TextEditingController(text: p.experience.toString());
    final areaCtrl = TextEditingController(text: p.serviceArea.toString());
    final descCtrl = TextEditingController(text: p.description);
    final skillCtrl =
        TextEditingController(text: (p.skills as List).join(', '));
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Edit Provider Profile'),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Hourly rate')),
                const SizedBox(height: 12),
                TextField(
                    controller: expCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Experience (years)')),
                const SizedBox(height: 12),
                TextField(
                    controller: areaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Service area (miles)')),
                const SizedBox(height: 12),
                TextField(
                    controller: skillCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Skills', hintText: 'Comma-separated')),
                const SizedBox(height: 12),
                TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
              ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Save')),
              ],
            ));
    if (ok != true || !context.mounted) return;
    final skills = (skillCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)).toList();
    final success = await pp.updateProviderProfile(
      id: p.id,
      hourlyRate: double.tryParse(rateCtrl.text.trim()),
      experience: int.tryParse(expCtrl.text.trim()),
      serviceArea: int.tryParse(areaCtrl.text.trim()),
      skills: skills,
      description: descCtrl.text.trim(),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Profile updated!' : (pp.error ?? 'Failed')),
      backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
    ));
  }

  Future<void> _showEditAvailabilityDialog(
      BuildContext context, ProviderProvider pp) async {
    final p = pp.currentProvider;
    if (p == null) return;
    final editableDays = {
      'Monday': EditableDayAvailability.fromDay(p.availability.monday),
      'Tuesday': EditableDayAvailability.fromDay(p.availability.tuesday),
      'Wednesday': EditableDayAvailability.fromDay(p.availability.wednesday),
      'Thursday': EditableDayAvailability.fromDay(p.availability.thursday),
      'Friday': EditableDayAvailability.fromDay(p.availability.friday),
      'Saturday': EditableDayAvailability.fromDay(p.availability.saturday),
      'Sunday': EditableDayAvailability.fromDay(p.availability.sunday),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (_, setDs) => AlertDialog(
                title: const Text('Edit Availability'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: editableDays.entries.map((e) {
                      final avail = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.dividerColor)),
                          child: Column(children: [
                            Row(children: [
                              Expanded(
                                  child: Text(e.key,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600))),
                              Switch(
                                  value: avail.available,
                                  onChanged: (v) =>
                                      setDs(() => avail.available = v)),
                            ]),
                            if (avail.available)
                              Row(children: [
                                Expanded(
                                    child: OutlinedButton(
                                  onPressed: () async {
                                    final t = await _pickTime(
                                        context, avail.startTime);
                                    if (t != null)
                                      setDs(() => avail.startTime = t);
                                  },
                                  child: Text('Start: ${avail.startTime}'),
                                )),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: OutlinedButton(
                                  onPressed: () async {
                                    final t =
                                        await _pickTime(context, avail.endTime);
                                    if (t != null)
                                      setDs(() => avail.endTime = t);
                                  },
                                  child: Text('End: ${avail.endTime}'),
                                )),
                              ]),
                          ]),
                        ),
                      );
                    }).toList(),
                  )),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Save')),
                ],
              )),
    );
    if (ok != true || !context.mounted) return;
    final success = await pp.updateProviderProfile(
      id: p.id,
      availability: Availability(
        monday: editableDays['Monday']!.toDayAvailability(),
        tuesday: editableDays['Tuesday']!.toDayAvailability(),
        wednesday: editableDays['Wednesday']!.toDayAvailability(),
        thursday: editableDays['Thursday']!.toDayAvailability(),
        friday: editableDays['Friday']!.toDayAvailability(),
        saturday: editableDays['Saturday']!.toDayAvailability(),
        sunday: editableDays['Sunday']!.toDayAvailability(),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Availability updated!' : (pp.error ?? 'Failed')),
      backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
    ));
  }

  Future<String?> _pickTime(BuildContext context, String initial) async {
    final parts = initial.split(':');
    final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
            hour: int.tryParse(parts.first) ?? 9,
            minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0));
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

// ─── EditableDayAvailability (same as before) ─────────────────────────────────

class EditableDayAvailability {
  bool available;
  String startTime, endTime;
  EditableDayAvailability(
      {required this.available,
      required this.startTime,
      required this.endTime});
  factory EditableDayAvailability.fromDay(DayAvailability d) =>
      EditableDayAvailability(
          available: d.available,
          startTime: d.startTime.isNotEmpty ? d.startTime : '09:00',
          endTime: d.endTime.isNotEmpty ? d.endTime : '17:00');
  DayAvailability toDayAvailability() => DayAvailability(
      available: available,
      startTime: available ? startTime : '',
      endTime: available ? endTime : '');
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _Stat(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
      ]);
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: AppTheme.dividerColor);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8)),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _Row(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ])),
        ]),
      );
}
