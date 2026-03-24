import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';
import 'earnings_screen.dart';
import 'provider_bookings_screen.dart';
import 'provider_profile_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProviderDashboardTab(
        openBookings: () => setState(() => _currentIndex = 1),
        openProfile: () => setState(() => _currentIndex = 3),
      ),
      const ProviderBookingsScreen(),
      const EarningsScreen(),
      const ProviderProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ProviderDashboardTab extends StatefulWidget {
  final VoidCallback openBookings;
  final VoidCallback openProfile;

  const ProviderDashboardTab({
    super.key,
    required this.openBookings,
    required this.openProfile,
  });

  @override
  State<ProviderDashboardTab> createState() => _ProviderDashboardTabState();
}

class _ProviderDashboardTabState extends State<ProviderDashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final providerProvider = Provider.of<ProviderProvider>(context, listen: false);

    await Future.wait([
      bookingProvider.loadBookings(role: 'provider', refresh: true),
      providerProvider.getMyProviderProfile(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final providerProvider = Provider.of<ProviderProvider>(context);

    final pendingRequests = bookingProvider.pendingBookings;
    final activeBookings = bookingProvider.activeBookings;
    final completedBookings = bookingProvider.completedBookings;
    final provider = providerProvider.currentProvider;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.user?.name ?? 'Provider',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundImage: (authProvider.user?.profilePhoto?.isNotEmpty ?? false)
                      ? NetworkImage(authProvider.user!.profilePhoto!)
                      : null,
                  child: !(authProvider.user?.profilePhoto?.isNotEmpty ?? false)
                      ? const Icon(Icons.person)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Pending',
                    value: '${pendingRequests.length}',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Active',
                    value: '${activeBookings.length}',
                    icon: Icons.work,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Completed',
                    value: '${completedBookings.length}',
                    icon: Icons.check_circle,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionChip(
                  icon: Icons.schedule,
                  label: 'Set Availability',
                  onTap: widget.openProfile,
                ),
                _ActionChip(
                  icon: Icons.edit,
                  label: 'Edit Profile',
                  onTap: widget.openProfile,
                ),
                _ActionChip(
                  icon: Icons.share,
                  label: 'Share Profile',
                  onTap: () => _shareProfile(provider),
                ),
                _ActionChip(
                  icon: Icons.receipt_long,
                  label: 'View Bookings',
                  onTap: widget.openBookings,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'New Booking Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (pendingRequests.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No new booking requests.'),
                ),
              )
            else
              ...pendingRequests.map((booking) => _PendingRequestCard(booking: booking)),
            const SizedBox(height: 24),
            const Text(
              'Active Bookings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (activeBookings.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No active jobs right now.'),
                ),
              )
            else
              ...activeBookings.map((booking) => _ActiveBookingCard(booking: booking)),
          ],
        ),
      ),
    );
  }

  void _shareProfile(dynamic provider) {
    final message = provider == null
        ? 'Create your provider profile first.'
        : 'Share this provider profile with customers:\n\n${provider.displayName}\nProvider ID: ${provider.id}\nCategory: ${provider.category?.name ?? 'Service Provider'}';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share Profile'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final dynamic booking;

  const _PendingRequestCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: (booking.customer?.profilePhoto?.isNotEmpty ?? false)
                      ? NetworkImage(booking.customer!.profilePhoto!)
                      : null,
                  child: !(booking.customer?.profilePhoto?.isNotEmpty ?? false)
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customer?.name ?? 'Unknown Customer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${booking.scheduledDate} at ${booking.scheduledTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(booking.description),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${booking.price.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final bookingProvider =
                            Provider.of<BookingProvider>(context, listen: false);
                        await bookingProvider.cancelBooking(
                          booking.id,
                          reason: 'Declined by provider',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                      child: const Text('Decline'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final bookingProvider =
                            Provider.of<BookingProvider>(context, listen: false);
                        await bookingProvider.acceptBooking(booking.id);
                      },
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBookingCard extends StatelessWidget {
  final dynamic booking;

  const _ActiveBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (booking.customer?.profilePhoto?.isNotEmpty ?? false)
              ? NetworkImage(booking.customer!.profilePhoto!)
              : null,
          child: !(booking.customer?.profilePhoto?.isNotEmpty ?? false)
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(
          booking.customer?.name ?? 'Unknown Customer',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${booking.scheduledDate} at ${booking.scheduledTime}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: booking.isAccepted
            ? ElevatedButton(
                onPressed: () async {
                  final bookingProvider =
                      Provider.of<BookingProvider>(context, listen: false);
                  await bookingProvider.startBooking(booking.id);
                },
                child: const Text('Start'),
              )
            : ElevatedButton(
                onPressed: () async {
                  final bookingProvider =
                      Provider.of<BookingProvider>(context, listen: false);
                  await bookingProvider.completeBooking(booking.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
                child: const Text('Complete'),
              ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      side: BorderSide.none,
    );
  }
}
