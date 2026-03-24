import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';
import 'booking_details_screen.dart';
import 'browse_providers_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'provider_details_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});
  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;

  void _onTabTap(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTab(
        openBrowse: () => _onTabTap(1),
        openBookings: () => _onTabTap(2),
      ),
      const BrowseProvidersScreen(),
      const MyBookingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

/// Premium floating pill bottom navigation bar
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_outlined,     activeIcon: Icons.home_rounded,              label: 'Home'),
    (icon: Icons.search_outlined,   activeIcon: Icons.search_rounded,            label: 'Browse'),
    (icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded,  label: 'Bookings'),
    (icon: Icons.person_outline,    activeIcon: Icons.person_rounded,            label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.navyDeep,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.navySurface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.dividerColor, width: 1),
              boxShadow: AppTheme.glowShadow(AppTheme.primaryColor, blur: 20, spread: -4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final active = i == currentIndex;
                final item = _items[i];
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(
                        horizontal: active ? 20 : 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: active ? AppTheme.goldGradient : null,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        size: 22,
                        color: active ? Colors.white : AppTheme.textSecondary,
                      ),
                      if (active) ...[
                        const SizedBox(width: 6),
                        Text(item.label,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class HomeTab extends StatefulWidget {
  final VoidCallback openBrowse;
  final VoidCallback openBookings;
  const HomeTab({super.key, required this.openBrowse, required this.openBookings});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final pp = Provider.of<ProviderProvider>(context, listen: false);
    final bp = Provider.of<BookingProvider>(context, listen: false);
    if (pp.categories.isEmpty) await pp.loadCategories();
    await Future.wait([
      pp.loadProviders(refresh: true),
      bp.loadBookings(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pp   = Provider.of<ProviderProvider>(context);
    final bp   = Provider.of<BookingProvider>(context);

    final featuredProviders = pp.providers.take(6).toList();
    final recentBookings = bp.bookings
        .where((b) => !b.isCompleted && !b.isCancelled)
        .take(3)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accentColor,
      backgroundColor: AppTheme.navySurface,
      child: CustomScrollView(
        slivers: [
          // ── Gradient header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context, auth, bp),
          ),

          // ── Error banners ──────────────────────────────────────────────
          if (pp.error != null)
            SliverToBoxAdapter(child: _ErrorBanner(message: pp.error!, onRetry: _loadData)),
          if (bp.error != null)
            SliverToBoxAdapter(child: _ErrorBanner(message: bp.error!, onRetry: _loadData, isWarning: true)),

          // ── Categories ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _SectionHeader(title: 'Categories', onSeeAll: widget.openBrowse),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 116,
              child: pp.isLoading && pp.categories.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                      itemCount: pp.categories.length,
                      itemBuilder: (_, i) => _CategoryTile(
                        category: pp.categories[i],
                        onTap: () {
                          pp.setSelectedCategory(pp.categories[i]);
                          widget.openBrowse();
                        },
                      ),
                    ),
            ),
          ),

          // ── Active Bookings ────────────────────────────────────────────
          if (recentBookings.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: _SectionHeader(title: 'Active Bookings', onSeeAll: widget.openBookings),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _BookingTile(
                    booking: recentBookings[i],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            BookingDetailsScreen(bookingId: recentBookings[i].id))),
                  ),
                  childCount: recentBookings.length,
                ),
              ),
            ),
          ],

          // ── Featured Providers ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: _SectionHeader(title: 'Top Rated Providers', onSeeAll: widget.openBrowse),
            ),
          ),
          SliverToBoxAdapter(
            child: featuredProviders.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _EmptyCard(message: 'No providers available yet.'),
                  )
                : SizedBox(
                    height: 230,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                      itemCount: featuredProviders.length,
                      itemBuilder: (_, i) => _ProviderCard(
                        provider: featuredProviders[i],
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                                ProviderDetailsScreen(providerId: featuredProviders[i].id))),
                      ),
                    ),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth, BookingProvider bp) {
    final name = (auth.user?.name ?? 'Guest').split(' ').first;
    final photo = auth.user?.profilePhoto;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final topPad = MediaQuery.of(context).padding.top + 16;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.navyDeep, Color(0xFF0F1428), AppTheme.navyMid],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greeting,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          ])),
          // Avatar
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.glowShadow(AppTheme.primaryColor, blur: 16),
              ),
              child: (photo?.isNotEmpty ?? false)
                  ? ClipOval(child: Image.network(photo!, fit: BoxFit.cover))
                  : Center(child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'G',
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    )),
            ),
          ),
        ]),

        const SizedBox(height: 24),

        // Search bar
        GestureDetector(
          onTap: widget.openBrowse,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.navySurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor, width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Search for services...',
                  style: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 14))),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: AppTheme.primaryColor, size: 16),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 20),

        // Quick stats
        Row(children: [
          _QuickStat(
            icon: Icons.receipt_long_rounded,
            value: '${bp.bookings.where((b) => !b.isCompleted && !b.isCancelled).length}',
            label: 'Active',
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 10),
          _QuickStat(
            icon: Icons.check_circle_rounded,
            value: '${bp.completedBookings.length}',
            label: 'Done',
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 10),
          _QuickStat(
            icon: Icons.star_rounded,
            value: '4.9',
            label: 'Rating',
            color: const Color(0xFF7C3AED),
          ),
        ]),
      ]),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _QuickStat({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(60), width: 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
                ]),
            ),
          ]),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title,
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary))),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('See All',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor)),
              ),
            ),
        ],
      );
}

class _CategoryTile extends StatelessWidget {
  final dynamic category;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.onTap});

  IconData _icon(String s) {
    switch (s) {
      case 'electrical': return Icons.electrical_services_rounded;
      case 'plumbing':   return Icons.water_damage_rounded;
      case 'appliance':  return Icons.kitchen_rounded;
      case 'computer':   return Icons.computer_rounded;
      case 'maintenance': return Icons.home_repair_service_rounded;
      case 'tutoring':   return Icons.school_rounded;
      case 'beauty':     return Icons.spa_rounded;
      case 'automotive': return Icons.directions_car_rounded;
      default:           return Icons.handyman_rounded;
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.color ?? '#6C63FF');
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withAlpha(160)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.glowShadow(color, blur: 10, spread: -2),
              ),
              child: Icon(_icon(category.icon ?? ''), color: Colors.white, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              category.name ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ProviderCard extends StatefulWidget {
  final dynamic provider;
  final VoidCallback onTap;
  const _ProviderCard({required this.provider, required this.onTap});
  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final hasPhoto = (p.profileImage as String).isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 172,
          margin: const EdgeInsets.only(right: 14, bottom: 4),
          decoration: BoxDecoration(
            color: AppTheme.navySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.dividerColor, width: 1),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar header
            Container(
              height: 92,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(alignment: Alignment.center, children: [
                // Decorative bg circle
                Positioned(right: -20, bottom: -20,
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(15),
                    ),
                  ),
                ),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.navySurface,
                    border: Border.all(color: AppTheme.accentColor, width: 2),
                  ),
                  child: hasPhoto
                      ? ClipOval(child: Image.network(p.profileImage, fit: BoxFit.cover))
                      : Center(child: Text(
                          (p.displayName as String).isNotEmpty
                              ? (p.displayName as String)[0].toUpperCase() : 'P',
                          style: GoogleFonts.inter(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary),
                        )),
                ),
                // Verified badge
                if (p.isVerified == true)
                  Positioned(top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.navySurface, width: 1.5),
                      ),
                      child: const Icon(Icons.check, size: 9, color: Colors.white),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.displayName ?? 'Provider',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 3),
                // Category pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(p.category?.name ?? 'Service',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor)),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 14, color: AppTheme.accentColor),
                  const SizedBox(width: 3),
                  Text((p.rating as double).toStringAsFixed(1),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const Spacer(),
                  Text('₹${(p.hourlyRate as double).toStringAsFixed(0)}/hr',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppTheme.accentColor)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final dynamic booking;
  final VoidCallback onTap;
  const _BookingTile({required this.booking, required this.onTap});

  Color _statusColor() {
    try { return booking.statusColor as Color; } catch (_) { return AppTheme.primaryColor; }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.navySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80), width: 1),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.provider?.displayName ?? 'Unknown Provider',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            Text('${booking.scheduledDate} at ${booking.scheduledTime}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(booking.statusDisplay ?? 'Pending',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.navySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Text(message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.textSecondary)),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isWarning;
  const _ErrorBanner({required this.message, required this.onRetry, this.isWarning = false});
  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AppTheme.warningColor : AppTheme.errorColor;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(children: [
        Icon(isWarning ? Icons.warning_rounded : Icons.error_rounded, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
            style: GoogleFonts.inter(fontSize: 12, color: color))),
        TextButton(
          onPressed: onRetry,
          child: Text('Retry', style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
