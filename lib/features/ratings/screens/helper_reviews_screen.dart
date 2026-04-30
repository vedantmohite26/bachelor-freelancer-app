import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/features/ratings/widgets/review_card.dart';
import 'package:freelancer/features/ratings/widgets/rating_summary_card.dart';

class HelperReviewsScreen extends StatefulWidget {
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
  State<HelperReviewsScreen> createState() => _HelperReviewsScreenState();
}

class _HelperReviewsScreenState extends State<HelperReviewsScreen> {
  late Stream<List<Map<String, dynamic>>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _loadReviewsStream();
  }

  @override
  void didUpdateWidget(HelperReviewsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.helperId != widget.helperId) {
      _loadReviewsStream();
    }
  }

  void _loadReviewsStream() {
    // OPTIMIZATION: Cache the stream to prevent redundant subscriptions
    // and Firestore listener setup on every widget rebuild.
    _reviewsStream = Provider.of<RatingService>(
      context,
      listen: false,
    ).getHelperRatings(widget.helperId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Reviews'),
        centerTitle: true,
        elevation: 0,
      ),
      // OPTIMIZATION: Using CustomScrollView with SliverList instead of
      // SingleChildScrollView + ListView.builder(shrinkWrap: true).
      // This enables virtualization (O(visible) vs O(N)) and avoids
      // building the entire list upfront.
      body: CustomScrollView(
        slivers: [
          // Summary Section
          SliverToBoxAdapter(
            child: RatingSummaryCard(
              helperId: widget.helperId,
              averageRating: widget.averageRating,
              reviewCount: widget.reviewCount,
            ),
          ),
          SliverToBoxAdapter(child: Divider(height: 1.h)),

          // Reviews List
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _reviewsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Error loading reviews')),
                );
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
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
