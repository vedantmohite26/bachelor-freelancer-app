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

    // PERFORMANCE OPTIMIZATION:
    // Replaced SingleChildScrollView + Column + ListView(shrinkWrap: true)
    // with CustomScrollView + SliverList. This enables list virtualization,
    // ensuring only visible items are rendered.
    // Impact: Reduces memory usage and UI thread jank from O(n) to O(visible).
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Reviews'),
        centerTitle: true,
        elevation: 0,
      ),
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
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const Text('Error loading reviews'),
                    ),
                  ),
                );
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const Text('No reviews found'),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverList.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return ReviewCard(review: reviews[index]);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
