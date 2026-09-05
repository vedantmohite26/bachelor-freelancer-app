import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/ratings/widgets/rating_summary_card.dart';

class FakeRatingService implements RatingService {
  int getRatingDistributionCallCount = 0;
  final Map<int, int> mockDistribution;

  FakeRatingService({Map<int, int>? mockDistribution})
      : mockDistribution = mockDistribution ?? {5: 4, 4: 1, 3: 0, 2: 0, 1: 0};

  @override
  Future<Map<int, int>> getRatingDistribution(String helperId) async {
    getRatingDistributionCallCount++;
    return mockDistribution;
  }

  @override
  Future<void> submitRating({
    required String helperId,
    required String seekerId,
    required String jobId,
    required int overallRating,
    required double communication,
    required double punctuality,
    required double quality,
    String? feedback,
    List<String>? tags,
    String? photoUrl,
  }) async {}

  @override
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    return const Stream.empty();
  }

  @override
  Future<bool> hasUserRatedJob(String seekerId, String jobId) async {
    return false;
  }
}

void main() {
  testWidgets('RatingSummaryCard displays distribution and caches Future across rebuilds', (tester) async {
    final fakeRatingService = FakeRatingService();

    late StateSetter setParentState;

    await tester.pumpWidget(
      Provider<RatingService>.value(
        value: fakeRatingService,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                Responsive.init(context);
                return StatefulBuilder(
                  builder: (context, setState) {
                    setParentState = setState;
                    return const RatingSummaryCard(
                      helperId: 'helper_123',
                      averageRating: 4.8,
                      reviewCount: 5,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump(); // Allow Future to resolve

    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('5 Reviews'), findsOneWidget);
    expect(fakeRatingService.getRatingDistributionCallCount, equals(1));

    // Rebuild parent widget to verify Future is cached and not re-instantiated
    setParentState(() {});
    await tester.pump();

    expect(fakeRatingService.getRatingDistributionCallCount, equals(1));
  });
}
