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
    _initStream();
  }

  @override
  void didUpdateWidget(HelperReviewsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only refresh the stream if the helperId has actually changed
    if (oldWidget.helperId != widget.helperId) {
      _initStream();
    }
  }

  void _initStream() {
    // BOLT: Cache the stream in the state to avoid redundant re-subscriptions on build
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _reviewsStream,
        builder: (context, snapshot) {
          // BOLT: Use CustomScrollView with slivers for virtualization.
          // This replaces the SingleChildScrollView + ListView(shrinkWrap: true) anti-pattern,
          // improving performance from O(N) to O(visible items) building.
          return CustomScrollView(
            slivers: [
              // 1. Summary Section (Fixed)
              SliverToBoxAdapter(
                child: RatingSummaryCard(
                  helperId: widget.helperId,
                  averageRating: widget.averageRating,
                  reviewCount: widget.reviewCount,
                ),
              ),
              SliverToBoxAdapter(child: Divider(height: 1.h)),

              // 2. Reviews List or Loading/Error/Empty States
              ..._buildMainContent(snapshot),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildMainContent(
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
            (context, index) => ReviewCard(review: reviews[index]),
            childCount: reviews.length,
          ),
        ),
      ),
    ];
  }
}
