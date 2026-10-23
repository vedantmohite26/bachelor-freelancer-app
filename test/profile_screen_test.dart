import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/profile/screens/my_profile_screen.dart';
import 'package:freelancer/features/profile/screens/helper_profile_screen.dart';

class FakeAuthService extends ChangeNotifier implements AuthService {
  final User? _user;
  FakeAuthService([this._user]);

  @override
  User? get user => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserService implements UserService {
  int getUserProfileStreamCallCount = 0;
  final StreamController<Map<String, dynamic>?> _profileController =
      StreamController<Map<String, dynamic>?>.broadcast();

  FakeUserService();

  @override
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    getUserProfileStreamCallCount++;
    return _profileController.stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) => sink.add(data),
      ),
    );
  }

  void emitProfile(Map<String, dynamic> data) {
    _profileController.add(data);
  }

  @override
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFriendService implements FriendService {
  int getFriendStatusStreamCallCount = 0;

  @override
  Stream<FriendStatus> getFriendStatusStream(
    String userId,
    String helperId,
  ) {
    getFriendStatusStreamCallCount++;
    return Stream.value(FriendStatus.none);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRatingService implements RatingService {
  int getHelperRatingsCallCount = 0;

  @override
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    getHelperRatingsCallCount++;
    return Stream.value([]);
  }

  @override
  Future<Map<int, int>> getRatingDistribution(String helperId) async {
    return {5: 3, 4: 2, 3: 0, 2: 0, 1: 0};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeJobService implements JobService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUser implements User {
  @override
  final String uid;
  FakeUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('MyProfileScreen renders and caches user profile stream across rebuilds', (
    WidgetTester tester,
  ) async {
    final fakeUser = FakeUser('user_123');
    final fakeAuthService = FakeAuthService(fakeUser);
    final profileData = {
      'name': 'Alex Johnson',
      'email': 'alex@campus.edu',
      'isOnline': true,
      'totalEarnings': 450.0,
      'gigsCompleted': 12,
      'rating': 4.8,
      'reviewCount': 5,
      'points': 250,
      'university': 'State University',
      'skills': ['Flutter', 'Dart', 'Design'],
    };
    final fakeUserService = FakeUserService();

    Widget buildTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: fakeAuthService),
          Provider<UserService>.value(value: fakeUserService),
          Provider<JobService>.value(value: FakeJobService()),
          Provider<RatingService>.value(value: FakeRatingService()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const MyProfileScreen();
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTestWidget());
    fakeUserService.emitProfile(profileData);
    await tester.pumpAndSettle();

    expect(find.text('Alex Johnson'), findsOneWidget);
    expect(find.text('alex@campus.edu'), findsOneWidget);
    expect(find.text('State University'), findsOneWidget);

    final initialCallCount = fakeUserService.getUserProfileStreamCallCount;
    expect(initialCallCount, equals(1));

    // Trigger parent rebuild
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify stream was cached and not re-subscribed
    expect(fakeUserService.getUserProfileStreamCallCount, equals(initialCallCount));
  });

  testWidgets('HelperProfileScreen renders and caches stream instances across rebuilds', (
    WidgetTester tester,
  ) async {
    final fakeUser = FakeUser('viewer_456');
    final fakeAuthService = FakeAuthService(fakeUser);
    final helperData = {
      'name': 'Jordan Smith',
      'bio': 'Computer Science Major',
      'university': 'Tech Campus',
      'isOnline': false,
      'walletBalance': 100.0,
      'gigsCompleted': 5,
      'skills': ['Python', 'Data Science'],
    };
    final fakeUserService = FakeUserService();
    final fakeFriendService = FakeFriendService();
    final fakeRatingService = FakeRatingService();

    Widget buildTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: fakeAuthService),
          Provider<UserService>.value(value: fakeUserService),
          Provider<FriendService>.value(value: fakeFriendService),
          Provider<RatingService>.value(value: fakeRatingService),
          Provider<JobService>.value(value: FakeJobService()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const HelperProfileScreen(helperId: 'helper_789');
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTestWidget());
    fakeUserService.emitProfile(helperData);
    await tester.pumpAndSettle();

    expect(find.text('Jordan Smith'), findsOneWidget);
    expect(find.text('Tech Campus'), findsOneWidget);

    final userCalls = fakeUserService.getUserProfileStreamCallCount;
    final friendCalls = fakeFriendService.getFriendStatusStreamCallCount;
    final ratingCalls = fakeRatingService.getHelperRatingsCallCount;

    expect(userCalls, equals(1));
    expect(friendCalls, equals(1));
    expect(ratingCalls, equals(1));

    // Trigger parent rebuild
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify all stream instances were cached across rebuild
    expect(fakeUserService.getUserProfileStreamCallCount, equals(userCalls));
    expect(fakeFriendService.getFriendStatusStreamCallCount, equals(friendCalls));
    expect(fakeRatingService.getHelperRatingsCallCount, equals(ratingCalls));
  });
}
