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
          // PERFORMANCE: Using CustomScrollView with Slivers instead of SingleChildScrollView + ListView(shrinkWrap: true)
          // This enables virtualization (only rendering visible items), reducing initial build time from O(N) to O(visible).
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

              // Status states (loading, error, empty)
              if (snapshot.connectionState == ConnectionState.waiting)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const Text('Error loading reviews'),
                    ),
                  ),
                )
              else if (snapshot.data == null || snapshot.data!.isEmpty)
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
                // Virtualized Reviews List
                SliverPadding(
                  padding: EdgeInsets.all(16.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ReviewCard(review: snapshot.data![index]);
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
