import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/features/ratings/screens/helper_reviews_screen.dart';

// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

class FakeRatingService extends Fake implements RatingService {
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  List<Map<String, dynamic>>? nextData;
  Object? nextError;

  void emitData(List<Map<String, dynamic>> data) {
    _controller.add(data);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  @override
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    if (nextError != null) {
      return Stream.error(nextError!);
    }
    if (nextData != null) {
      return Stream.value(nextData!);
    }
    return _controller.stream;
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
      'name': 'Test User $userId',
      'profilePictureUrl': null,
    };
  }
}

void main() {
  testWidgets('HelperReviewsScreen shows loading, empty, and review list states',
      (WidgetTester tester) async {
    final fakeRatingService = FakeRatingService();
    final fakeUserService = FakeUserService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<RatingService>.value(value: fakeRatingService),
          Provider<UserService>.value(value: fakeUserService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const HelperReviewsScreen(
                helperId: 'helper_123',
                averageRating: 4.8,
                reviewCount: 16,
              );
            },
          ),
        ),
      ),
    );

    // Initial state: loading indicator inside SliverFillRemaining (RatingSummaryCard also loads distribution)
    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

    // Emit empty list
    fakeRatingService.emitData([]);
    await tester.pump();
    expect(find.text('No reviews found'), findsOneWidget);

    // Emit review items with expected fields matching ReviewCard model
    fakeRatingService.emitData([
      {
        'id': 'rev_1',
        'seekerId': 'user_1',
        'overallRating': 5.0,
        'feedback': 'Awesome work!',
      },
      {
        'id': 'rev_2',
        'seekerId': 'user_2',
        'overallRating': 4.0,
        'feedback': 'Good job',
      },
    ]);
    await tester.pump();

    // Verify reviews are rendered in virtualized list
    expect(find.text('Awesome work!'), findsOneWidget);
    expect(find.text('Good job'), findsOneWidget);
  });
}
