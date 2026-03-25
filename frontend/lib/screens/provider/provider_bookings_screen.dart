import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../utils/theme.dart';
import '../chat_screen.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
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
    await bp.loadBookings(role: 'provider');
  }

  Future<void> _refresh() => _load();

  Future<void> _handleAction(String action, Booking booking) async {
    final bp = Provider.of<BookingProvider>(context, listen: false);

    bool success = false;
    switch (action) {
      case 'accept':
        success = await bp.acceptBooking(booking.id);
        break;
      case 'start':
        success = await bp.startBooking(booking.id);
        break;
      case 'complete':
        success = await bp.completeBooking(booking.id);
        break;
      case 'cancel':
        success = await bp.cancelBooking(booking.id);
        break;
    }

    if (!mounted) return;

    final msg = success
        ? switch (action) {
            'accept' => 'Booking accepted!',
            'start' => 'Service started!',
            'complete' => 'Booking marked as completed!',
            'cancel' => 'Booking declined.',
            _ => 'Updated successfully.',
          }
        : (bp.error ?? 'Unable to update booking.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
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
                      onAction: _handleAction,
                      emptyMessage: 'No bookings yet.\nCustomers will appear here.',
                    ),
                    _BookingsList(
                      bookings: bp.pendingBookings,
                      onRefresh: _refresh,
                      onAction: _handleAction,
                      emptyMessage: 'No pending requests.',
                    ),
                    _BookingsList(
                      bookings: bp.activeBookings,
                      onRefresh: _refresh,
                      onAction: _handleAction,
                      emptyMessage: 'No active jobs.',
                    ),
                    _BookingsList(
                      bookings: bp.completedBookings,
                      onRefresh: _refresh,
                      onAction: null,
                      emptyMessage: 'No completed jobs yet.',
                    ),
                    _BookingsList(
                      bookings: bp.cancelledBookings,
                      onRefresh: _refresh,
                      onAction: null,
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

// ─── Error Banner ─────────────────────────────────────────────────────────────

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
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppTheme.errorColor, fontSize: 13)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─── Bookings List ────────────────────────────────────────────────────────────

class _BookingsList extends StatelessWidget {
  final List<Booking> bookings;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String, Booking)? onAction;
  final String emptyMessage;

  const _BookingsList({
    required this.bookings,
    required this.onRefresh,
    required this.onAction,
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
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15),
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
        itemBuilder: (ctx, i) => _BookingCard(
          booking: bookings[i],
          onAction: onAction,
        ),
      ),
    );
  }
}

// ─── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final Future<void> Function(String, Booking)? onAction;

  const _BookingCard({required this.booking, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final statusColor = booking.statusColor;
    final customerName = booking.customer?.name ?? 'Unknown Customer';
    final photo = booking.customer?.profilePhoto;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer info + status
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      (photo?.isNotEmpty ?? false) ? NetworkImage(photo!) : null,
                  child: (photo?.isNotEmpty ?? false)
                      ? null
                      : const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${booking.scheduledDate} at ${booking.scheduledTime}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              bookingId: booking.id,
                              otherUserName: customerName,
                            ),
                          ),
                        );
                      },
                    ),
                    _StatusChip(label: booking.statusDisplay, color: statusColor),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
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
                  '\$${booking.price.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor),
                ),
                if (onAction != null) _actionButtons(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    if (booking.isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () => onAction!('cancel', booking),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Decline'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => onAction!('accept', booking),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Accept'),
          ),
        ],
      );
    }

    if (booking.isAccepted) {
      return ElevatedButton(
        onPressed: () => onAction!('start', booking),
        style:
            ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
        child: const Text('Start Service'),
      );
    }

    if (booking.isInProgress) {
      return ElevatedButton(
        onPressed: () => onAction!('complete', booking),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text('Complete'),
      );
    }

    return const SizedBox.shrink();
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