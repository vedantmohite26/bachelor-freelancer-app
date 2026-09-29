import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/profile/screens/my_profile_screen.dart';
import 'package:freelancer/features/profile/screens/helper_profile_screen.dart';

class FakeUser implements User {
  @override
  final String uid;

  FakeUser({required this.uid});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  User? _user;

  FakeAuthService(String uid) {
    _user = FakeUser(uid: uid);
  }

  @override
  User? get user => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserService implements UserService {
  int getUserProfileStreamCallCount = 0;
  final Map<String, Map<String, dynamic>?> _profiles = {};
  final Map<String, StreamController<Map<String, dynamic>?>> _controllers = {};

  void setProfile(String userId, Map<String, dynamic> data) {
    _profiles[userId] = data;
    if (_controllers.containsKey(userId)) {
      _controllers[userId]!.add(data);
    }
  }

  @override
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    getUserProfileStreamCallCount++;
    _controllers.putIfAbsent(userId, () => StreamController<Map<String, dynamic>?>.broadcast());

    return Stream.multi((controller) {
      if (_profiles.containsKey(userId)) {
        controller.add(_profiles[userId]);
      }
      final sub = _controllers[userId]!.stream.listen((data) {
        controller.add(data);
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRatingService implements RatingService {
  int getHelperRatingsCallCount = 0;

  @override
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    getHelperRatingsCallCount++;
    return Stream.value([
      {
        'overallRating': 5.0,
        'comment': 'Great job!',
        'createdAt': DateTime.now().toIso8601String(),
      }
    ]);
  }

  @override
  Future<Map<int, int>> getRatingDistribution(String helperId) async {
    return {5: 1, 4: 0, 3: 0, 2: 0, 1: 0};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFriendService implements FriendService {
  int getFriendStatusStreamCallCount = 0;

  @override
  Stream<FriendStatus> getFriendStatusStream(String currentUserId, String targetUserId) {
    getFriendStatusStreamCallCount++;
    return Stream.value(FriendStatus.connected);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeJobService implements JobService {
  @override
  Future<List<Map<String, dynamic>>> getHelperCompletedJobs(String helperId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChatService implements ChatService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAuthService fakeAuthService;
  late FakeUserService fakeUserService;
  late FakeRatingService fakeRatingService;
  late FakeFriendService fakeFriendService;
  late FakeJobService fakeJobService;
  late FakeChatService fakeChatService;

  setUp(() {
    fakeAuthService = FakeAuthService('user_123');
    fakeUserService = FakeUserService();
    fakeRatingService = FakeRatingService();
    fakeFriendService = FakeFriendService();
    fakeJobService = FakeJobService();
    fakeChatService = FakeChatService();
  });

  Widget buildTestableWidget(Widget child, {required void Function(StateSetter) onStateCreated}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: fakeAuthService),
        Provider<UserService>.value(value: fakeUserService),
        Provider<RatingService>.value(value: fakeRatingService),
        Provider<FriendService>.value(value: fakeFriendService),
        Provider<JobService>.value(value: fakeJobService),
        Provider<ChatService>.value(value: fakeChatService),
      ],
      child: MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            onStateCreated(setState);
            return child;
          },
        ),
        builder: (context, widget) {
          Responsive.init(context);
          return widget!;
        },
      ),
    );
  }

  testWidgets('MyProfileScreen renders profile data and caches getUserProfileStream across rebuilds', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    fakeUserService.setProfile('user_123', {
      'name': 'Alex Johnson',
      'email': 'alex@example.com',
      'university': 'State College',
      'isOnline': true,
      'totalEarnings': 150.0,
      'gigsCompleted': 5,
      'rating': 4.8,
      'reviewCount': 10,
      'points': 250,
      'skills': ['Dart', 'Flutter', 'Cleaning'],
    });

    late StateSetter parentSetState;

    // Pump widget
    await tester.pumpWidget(
      buildTestableWidget(
        const MyProfileScreen(),
        onStateCreated: (setter) => parentSetState = setter,
      ),
    );

    await tester.pump();

    // Verify rendered profile info
    expect(find.text('Alex Johnson'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text('State College'), findsOneWidget);
    expect(find.text('You are Online'), findsOneWidget);
    expect(find.text('₹150'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Level 2 — Beginner'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);

    final initialCallCount = fakeUserService.getUserProfileStreamCallCount;
    expect(initialCallCount, equals(1));

    // Trigger parent rebuild
    parentSetState(() {});
    await tester.pump();

    // Verify stream was NOT recreated
    expect(fakeUserService.getUserProfileStreamCallCount, equals(initialCallCount));
  });

  testWidgets('HelperProfileScreen renders profile data and caches streams across rebuilds', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    fakeUserService.setProfile('helper_456', {
      'name': 'Sam Helper',
      'bio': 'Pro Student Helper',
      'university': 'Tech Univ',
      'isOnline': false,
      'gigsCompleted': 12,
      'skills': ['Tutoring', 'Dog Walking'],
    });

    late StateSetter parentSetState;

    // Pump widget
    await tester.pumpWidget(
      buildTestableWidget(
        const HelperProfileScreen(helperId: 'helper_456'),
        onStateCreated: (setter) => parentSetState = setter,
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);

    // Verify rendered helper profile info
    expect(find.text('Sam Helper'), findsOneWidget);
    expect(find.text('Pro Student Helper'), findsOneWidget);
    expect(find.text('Tech Univ'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Tutoring'), findsOneWidget);

    final initialUserCalls = fakeUserService.getUserProfileStreamCallCount;
    final initialFriendCalls = fakeFriendService.getFriendStatusStreamCallCount;
    final initialRatingCalls = fakeRatingService.getHelperRatingsCallCount;

    expect(initialUserCalls, equals(1));
    expect(initialFriendCalls, equals(1));
    expect(initialRatingCalls, equals(1));

    // Force parent rebuild
    parentSetState(() {});
    await tester.pump();

    // Verify streams were cached and not re-subscribed
    expect(fakeUserService.getUserProfileStreamCallCount, equals(initialUserCalls));
    expect(fakeFriendService.getFriendStatusStreamCallCount, equals(initialFriendCalls));
    expect(fakeRatingService.getHelperRatingsCallCount, equals(initialRatingCalls));
  });
}
