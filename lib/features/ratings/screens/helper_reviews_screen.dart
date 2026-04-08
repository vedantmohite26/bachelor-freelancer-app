import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/features/ratings/widgets/review_card.dart';
import 'package:freelancer/features/ratings/widgets/rating_summary_card.dart';

class HelperReviewsScreen extends StatelessWidget {
  final String helperId;
  final double averageRating;
  final int reviewCount;

  const HelperReviewsScreen({
    super.key,
    required this.helperId,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final ratingService = Provider.of<RatingService>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Reviews'),
        centerTitle: true,
        elevation: 0,
      ),
      // PERFORMANCE OPTIMIZATION: Using CustomScrollView with SliverList instead of
      // SingleChildScrollView + ListView(shrinkWrap: true).
      // This enables UI virtualization (lazy loading), which:
      // 1. Reduces initial build time from O(N) to O(visible).
      // 2. Reduces memory footprint for long review lists.
      // 3. Defers execution of FutureBuilders in ReviewCard until they are on screen.
      body: CustomScrollView(
        slivers: [
          // Summary Section
          SliverToBoxAdapter(
            child: RatingSummaryCard(
              helperId: helperId,
              averageRating: averageRating,
              reviewCount: reviewCount,
            ),
          ),
          SliverToBoxAdapter(child: Divider(height: 1.h)),

          // Reviews List
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: ratingService.getHelperRatings(helperId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Error loading reviews')),
                );
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No reviews found')),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ReviewCard(review: reviews[index]);
                    },
                    childCount: reviews.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
