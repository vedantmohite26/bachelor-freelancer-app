import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/features/ratings/screens/helper_reviews_screen.dart';
import 'package:freelancer/features/ratings/widgets/review_card.dart';

// Fake RatingService to control the stream and future values in tests
class FakeRatingService implements RatingService {
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Map<int, int> _distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  void emitReviews(List<Map<String, dynamic>> reviews) {
    _controller.add(reviews);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  void setDistribution(Map<int, int> distribution) {
    _distribution = distribution;
  }

  @override
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    return _controller.stream;
  }

  @override
  Future<Map<int, int>> getRatingDistribution(String helperId) async {
    return _distribution;
  }

  // Unused methods in these tests can throw UnimplementedError or be empty
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake UserService to mock user profile fetching
class FakeUserService implements UserService {
  final Map<String, Map<String, dynamic>> _profiles = {};

  void setProfile(String userId, Map<String, dynamic> profile) {
    _profiles[userId] = profile;
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  testWidgets('HelperReviewsScreen shows loading indicator while waiting for reviews', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper_1',
          averageRating: 4.5,
          reviewCount: 3,
        ),
      ),
    );

    // Initial state is waiting since no reviews are emitted yet.
    // There are 2 progress indicators: one in the FutureBuilder of RatingSummaryCard
    // and one in the main StreamBuilder list content area.
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(find.text('Reviews'), findsOneWidget);
  });

  testWidgets('HelperReviewsScreen shows error message on stream error', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper_1',
          averageRating: 4.5,
          reviewCount: 3,
        ),
      ),
    );

    // Emit error
    fakeRatingService.emitError('Database error');
    await tester.pump();

    expect(find.text('Error loading reviews'), findsOneWidget);
  });

  testWidgets('HelperReviewsScreen shows empty message when no reviews are found', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper_1',
          averageRating: 4.5,
          reviewCount: 3,
        ),
      ),
    );

    // Emit empty list
    fakeRatingService.emitReviews([]);
    await tester.pump();

    expect(find.text('No reviews found'), findsOneWidget);
  });

  testWidgets('HelperReviewsScreen renders summary card and reviews list successfully', (WidgetTester tester) async {
    fakeRatingService.setDistribution({5: 2, 4: 1, 3: 0, 2: 0, 1: 0});
    fakeUserService.setProfile('seeker_1', {'name': 'Alice Smith', 'photoUrl': null});
    fakeUserService.setProfile('seeker_2', {'name': 'Bob Jones', 'photoUrl': null});

    final reviews = [
      {
        'id': 'r1',
        'seekerId': 'seeker_1',
        'overallRating': 5,
        'feedback': 'Amazing service, very punctual!',
        'tags': ['Reliable', 'Friendly'],
        'createdAt': null, // results in DateTime.now()
      },
      {
        'id': 'r2',
        'seekerId': 'seeker_2',
        'overallRating': 4,
        'feedback': 'Good job overall.',
        'tags': ['Skilled'],
        'createdAt': null,
      }
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        const HelperReviewsScreen(
          helperId: 'helper_1',
          averageRating: 4.5,
          reviewCount: 2,
        ),
      ),
    );

    // Emit the reviews
    fakeRatingService.emitReviews(reviews);
    await tester.pump();
    await tester.pumpAndSettle(); // Settle future builder inside RatingSummaryCard and ReviewCard

    // Check header / summary card content
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('2 Reviews'), findsOneWidget);

    // Check individual review cards are rendered
    expect(find.byType(ReviewCard), findsNWidgets(2));
    expect(find.text('Amazing service, very punctual!'), findsOneWidget);
    expect(find.text('Good job overall.'), findsOneWidget);
    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Bob Jones'), findsOneWidget);
  });
}
