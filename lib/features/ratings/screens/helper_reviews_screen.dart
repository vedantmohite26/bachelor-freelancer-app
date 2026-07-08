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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ratingService.getHelperRatings(helperId),
        builder: (context, snapshot) {
          final reviews = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;

          return CustomScrollView(
            slivers: [
              // 1. Summary Section (Always visible)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    RatingSummaryCard(
                      helperId: helperId,
                      averageRating: averageRating,
                      reviewCount: reviewCount,
                    ),
                    Divider(height: 1.h),
                  ],
                ),
              ),

              // 2. Reviews List or Status Placeholders
              if (isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const Text('Error loading reviews'),
                    ),
                  ),
                )
              else if (reviews.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const Text('No reviews found'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.all(16.w),
                  sliver: SliverList.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      return ReviewCard(review: reviews[index]);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
