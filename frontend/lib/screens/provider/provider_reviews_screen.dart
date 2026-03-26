import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/provider_provider.dart';
import '../../providers/review_provider.dart';
import '../../utils/theme.dart';

class ProviderReviewsScreen extends StatefulWidget {
  const ProviderReviewsScreen({super.key});

  @override
  State<ProviderReviewsScreen> createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends State<ProviderReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
  }

  Future<void> _loadReviews() async {
    final pp = Provider.of<ProviderProvider>(context, listen: false);
    final rp = Provider.of<ReviewProvider>(context, listen: false);
    if (pp.currentProvider != null) {
      await rp.loadReviews(providerId: pp.currentProvider!.id, refresh: true);
    }
  }

  void _showResponseDialog(String reviewId, String existingResponse) {
    final TextEditingController controller = TextEditingController(text: existingResponse);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Review'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Type your response here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final rp = Provider.of<ReviewProvider>(context, listen: false);
              final success = await rp.respondToReview(
                reviewId: reviewId,
                response: controller.text.trim(),
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Response saved!' : 'Failed to save response.'),
                    backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: AppTheme.navyDeep,
        elevation: 0,
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, reviewProvider, child) {
          if (reviewProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          final reviews = reviewProvider.reviews;

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: GoogleFonts.inter(fontSize: 18, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadReviews,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.navySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            review.customer?.name ?? 'Customer',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Text(
                            review.timeAgo,
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        review.comment,
                        style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      ),
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
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.dividerColor),
                      const SizedBox(height: 8),
                      if (review.providerResponse.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Your Response',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showResponseDialog(review.id, review.providerResponse),
                                    child: const Icon(Icons.edit_outlined, size: 14, color: AppTheme.primaryColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                review.providerResponse,
                                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        TextButton.icon(
                          onPressed: () => _showResponseDialog(review.id, ''),
                          icon: const Icon(Icons.reply_rounded, size: 18),
                          label: const Text('Respond to Review'),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
