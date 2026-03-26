import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

import '../../providers/booking_provider.dart';
import '../../providers/review_provider.dart';
import '../../utils/theme.dart';
import '../chat_screen.dart';
import 'provider_details_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooking();
    });
  }

  Future<void> _loadBooking() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    await bookingProvider.getBookingById(widget.bookingId);
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final success = await bookingProvider.cancelBooking(widget.bookingId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Booking cancelled successfully.'
              : (bookingProvider.error ?? 'Failed to cancel booking.'),
        ),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  Future<void> _showReviewDialog(String providerId) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _ReviewDialog(providerId: providerId),
    );

    if (result != null && mounted) {
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      final success = await reviewProvider.createReview(
        bookingId: widget.bookingId,
        providerId: providerId,
        rating: result['rating'],
        comment: result['comment'],
        images: result['images'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Review submitted successfully.'
                : (reviewProvider.error ?? 'Failed to submit review.'),
          ),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading && bookingProvider.currentBooking == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final booking = bookingProvider.currentBooking;
          if (booking == null) {
            return const Center(child: Text('Booking not found'));
          }

          return RefreshIndicator(
            onRefresh: _loadBooking,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: booking.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getStatusIcon(booking.status),
                        size: 48,
                        color: booking.statusColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        booking.statusDisplay,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: booking.statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusMessage(booking.status),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: booking.statusColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Service Provider'),
                Card(
                  child: ListTile(
                    onTap: booking.provider != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProviderDetailsScreen(
                                  providerId: booking.provider!.id,
                                ),
                              ),
                            );
                          }
                        : null,
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: booking.provider != null &&
                              booking.provider!.profileImage.isNotEmpty
                          ? NetworkImage(booking.provider!.profileImage)
                          : null,
                      child: booking.provider == null ||
                              booking.provider!.profileImage.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(booking.provider?.displayName ?? 'Unknown Provider'),
                    subtitle: Text(
                      booking.provider?.category?.name ?? 'Service Provider',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (booking.provider != null)
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    bookingId: booking.id,
                                    otherUserName: booking.provider!.displayName,
                                  ),
                                ),
                              );
                            },
                          ),
                        booking.provider?.isVerified == true
                            ? const Icon(Icons.verified, color: AppTheme.primaryColor)
                            : const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Service Details'),
                Card(
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.description,
                        title: 'Description',
                        subtitle: booking.description,
                      ),
                      _InfoTile(
                        icon: Icons.schedule,
                        title: 'Scheduled',
                        subtitle: '${booking.scheduledDate} at ${booking.scheduledTime}',
                      ),
                      _InfoTile(
                        icon: Icons.timer,
                        title: 'Estimated Duration',
                        subtitle: '${booking.estimatedDuration} hour(s)',
                      ),
                      _InfoTile(
                        icon: Icons.location_on,
                        title: 'Service Address',
                        subtitle: booking.serviceLocation.fullAddress,
                      ),
                      if (booking.notes.isNotEmpty)
                        _InfoTile(
                          icon: Icons.notes,
                          title: 'Notes',
                          subtitle: booking.notes,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Pricing'),
                Card(
                  child: Column(
                    children: [
                      _PriceRow(label: 'Hourly Rate', value: booking.price.hourlyRate),
                      _PriceRow(
                        label: 'Estimated Hours',
                        value: booking.price.estimatedHours.toDouble(),
                        prefix: '',
                        suffix: ' hrs',
                      ),
                      _PriceRow(label: 'Labor Total', value: booking.price.totalAmount),
                      if (booking.price.materialsCost > 0)
                        _PriceRow(label: 'Materials', value: booking.price.materialsCost),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${booking.price.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (booking.isPending || booking.isAccepted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cancelBooking,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (booking.isCompleted && booking.provider != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(booking.provider!.id),
                      icon: const Icon(Icons.star),
                      label: const Text('Leave a Review'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'in-progress':
        return Icons.work;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting for provider to accept your request.';
      case 'accepted':
        return 'The provider accepted this booking.';
      case 'in-progress':
        return 'The service is currently in progress.';
      case 'completed':
        return 'The service has been completed successfully.';
      case 'cancelled':
        return 'This booking has been cancelled.';
      default:
        return '';
    }
  }
}

class _ReviewDialog extends StatefulWidget {
  final String providerId;
  const _ReviewDialog({super.key, required this.providerId});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  double _rating = 5;
  final _commentController = TextEditingController();
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Your Experience'),
      content: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Custom Star Rating to replace RatingBar for stability
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1.0),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: AppTheme.accentColor,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Comment (optional)',
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add Photos (Max 5)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...List.generate(_selectedImages.length, (index) {
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                            image: DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(_selectedImages[index].path)
                                  : FileImage(io.File(_selectedImages[index].path)) as ImageProvider,
                              fit: BoxFit.cover,
                              onError: (e, s) => debugPrint('Image error: $e'),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImages.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_selectedImages.length < 5)
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final images = await picker.pickMultiImage(
                          imageQuality: 70,
                          maxWidth: 800,
                        );
                        if (images.isNotEmpty) {
                          setState(() {
                            _selectedImages.addAll(images);
                            if (_selectedImages.length > 5) {
                              _selectedImages = _selectedImages.sublist(0, 5);
                            }
                          });
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                        ),
                        child: const Icon(Icons.add_a_photo, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  Navigator.pop(context, {
                    'rating': _rating.round(),
                    'comment': _commentController.text.trim(),
                    'images': _selectedImages,
                  });
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final String prefix;
  final String suffix;

  const _PriceRow({
    required this.label,
    required this.value,
    this.prefix = '\$',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final formattedValue = prefix.isEmpty
        ? '${value.toStringAsFixed(0)}$suffix'
        : '$prefix${value.toStringAsFixed(2)}$suffix';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(formattedValue),
        ],
      ),
    );
  }
}
