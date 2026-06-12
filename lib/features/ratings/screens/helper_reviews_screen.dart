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
  // BOLT OPTIMIZATION: Refactored from SingleChildScrollView + Column + ListView(shrinkWrap: true)
  // to CustomScrollView + SliverList.
  //
  // WHY: The previous implementation had O(N) rendering complexity where all ReviewCards
  // were built and laid out immediately, even those off-screen, due to 'shrinkWrap: true'
  // disabling ListView's virtualization.
  //
  // IMPACT: By using SliverList, we enable virtualization (O(visible) complexity).
  // Only the reviews currently visible in the viewport are built and rendered,
  // significantly reducing initial build time and memory usage for long review lists.
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
          return CustomScrollView(
            slivers: [
              // 1. Summary Section (Fixed at top)
              SliverToBoxAdapter(
                child: RatingSummaryCard(
                  helperId: helperId,
                  averageRating: averageRating,
                  reviewCount: reviewCount,
                ),
              ),
              SliverToBoxAdapter(child: Divider(height: 1.h)),

              // 2. Loading/Error/Data States
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
              else if ((snapshot.data ?? []).isEmpty)
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
