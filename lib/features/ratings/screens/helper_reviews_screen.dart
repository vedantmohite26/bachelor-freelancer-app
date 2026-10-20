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
  Stream<List<Map<String, dynamic>>>? _reviewsStream;
  bool _isStreamInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isStreamInitialized) {
      final ratingService = Provider.of<RatingService>(context, listen: false);
      _reviewsStream = ratingService.getHelperRatings(widget.helperId);
      _isStreamInitialized = true;
    }
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
      body: CustomScrollView(
        slivers: [
          // Summary Section Header
          SliverToBoxAdapter(
            child: Column(
              children: [
                RatingSummaryCard(
                  helperId: widget.helperId,
                  averageRating: widget.averageRating,
                  reviewCount: widget.reviewCount,
                ),
                Divider(height: 1.h),
              ],
            ),
          ),
          // Reviews List / States Stream
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _reviewsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
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
                return SliverToBoxAdapter(
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
                    return RepaintBoundary(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: index == reviews.length - 1 ? 0 : 12.h),
                        child: ReviewCard(review: reviews[index]),
                      ),
                    );
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
