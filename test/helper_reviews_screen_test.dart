import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/ratings/screens/helper_reviews_screen.dart';
import 'package:provider/provider.dart';

class FakeAuthService extends Fake implements AuthService {
  @override
  User? get user => null;
}

class FakeUserService extends Fake implements UserService {
  @override
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    return {
      'uid': uid,
      'name': 'Reviewer User',
      'photoUrl': null,
    };
  }
}

class FakeRatingService extends Fake implements RatingService {
  final StreamController<List<Map<String, dynamic>>> _controller;
  int streamAccessCount = 0;

  FakeRatingService(this._controller);

  @override
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    streamAccessCount++;
    return _controller.stream;
  }

  @override
  Future<Map<int, int>> getRatingDistribution(String helperId) async {
    return {
      5: 1,
      4: 0,
      3: 0,
      2: 0,
      1: 0,
    };
  }
}

void main() {
  testWidgets('HelperReviewsScreen caches stream and renders virtualized reviews list', (WidgetTester tester) async {
    Provider.debugCheckInvalidValueType = null;
    final streamController = StreamController<List<Map<String, dynamic>>>.broadcast();
    final fakeRatingService = FakeRatingService(streamController);
    final fakeUserService = FakeUserService();
    final fakeAuthService = FakeAuthService();

    Widget buildTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<AuthService>.value(value: fakeAuthService),
            Provider<UserService>.value(value: fakeUserService),
            Provider<RatingService>.value(value: fakeRatingService),
          ],
          child: Builder(
            builder: (context) {
              Responsive.init(context);
              return const HelperReviewsScreen(
                helperId: 'helper_123',
                averageRating: 5.0,
                reviewCount: 1,
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTestWidget());
    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    expect(fakeRatingService.streamAccessCount, equals(1));

    // Emit empty reviews list
    streamController.add([]);
    await tester.pumpAndSettle();

    expect(find.text('No reviews found'), findsOneWidget);

    // Rebuild parent widget tree
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify stream was cached and not accessed again on rebuild
    expect(fakeRatingService.streamAccessCount, equals(1));

    // Emit review data matching ReviewCard expected map structure
    streamController.add([
      {
        'id': 'rev_1',
        'seekerId': 'user_1',
        'overallRating': 5.0,
        'feedback': 'Awesome work on the project!',
        'tags': ['Punctual', 'Friendly'],
        'createdAt': null,
      }
    ]);

    await tester.pumpAndSettle();

    expect(find.text('Awesome work on the project!'), findsOneWidget);
    expect(find.text('Reviewer User'), findsOneWidget);

    await streamController.close();
  });
}
