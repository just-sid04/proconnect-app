import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
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
    final bookingProvider = Provider.of<BookingProvider>(context);
    final providerProvider = Provider.of<ProviderProvider>(context);

    final completedBookings = [...bookingProvider.completedBookings]
      ..sort((a, b) => _transactionDate(b).compareTo(_transactionDate(a)));
    final pendingBookings = bookingProvider.pendingBookings;
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final totalEarnings = _sumBookings(completedBookings);
    final monthEarnings = _sumBookings(
      completedBookings.where((booking) {
        final date = _transactionDate(booking);
        return date.year == now.year && date.month == now.month;
      }),
    );
    final weekEarnings = _sumBookings(
      completedBookings.where((booking) {
        final date = _transactionDate(booking);
        return !date.isBefore(weekStart);
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: bookingProvider.isLoading && bookingProvider.bookings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerProvider.currentProvider?.displayName ?? 'Provider Earnings',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Total Earnings',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(totalEarnings),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _EarningsStat(
                                label: 'This Month',
                                value: _formatCurrency(monthEarnings),
                              ),
                            ),
                            Expanded(
                              child: _EarningsStat(
                                label: 'This Week',
                                value: _formatCurrency(weekEarnings),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Completed Jobs',
                          value: '${completedBookings.length}',
                          icon: Icons.check_circle,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Pending',
                          value: '${pendingBookings.length}',
                          icon: Icons.pending,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Average Job',
                          value: completedBookings.isEmpty
                              ? _formatCurrency(0)
                              : _formatCurrency(totalEarnings / completedBookings.length),
                          icon: Icons.insights,
                          color: AppTheme.infoColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'In Progress',
                          value: '${bookingProvider.activeBookings.length}',
                          icon: Icons.work,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (completedBookings.isEmpty)
                    _buildEmptyTransactions()
                  else
                    ...completedBookings.take(10).map(
                      (booking) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          title: Text(booking.customer?.name ?? 'Customer'),
                          subtitle: Text(
                            '${booking.description}\n${DateFormat('MMM dd, yyyy').format(_transactionDate(booking))}',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(booking.price.grandTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.statusDisplay,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete jobs to start earning.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  DateTime _transactionDate(Booking booking) {
    return booking.completedAt ??
        DateTime.tryParse(booking.scheduledDate) ??
        booking.updatedAt;
  }

  double _sumBookings(Iterable<Booking> bookings) {
    return bookings.fold<double>(0, (sum, booking) => sum + booking.price.grandTotal);
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
  }
}

class _EarningsStat extends StatelessWidget {
  final String label;
  final String value;

  const _EarningsStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
