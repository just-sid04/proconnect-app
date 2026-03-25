import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';
import 'earnings_screen.dart';
import 'provider_bookings_screen.dart';
import 'provider_profile_screen.dart';
import 'schedule_screen.dart';
import 'blocked_dates_screen.dart';
import '../chat_screen.dart';
import '../common/messages_list_screen.dart';
import '../../providers/chat_provider.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});
  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _currentIndex = 0;

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      Provider.of<BookingProvider>(context, listen: false)
          .loadBookings(role: 'provider', refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProviderDashboardTab(
        openBookings: () => _onTabTap(1),
        openProfile: () => _onTabTap(4),
      ),
      const ProviderBookingsScreen(),
      const MessagesListScreen(),
      const EarningsScreen(),
      const ProviderProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _ProviderNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

/// Premium floating pill nav bar for provider
class _ProviderNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _ProviderNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard'
    ),
    (
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Bookings'
    ),
    (
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Messages'
    ),
    (
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Earnings'
    ),
    (
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile'
    ),
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
              boxShadow: AppTheme.glowShadow(AppTheme.primaryColor,
                  blur: 20, spread: -4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final active = i == currentIndex;
                final item = _items[i];
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.symmetric(
                            horizontal: active ? 18 : 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: active ? AppTheme.primaryGradient : null,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(children: [
                          Icon(active ? item.activeIcon : item.icon,
                              size: 22,
                              color:
                                  active ? Colors.white : AppTheme.textSecondary),
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
                      // Notification badge for Messages (index 2)
                      if (i == 2 && !active)
                        Consumer<ChatProvider?>(
                          builder: (context, chat, _) {
                            final count = chat?.unreadConversationsCount ?? 0;
                            if (count > 0) {
                              return Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.errorColor,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
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

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class ProviderDashboardTab extends StatefulWidget {
  final VoidCallback openBookings;
  final VoidCallback openProfile;
  const ProviderDashboardTab(
      {super.key, required this.openBookings, required this.openProfile});
  @override
  State<ProviderDashboardTab> createState() => _ProviderDashboardTabState();
}

class _ProviderDashboardTabState extends State<ProviderDashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final bp = Provider.of<BookingProvider>(context, listen: false);
    final pp = Provider.of<ProviderProvider>(context, listen: false);
    await Future.wait([
      bp.loadBookings(role: 'provider', refresh: true),
      pp.getMyProviderProfile(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bp = Provider.of<BookingProvider>(context);
    final pp = Provider.of<ProviderProvider>(context);

    final pending = bp.pendingBookings;
    final active = bp.activeBookings;
    final completed = bp.completedBookings;
    final provider = pp.currentProvider;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accentColor,
      backgroundColor: AppTheme.navySurface,
      child: CustomScrollView(
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(auth, provider)),

          // --- NON-BLOCKING LOADING INDICATOR ---
          if (bp.isLoading && bp.bookings.isNotEmpty)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                minHeight: 2,
              ),
            ),

          if (bp.isLoading && bp.bookings.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            )
          else if (bp.error != null && bp.bookings.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 48),
                      const SizedBox(height: 16),
                      Text(bp.error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // ── KPI cards ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(children: [
                  Expanded(
                      child: _KpiCard(
                          label: 'Pending',
                          value: '${pending.length}',
                          icon: Icons.pending_actions_rounded,
                          color: AppTheme.warningColor)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _KpiCard(
                          label: 'Active',
                          value: '${active.length}',
                          icon: Icons.construction_rounded,
                          color: AppTheme.primaryColor)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _KpiCard(
                          label: 'Done',
                          value: '${completed.length}',
                          icon: Icons.check_circle_rounded,
                          color: AppTheme.successColor)),
                ]),
              ),
            ),

            // ── Quick actions ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(children: [
                  Expanded(
                      child: _ActionBtn(
                          icon: Icons.calendar_today_rounded,
                          label: 'Bookings',
                          color: AppTheme.primaryColor,
                          onTap: widget.openBookings)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _ActionBtn(
                          icon: Icons.access_time_rounded,
                          label: 'Schedule',
                          color: AppTheme.accentColor,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ScheduleScreen())))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _ActionBtn(
                          icon: Icons.event_busy_rounded,
                          label: 'Holidays',
                          color: const Color(0xFF7C3AED),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BlockedDatesScreen())))),
                ]),
              ),
            ),

            // ── Pending Requests ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(children: [
                  Expanded(
                      child: Text('New Requests',
                          style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary))),
                  if (pending.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${pending.length} new',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.warningColor)),
                    ),
                ]),
              ),
            ),
            if (pending.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _EmptyBox(message: 'No new booking requests'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                  (_, i) => _PendingCard(booking: pending[i]),
                  childCount: pending.length,
                )),
              ),

            // ── Active Jobs ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text('Active Jobs',
                    style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
              ),
            ),
            if (active.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _EmptyBox(message: 'No active jobs right now'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                  (_, i) => _ActiveJobCard(booking: active[i]),
                  childCount: active.length,
                )),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, dynamic provider) {
    final name = (auth.user?.name ?? 'Provider').split(' ').first;
    final photo = auth.user?.profilePhoto;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(greeting,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 3),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          if (provider != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppTheme.successColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(provider.category?.name ?? 'Service Provider',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500)),
            ]),
          ],
        ])),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            border: Border.all(color: AppTheme.accentColor, width: 2),
            boxShadow: AppTheme.glowShadow(AppTheme.primaryColor, blur: 16),
          ),
          child: (photo?.isNotEmpty ?? false)
              ? ClipOval(child: Image.network(photo!, fit: BoxFit.cover))
              : Center(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P',
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white))),
        ),
      ]),
    );
  }
}

// ─── KPI Card ────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(40), color.withAlpha(15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80), width: 1),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 11, color: color.withAlpha(180))),
        ]),
      );
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      );
}

// ─── Pending Request Card ─────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final dynamic booking;
  const _PendingCard({required this.booking});
  @override
  Widget build(BuildContext context) {
    final bp = Provider.of<BookingProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navySurface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.warningColor.withAlpha(60), width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: AppTheme.goldGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Text(
              ((booking.customer?.name as String?) ?? 'C').isNotEmpty
                  ? (booking.customer!.name as String)[0].toUpperCase()
                  : 'C',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(booking.customer?.name ?? 'Customer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text('${booking.scheduledDate} at ${booking.scheduledTime}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('₹${booking.price.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warningColor)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(bookingId: booking.id, otherUserName: booking.customer?.name ?? 'Customer')
            )),
          ),
        ]),
        if ((booking.description as String).isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(booking.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  bp.cancelBooking(booking.id, reason: 'Declined by provider'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorColor.withAlpha(60)),
                ),
                child: Center(
                    child: Text('Decline',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.errorColor))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => bp.acceptBooking(booking.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppTheme.successGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      AppTheme.glowShadow(AppTheme.successColor, blur: 12),
                ),
                child: Center(
                    child: Text('Accept',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white))),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Active Job Card ──────────────────────────────────────────────────────────

class _ActiveJobCard extends StatelessWidget {
  final dynamic booking;
  const _ActiveJobCard({required this.booking});
  @override
  Widget build(BuildContext context) {
    final bp = Provider.of<BookingProvider>(context, listen: false);
    final isAccepted = booking.isAccepted as bool? ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navySurface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.primaryColor.withAlpha(50), width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
              child: Text(
            ((booking.customer?.name as String?) ?? 'C').isNotEmpty
                ? (booking.customer!.name as String)[0].toUpperCase()
                : 'C',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking.customer?.name ?? 'Customer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          Text('${booking.scheduledDate} · ${booking.scheduledTime}',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ])),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryColor),
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChatScreen(bookingId: booking.id, otherUserName: booking.customer?.name ?? 'Customer')
          )),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => isAccepted
              ? bp.startBooking(booking.id)
              : bp.completeBooking(booking.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isAccepted
                  ? AppTheme.primaryGradient
                  : AppTheme.successGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.glowShadow(
                  isAccepted ? AppTheme.primaryColor : AppTheme.successColor,
                  blur: 12),
            ),
            child: Text(isAccepted ? 'Start' : 'Complete',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;
  const _EmptyBox({required this.message});
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
            style:
                GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
      );
}
