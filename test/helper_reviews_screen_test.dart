import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/features/ratings/screens/helper_reviews_screen.dart';

// Suppress subtype of sealed class and noSuchMethod warnings
// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

class FakeRatingService implements RatingService {
  final _controller = StreamController<List<Map<String, dynamic>>>.broadcast();

  void emitReviews(List<Map<String, dynamic>> reviews) {
    _controller.add(reviews);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  @override
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    return _controller.stream;
  }

  @override
  Future<Map<int, int>> getRatingDistribution(String helperId) async {
    return {5: 10, 4: 2, 3: 1, 2: 0, 1: 0};
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserService implements UserService {
  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return {
      'id': userId,
      'name': 'User $userId',
      'photoUrl': null,
    };
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
        home: Scaffold(
          body: Builder(
            builder: (context) {
              Responsive.init(context);
              return child;
            },
          ),
        ),
      ),
    );
  }

  testWidgets('HelperReviewsScreen shows loading state initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper_123',
          averageRating: 4.8,
          reviewCount: 13,
        ),
      ),
    );

    // One CPI from RatingSummaryCard (FutureBuilder), one from helper reviews list (StreamBuilder waiting)
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
  });

  testWidgets('HelperReviewsScreen shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper_123',
          averageRating: 4.8,
          reviewCount: 13,
        ),
      ),
    );

    fakeRatingService.emitReviews([]);
    await tester.pump();

    expect(find.text('No reviews found'), findsOneWidget);
  });

  testWidgets('HelperReviewsScreen shows error state', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper_123',
          averageRating: 4.8,
          reviewCount: 13,
        ),
      ),
    );

    fakeRatingService.emitError('Database error');
    await tester.pump();

    expect(find.text('Error loading reviews'), findsOneWidget);
  });

  testWidgets('HelperReviewsScreen renders virtualized list of reviews', (WidgetTester tester) async {
    final mockReviews = [
      {
        'id': 'r1',
        'seekerId': 's1',
        'overallRating': 5.0,
        'feedback': 'Great service, very punctual!',
        'tags': ['Punctual', 'Polite'],
        'createdAt': null,
      },
      {
        'id': 'r2',
        'seekerId': 's2',
        'overallRating': 4.0,
        'feedback': 'Excellent work done.',
        'tags': ['Quality'],
        'createdAt': null,
      }
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper_123',
          averageRating: 4.8,
          reviewCount: 13,
        ),
      ),
    );

    fakeRatingService.emitReviews(mockReviews);
    await tester.pumpAndSettle();

    // Verify rating summary card fields are shown
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('13 Reviews'), findsOneWidget);

    // Verify mock review items are displayed
    expect(find.text('Great service, very punctual!'), findsOneWidget);
    expect(find.text('Excellent work done.'), findsOneWidget);
  });
}
