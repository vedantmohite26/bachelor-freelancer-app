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
      // OPTIMIZATION: Refactored SingleChildScrollView + Column + ListView.builder(shrinkWrap: true)
      // to a CustomScrollView wrapping SliverToBoxAdapter, SliverFillRemaining, and SliverPadding with SliverList.
      // This enables full list virtualization and lazy item rendering, avoiding the O(n) rendering penalty
      // on long review lists, improving viewport performance and overall responsiveness.
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ratingService.getHelperRatings(helperId),
        builder: (context, snapshot) {
          Widget stateSliver;

          if (snapshot.connectionState == ConnectionState.waiting) {
            // Keep the exact padding (32.w) and center alignment using SliverFillRemaining
            stateSliver = SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: const CircularProgressIndicator(),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            // Error state keeping original 32.w padding and center alignment
            stateSliver = SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: const Text('Error loading reviews'),
                ),
              ),
            );
          } else {
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              // Empty state keeping original 32.w padding and center alignment
              stateSliver = SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: const Text('No reviews found'),
                  ),
                ),
              );
            } else {
              // Content loaded: Use SliverPadding with SliverList to virtualize items lazily
              stateSliver = SliverPadding(
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
            }
          }

          return CustomScrollView(
            slivers: [
              // Summary Section
              SliverToBoxAdapter(
                child: RatingSummaryCard(
                  helperId: helperId,
                  averageRating: averageRating,
                  reviewCount: reviewCount,
                ),
              ),
              SliverToBoxAdapter(
                child: Divider(height: 1.h),
              ),
              // Dynamic state sliver (Loading, Error, Empty, or virtualized reviews list)
              stateSliver,
            ],
          );
        },
      ),
    );
  }
}
