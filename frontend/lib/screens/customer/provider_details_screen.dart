import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/provider_provider.dart';
import '../../providers/review_provider.dart';
import '../../utils/theme.dart';
import 'book_service_screen.dart';
import '../../services/event_service.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final String providerId;

  const ProviderDetailsScreen({super.key, required this.providerId});

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProvider();
    });
  }

  Future<void> _loadProvider() async {
    final providerProvider =
        Provider.of<ProviderProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    await Future.wait([
      providerProvider.getProviderById(widget.providerId),
      reviewProvider.loadReviews(providerId: widget.providerId, refresh: true),
      reviewProvider.getRatingSummary(widget.providerId),
      EventService.logProfileView(widget.providerId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final providerProvider = Provider.of<ProviderProvider>(context);
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final provider = providerProvider.currentProvider;
    final summary = reviewProvider.ratingSummary;

    return Scaffold(
      body: providerProvider.isLoading && provider == null
          ? const Center(child: CircularProgressIndicator())
          : provider == null
              ? const Center(child: Text('Provider not found'))
              : RefreshIndicator(
                  onRefresh: _loadProvider,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 220,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            child: Center(
                              child: CircleAvatar(
                                radius: 64,
                                backgroundImage:
                                    provider.profileImage.isNotEmpty
                                        ? NetworkImage(provider.profileImage)
                                        : null,
                                child: provider.profileImage.isEmpty
                                    ? const Icon(Icons.person, size: 64)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      provider.displayName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (provider.isVerified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            size: 16,
                                            color: AppTheme.primaryColor,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Verified',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.category?.name ?? 'Service Provider',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  _StatCard(
                                    icon: Icons.star,
                                    value: summary != null
                                        ? summary.averageRating
                                            .toStringAsFixed(1)
                                        : provider.rating.toStringAsFixed(1),
                                    label: 'Rating',
                                    color: AppTheme.accentColor,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatCard(
                                    icon: Icons.reviews,
                                    value:
                                        '${summary?.totalReviews ?? provider.totalReviews}',
                                    label: 'Reviews',
                                    color: AppTheme.infoColor,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatCard(
                                    icon: Icons.work,
                                    value: '${provider.totalBookings}',
                                    label: 'Jobs',
                                    color: AppTheme.secondaryColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.attach_money,
                                      color: AppTheme.primaryColor),
                                  title: Text(
                                      '\$${provider.hourlyRate.toStringAsFixed(2)} / hour'),
                                  subtitle: Text(
                                      '${provider.experience} years experience'),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const _SectionTitle('About'),
                              Text(
                                provider.description.isNotEmpty
                                    ? provider.description
                                    : 'No description available.',
                                style: const TextStyle(height: 1.5),
                              ),
                              const SizedBox(height: 24),
                              const _SectionTitle('Skills'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: provider.skills
                                    .map(
                                      (skill) => Chip(
                                        label: Text(skill),
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        labelStyle: const TextStyle(
                                            color: AppTheme.primaryColor),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 24),
                              const _SectionTitle('Availability'),
                              Card(
                                child: Column(
                                  children:
                                      _availabilityRows(provider.availability),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  const Expanded(
                                    child: _SectionTitle('Reviews'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _showAllReviews(reviewProvider),
                                    child: const Text('See All'),
                                  ),
                                ],
                              ),
                              if (reviewProvider.isLoading &&
                                  reviewProvider.reviews.isEmpty)
                                const Center(
                                    child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ))
                              else if (reviewProvider.reviews.isEmpty)
                                const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No reviews yet.'),
                                  ),
                                )
                              else
                                ...reviewProvider.reviews.take(3).map(
                                      (review) => Card(
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: AppTheme
                                                .primaryColor
                                                .withOpacity(0.1),
                                            child: Text(
                                              (review.customer?.name
                                                          .isNotEmpty ??
                                                      false)
                                                  ? review.customer!.name[0]
                                                      .toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                  color: AppTheme.primaryColor),
                                            ),
                                          ),
                                          title: Text(review.customer?.name ??
                                              'Customer'),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (index) => Icon(
                                                    index < review.rating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    size: 16,
                                                    color: AppTheme.accentColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                               Text(review.comment.isNotEmpty
                                                   ? review.comment
                                                   : 'No comment'),
                                               if (review.images.isNotEmpty) ...[
                                                 const SizedBox(height: 12),
                                                 SizedBox(
                                                   height: 60,
                                                   child: ListView.builder(
                                                     scrollDirection: Axis.horizontal,
                                                     itemCount: review.images.length,
                                                     itemBuilder: (context, i) => Padding(
                                                       padding: const EdgeInsets.only(right: 8),
                                                       child: ClipRRect(
                                                         borderRadius: BorderRadius.circular(4),
                                                         child: Image.network(
                                                           review.images[i],
                                                           width: 60,
                                                           height: 60,
                                                           fit: BoxFit.cover,
                                                         ),
                                                       ),
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                               if (review.providerResponse.isNotEmpty) ...[
                                                 const SizedBox(height: 12),
                                                 Container(
                                                   padding: const EdgeInsets.all(10),
                                                   decoration: BoxDecoration(
                                                     color: AppTheme.primaryColor.withOpacity(0.05),
                                                     borderRadius: BorderRadius.circular(8),
                                                     border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                                                   ),
                                                   child: Column(
                                                     crossAxisAlignment: CrossAxisAlignment.start,
                                                     children: [
                                                       const Text(
                                                         'Provider Response',
                                                         style: TextStyle(
                                                           fontSize: 11,
                                                           fontWeight: FontWeight.bold,
                                                           color: AppTheme.primaryColor,
                                                         ),
                                                       ),
                                                       const SizedBox(height: 4),
                                                       Text(
                                                         review.providerResponse,
                                                         style: const TextStyle(fontSize: 13),
                                                       ),
                                                     ],
                                                   ),
                                                 ),
                                               ],
                                               const SizedBox(height: 8),
                                               Text(
                                                 review.timeAgo,
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
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: provider == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Verification guard banner ──────────────────────────────
                if (!provider.isVerified)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: Colors.amber.shade100,
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This provider is pending verification. Booking is currently unavailable.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: authProvider.isCustomer && provider.isVerified
                          ? () async {
                              final created = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookServiceScreen(provider: provider),
                                ),
                              );
                              if (created == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Booking request sent successfully.'),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        !provider.isVerified
                            ? 'Provider Not Verified'
                            : authProvider.isCustomer
                                ? 'Book Now'
                                : 'Only customers can book services',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _availabilityRows(dynamic availability) {
    final days = [
      ('Monday', availability.monday),
      ('Tuesday', availability.tuesday),
      ('Wednesday', availability.wednesday),
      ('Thursday', availability.thursday),
      ('Friday', availability.friday),
      ('Saturday', availability.saturday),
      ('Sunday', availability.sunday),
    ];

    return days
        .map(
          (day) => ListTile(
            title: Text(day.$1),
            trailing: Text(
              day.$2.available
                  ? '${day.$2.startTime} - ${day.$2.endTime}'
                  : 'Unavailable',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: day.$2.available
                    ? AppTheme.secondaryColor
                    : AppTheme.errorColor,
              ),
            ),
          ),
        )
        .toList();
  }

  void _showAllReviews(ReviewProvider reviewProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'All Reviews',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: reviewProvider.reviews.isEmpty
                    ? const Center(child: Text('No reviews found.'))
                    : ListView.builder(
                        itemCount: reviewProvider.reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviewProvider.reviews[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          review.customer?.name ?? 'Customer',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          review.timeAgo,
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (index) => Icon(
                                          index < review.rating ? Icons.star : Icons.star_border,
                                          size: 16,
                                          color: AppTheme.accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(review.comment),
                                    if (review.images.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 80,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: review.images.length,
                                          itemBuilder: (context, i) => Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                review.images[i],
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (review.providerResponse.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Provider Response',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(review.providerResponse),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
