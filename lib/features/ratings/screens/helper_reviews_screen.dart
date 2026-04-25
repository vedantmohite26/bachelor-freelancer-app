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
      // ⚡ Bolt Optimization: Switched to CustomScrollView with SliverList.
      // This enables list virtualization, ensuring only visible reviews are rendered.
      // Expected impact: Reduces initial build time from O(N) to O(visible items)
      // and improves scroll smoothness for long review lists.
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ratingService.getHelperRatings(helperId),
        builder: (context, snapshot) {
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
              SliverToBoxAdapter(child: Divider(height: 1.h)),

              // Reviews List (Virtualized)
              ..._buildSliverContent(context, snapshot),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSliverContent(
    BuildContext context,
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      ];
    }

    if (snapshot.hasError) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: const Text('Error loading reviews'),
            ),
          ),
        ),
      ];
    }

    final reviews = snapshot.data ?? [];

    if (reviews.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: const Text('No reviews found'),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.all(16.w),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return ReviewCard(review: reviews[index]);
            },
            childCount: reviews.length,
          ),
        ),
      ),
    ];
  }
}
