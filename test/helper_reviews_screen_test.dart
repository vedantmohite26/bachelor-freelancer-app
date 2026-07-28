import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/ratings/screens/helper_reviews_screen.dart';
import 'package:freelancer/features/ratings/widgets/review_card.dart';
import 'package:provider/provider.dart';

// Plain Dart Fake Implementation for RatingService to avoid Mockito dependencies
class FakeRatingService implements RatingService {
  final Stream<List<Map<String, dynamic>>> reviewsStream;
  final Map<int, int> distribution;

  FakeRatingService({
    required this.reviewsStream,
    required this.distribution,
  });

  @override
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    return reviewsStream;
  }

  @override
  Future<Map<int, int>> getRatingDistribution(String helperId) async {
    return distribution;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Plain Dart Fake Implementation for UserService to avoid Mockito dependencies
class FakeUserService implements UserService {
  final Map<String, Map<String, dynamic>> profiles;

  FakeUserService({required this.profiles});

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return profiles[userId];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeUserService fakeUserService;

  setUp(() {
    fakeUserService = FakeUserService(
      profiles: {
        'seeker1': {
          'name': 'Alice Johnson',
          'photoUrl': null, // Set to null to prevent network image HTTP requests in tests
        },
        'seeker2': {
          'name': 'Bob Smith',
          'photoUrl': null,
        },
      },
    );
  });

  Widget buildTestWidget({
    required RatingService ratingService,
    required UserService userService,
  }) {
    return MultiProvider(
      providers: [
        Provider<RatingService>.value(value: ratingService),
        Provider<UserService>.value(value: userService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Initialize Responsive utility context
              Responsive.init(context);
              return const HelperReviewsScreen(
                helperId: 'helper123',
                averageRating: 4.5,
                reviewCount: 2,
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('HelperReviewsScreen shows loading spinner when waiting for reviews', (WidgetTester tester) async {
    final streamController = StreamController<List<Map<String, dynamic>>>();
    final fakeRatingService = FakeRatingService(
      reviewsStream: streamController.stream,
      distribution: {5: 1, 4: 1, 3: 0, 2: 0, 1: 0},
    );

    await tester.pumpWidget(
      buildTestWidget(
        ratingService: fakeRatingService,
        userService: fakeUserService,
      ),
    );

    // Verify loading indicator is displayed (without pumpAndSettle since loading is active)
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2)); // One in summary card, one in list remaining

    // Clean up
    await streamController.close();
  });

  testWidgets('HelperReviewsScreen shows error text when stream fails', (WidgetTester tester) async {
    final streamController = StreamController<List<Map<String, dynamic>>>();
    final fakeRatingService = FakeRatingService(
      reviewsStream: streamController.stream,
      distribution: {5: 1, 4: 1, 3: 0, 2: 0, 1: 0},
    );

    await tester.pumpWidget(
      buildTestWidget(
        ratingService: fakeRatingService,
        userService: fakeUserService,
      ),
    );

    // Emit error
    streamController.addError('Something went wrong');
    // Pump frames to let stream error propagate
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify error text is displayed
    expect(find.text('Error loading reviews'), findsOneWidget);

    // Clean up
    await streamController.close();
  });

  testWidgets('HelperReviewsScreen shows empty text when no reviews are found', (WidgetTester tester) async {
    final fakeRatingService = FakeRatingService(
      reviewsStream: Stream.value([]),
      distribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
    );

    await tester.pumpWidget(
      buildTestWidget(
        ratingService: fakeRatingService,
        userService: fakeUserService,
      ),
    );

    // Pump frames to let Stream.value and Future resolve
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No reviews found'), findsOneWidget);
  });

  testWidgets('HelperReviewsScreen renders virtualized list when reviews are available', (WidgetTester tester) async {
    final reviews = [
      {
        'id': 'r1',
        'seekerId': 'seeker1',
        'overallRating': 5,
        'feedback': 'Excellent work! Highly recommended.',
        'tags': ['Fast', 'Professional'],
        'createdAt': null,
      },
      {
        'id': 'r2',
        'seekerId': 'seeker2',
        'overallRating': 4,
        'feedback': 'Great communication.',
        'tags': ['Polite'],
        'createdAt': null,
      }
    ];

    final fakeRatingService = FakeRatingService(
      reviewsStream: Stream.value(reviews),
      distribution: {5: 1, 4: 1, 3: 0, 2: 0, 1: 0},
    );

    await tester.pumpWidget(
      buildTestWidget(
        ratingService: fakeRatingService,
        userService: fakeUserService,
      ),
    );

    // Pump multiple times to resolve streams, FutureBuilders, and any layout passes
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Verify rating summary elements are present
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('2 Reviews'), findsOneWidget);

    // Verify the virtualized list renders the reviews
    expect(find.byType(ReviewCard), findsNWidgets(2));
    expect(find.text('Excellent work! Highly recommended.'), findsOneWidget);
    expect(find.text('Great communication.'), findsOneWidget);

    // Verify tags
    expect(find.text('Fast'), findsOneWidget);
    expect(find.text('Professional'), findsOneWidget);
    expect(find.text('Polite'), findsOneWidget);
  });
}
