import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../utils/theme.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    await bookingProvider.loadBookings(role: 'provider', refresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleAction(String action, Booking booking) async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    bool success = false;
    switch (action) {
      case 'accept':
        success = await bookingProvider.acceptBooking(booking.id);
        break;

      case 'start':
        success = await bookingProvider.startBooking(booking.id);
        break;

      case 'complete':
        success = await bookingProvider.completeBooking(booking.id);
        break;

      case 'cancel':
        success = await bookingProvider.cancelBooking(booking.id);
        break;
    }

    if (!mounted) return;

    final successMessage = switch (action) {
      'accept' => 'Booking accepted successfully.',
      'start' => 'Booking started successfully.',
      'complete' => 'Booking completed successfully.',
      'cancel' => 'Booking declined successfully.',
      _ => 'Booking updated successfully.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? successMessage : (bookingProvider.error ?? 'Unable to update booking.'),
        ),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );

    if (success) {
      await bookingProvider.loadBookings(role: 'provider', refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Pending"),
            Tab(text: "Active"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading &&
              bookingProvider.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingsList(
                bookings: bookingProvider.bookings,
                onAction: _handleAction,
              ),
              _BookingsList(
                bookings: bookingProvider.pendingBookings,
                onAction: _handleAction,
              ),
              _BookingsList(
                bookings: bookingProvider.activeBookings,
                onAction: _handleAction,
              ),
              _BookingsList(
                bookings: bookingProvider.completedBookings,
                onAction: _handleAction,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<Booking> bookings;
  final Function(String, Booking) onAction;

  const _BookingsList({
    required this.bookings,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return _emptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        final provider =
            Provider.of<BookingProvider>(context, listen: false);
        await provider.loadBookings(role: "provider", refresh: true);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];

          return _BookingCard(
            booking: booking,
            onAction: onAction,
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            "No bookings yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final Function(String, Booking) onAction;

  const _BookingCard({
    required this.booking,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = booking.statusColor;
    final profilePhoto = booking.customer?.profilePhoto;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: profilePhoto != null &&
                          profilePhoto.isNotEmpty
                      ? NetworkImage(profilePhoto)
                      : null,
                  child: profilePhoto == null || profilePhoto.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customer?.name ?? "Unknown",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${booking.scheduledDate} at ${booking.scheduledTime}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            Text(
              booking.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${booking.price.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                _actionButtons(),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _actionButtons() {
    if (booking.isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () => onAction("cancel", booking),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text("Decline"),
          ),

          const SizedBox(width: 8),

          ElevatedButton(
            onPressed: () => onAction("accept", booking),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text("Accept"),
          ),
        ],
      );
    }

    if (booking.isAccepted) {
      return ElevatedButton(
        onPressed: () => onAction("start", booking),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text("Start Service"),
      );
    }

    if (booking.isInProgress) {
      return ElevatedButton(
        onPressed: () => onAction("complete", booking),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text("Complete"),
      );
    }

    return const SizedBox.shrink();
  }
}