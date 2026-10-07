import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/features/ratings/widgets/review_card.dart';
import 'package:freelancer/features/ratings/widgets/rating_summary_card.dart';

/// HelperReviewsScreen displays the rating summary and list of helper reviews.
///
/// Bolt Optimization: Converted to [StatefulWidget] to cache [_reviewsStream]
/// in [didChangeDependencies]. This prevents [StreamBuilder] from tearing down
/// and re-subscribing to the Firestore rating stream on every widget rebuild,
/// reducing unnecessary network requests, garbage collection, and UI flickers.
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
  String? _cachedHelperId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reviewsStream == null || _cachedHelperId != widget.helperId) {
      _cachedHelperId = widget.helperId;
      final ratingService = Provider.of<RatingService>(context, listen: false);
      _reviewsStream = ratingService.getHelperRatings(widget.helperId);
    }
  }

  @override
  void didUpdateWidget(covariant HelperReviewsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.helperId != widget.helperId) {
      _cachedHelperId = widget.helperId;
      final ratingService = Provider.of<RatingService>(context, listen: false);
      _reviewsStream = ratingService.getHelperRatings(widget.helperId);
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Summary Section
            RatingSummaryCard(
              helperId: widget.helperId,
              averageRating: widget.averageRating,
              reviewCount: widget.reviewCount,
            ),
            Divider(height: 1.h),
            // Reviews List
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _reviewsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const Text('Error loading reviews'),
                    ),
                  );
                }

                final reviews = snapshot.data ?? [];

                if (reviews.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const Text('No reviews found'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return RepaintBoundary(
                      child: ReviewCard(review: reviews[index]),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
