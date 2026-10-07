import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/ratings/screens/helper_reviews_screen.dart';

class FakeRatingService extends Fake implements RatingService {
  int getRatingsCallCount = 0;
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  @override
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    getRatingsCallCount++;
    return _controller.stream;
  }

  void emitReviews(List<Map<String, dynamic>> reviews) {
    _controller.add(reviews);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  @override
  Future<Map<int, int>> getRatingDistribution(String helperId) async {
    return {5: 10, 4: 5, 3: 1, 2: 0, 1: 0};
  }
}

class FakeUserService extends Fake implements UserService {
  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return {
      'uid': userId,
      'name': 'Reviewer User',
      'photoUrl': null,
    };
  }
}

void main() {
  late FakeRatingService fakeRatingService;
  late FakeUserService fakeUserService;

  setUp(() {
    fakeRatingService = FakeRatingService();
    fakeUserService = FakeUserService();
  });

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<RatingService>.value(value: fakeRatingService),
        Provider<UserService>.value(value: fakeUserService),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return child;
          },
        ),
      ),
    );
  }

  testWidgets('HelperReviewsScreen renders loading indicator initially and caches stream on rebuild', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper123',
          averageRating: 4.8,
          reviewCount: 16,
        ),
      ),
    );

    // Verify stream was subscribed once
    expect(fakeRatingService.getRatingsCallCount, equals(1));
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    // Emit empty reviews list
    fakeRatingService.emitReviews([]);
    await tester.pump();

    expect(find.text('No reviews found'), findsOneWidget);

    // Trigger parent rebuild
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper123',
          averageRating: 4.8,
          reviewCount: 16,
        ),
      ),
    );

    // Verify stream was NOT re-queried on rebuild
    expect(fakeRatingService.getRatingsCallCount, equals(1));
    expect(find.text('No reviews found'), findsOneWidget);
  });

  testWidgets('HelperReviewsScreen displays review cards when stream emits data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper123',
          averageRating: 4.8,
          reviewCount: 16,
        ),
      ),
    );

    fakeRatingService.emitReviews([
      {
        'id': 'rev1',
        'seekerId': 'seeker1',
        'overallRating': 5,
        'feedback': 'Excellent work! Highly recommended.',
        'createdAt': '2026-03-01T10:00:00Z',
      },
    ]);
    await tester.pump();

    expect(find.text('Excellent work! Highly recommended.'), findsOneWidget);
  });

  testWidgets('HelperReviewsScreen displays error message when stream emits error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper123',
          averageRating: 4.8,
          reviewCount: 16,
        ),
      ),
    );

    fakeRatingService.emitError('Firestore connection error');
    await tester.pump();

    expect(find.text('Error loading reviews'), findsOneWidget);
  });
}
