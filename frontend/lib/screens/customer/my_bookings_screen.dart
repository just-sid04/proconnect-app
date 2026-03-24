import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../utils/theme.dart';
import 'booking_details_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _load();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final bp = Provider.of<BookingProvider>(context, listen: false);
    await bp.loadBookings(role: 'customer');
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bp, _) {
          // Show error banner if present (but still show list below)
          return Column(
            children: [
              if (bp.error != null && bp.bookings.isEmpty)
                _ErrorBanner(message: bp.error!, onRetry: _refresh),
              if (bp.isLoading && bp.bookings.isEmpty)
                const LinearProgressIndicator(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BookingsList(
                      bookings: bp.bookings,
                      onRefresh: _refresh,
                      emptyMessage: 'No bookings yet.\nBook a service to get started!',
                    ),
                    _BookingsList(
                      bookings: bp.pendingBookings,
                      onRefresh: _refresh,
                      emptyMessage: 'No pending bookings.',
                    ),
                    _BookingsList(
                      bookings: bp.activeBookings,
                      onRefresh: _refresh,
                      emptyMessage: 'No active bookings.',
                    ),
                    _BookingsList(
                      bookings: bp.completedBookings,
                      onRefresh: _refresh,
                      emptyMessage: 'No completed bookings.',
                    ),
                    _BookingsList(
                      bookings: bp.cancelledBookings,
                      onRefresh: _refresh,
                      emptyMessage: 'No cancelled bookings.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.errorColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<Booking> bookings;
  final Future<void> Function() onRefresh;
  final String emptyMessage;

  const _BookingsList({
    required this.bookings,
    required this.onRefresh,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) =>
            _BookingCard(booking: bookings[index]),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = booking.statusColor;
    final providerName =
        booking.provider?.user?.name ?? booking.provider?.displayName ?? 'Unknown Provider';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailsScreen(bookingId: booking.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: provider + status
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        (booking.provider?.user?.profilePhoto?.isNotEmpty ?? false)
                            ? NetworkImage(booking.provider!.user!.profilePhoto!)
                            : null,
                    child: (booking.provider?.user?.profilePhoto?.isNotEmpty ?? false)
                        ? null
                        : const Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          booking.provider?.category?.name ?? 'Service',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(label: booking.statusDisplay, color: statusColor),
                ],
              ),
              const Divider(height: 20),
              // Date & time
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.scheduledDate} at ${booking.scheduledTime}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Description
              Text(
                booking.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              // Price row
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
                  const Row(
                    children: [
                      Text('View Details',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      Icon(Icons.chevron_right,
                          size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
