import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/features/ratings/screens/helper_reviews_screen.dart';
import 'package:freelancer/features/ratings/widgets/review_card.dart';
import 'package:freelancer/core/utils/responsive.dart';

class FakeRatingService extends Fake implements RatingService {
  final StreamController<List<Map<String, dynamic>>> _ratingsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  bool getHelperRatingsCalled = false;
  String? queriedHelperId;

  @override
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    getHelperRatingsCalled = true;
    queriedHelperId = helperId;
    return _ratingsController.stream;
  }

  @override
  Future<Map<int, int>> getRatingDistribution(String helperId) async {
    return {5: 10, 4: 5, 3: 2, 2: 1, 1: 0};
  }

  void emit(List<Map<String, dynamic>> ratings) {
    _ratingsController.add(ratings);
  }

  void emitError(Object error) {
    _ratingsController.addError(error);
  }

  void dispose() {
    _ratingsController.close();
  }
}

class FakeUserService extends Fake implements UserService {
  final Map<String, Map<String, dynamic>> _profiles = {};
  int getUserProfileCalls = 0;

  void addProfile(String userId, Map<String, dynamic> profile) {
    _profiles[userId] = profile;
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    getUserProfileCalls++;
    return _profiles[userId];
  }
}

void main() {
  late FakeRatingService fakeRatingService;
  late FakeUserService fakeUserService;

  setUp(() {
    fakeRatingService = FakeRatingService();
    fakeUserService = FakeUserService();
  });

  tearDown(() {
    fakeRatingService.dispose();
  });

  Widget createWidgetUnderTest() {
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
              return const HelperReviewsScreen(
                helperId: 'helper_1',
                averageRating: 4.5,
                reviewCount: 18,
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('HelperReviewsScreen displays loading indicator initially', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify loading indicators are displayed (one for screen body, one for summary card)
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(fakeRatingService.getHelperRatingsCalled, isTrue);
    expect(fakeRatingService.queriedHelperId, 'helper_1');
  });

  testWidgets('HelperReviewsScreen displays error message when stream fails', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Emit error
    fakeRatingService.emitError('Database error');
    await tester.pump();

    // Verify error text is shown
    expect(find.text('Error loading reviews'), findsOneWidget);
  });

  testWidgets('HelperReviewsScreen displays empty message when reviews list is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Emit empty list
    fakeRatingService.emit([]);
    await tester.pump();

    // Verify empty text is shown
    expect(find.text('No reviews found'), findsOneWidget);
  });

  testWidgets('HelperReviewsScreen renders summary card and virtualized reviews correctly', (WidgetTester tester) async {
    fakeUserService.addProfile('seeker_1', {
      'name': 'John Doe',
      'photoUrl': null,
    });

    await tester.pumpWidget(createWidgetUnderTest());

    // Emit reviews
    fakeRatingService.emit([
      {
        'id': 'review_1',
        'seekerId': 'seeker_1',
        'overallRating': 5,
        'feedback': 'Amazing service! Very professional.',
        'tags': ['Fast', 'Polite'],
        'createdAt': null,
      }
    ]);

    // Use repeated pump instead of pumpAndSettle to allow FutureBuilder in RatingSummaryCard to resolve
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify the summary is shown
    expect(find.text('18 Reviews'), findsOneWidget);

    // Verify the review is rendered
    expect(find.byType(ReviewCard), findsOneWidget);
    expect(find.text('Amazing service! Very professional.'), findsOneWidget);

    // Seeker's profile should have been loaded asynchronously
    expect(find.text('John Doe'), findsOneWidget);
  });
}
