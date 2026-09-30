import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/community_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/community/screens/campus_feed_screen.dart';

class FakeCommunityService extends Fake implements CommunityService {
  int getPostsStreamCallCount = 0;
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  @override
  Stream<List<Map<String, dynamic>>> getPostsStream({int limit = 20}) {
    getPostsStreamCallCount++;
    return _controller.stream;
  }

  void emitPosts(List<Map<String, dynamic>> posts) {
    _controller.add(posts);
  }

  void close() {
    _controller.close();
  }
}

class FakeAuthService extends Fake implements AuthService {
  @override
  User? get user => null;
}

class FakeUserService extends Fake implements UserService {}

Widget createCampusFeedScreenWidget({
  required FakeCommunityService communityService,
  required FakeAuthService authService,
  required FakeUserService userService,
}) {
  return MultiProvider(
    providers: [
      Provider<CommunityService>.value(value: communityService),
      Provider<AuthService>.value(value: authService),
      Provider<UserService>.value(value: userService),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) {
          Responsive.init(context);
          return const CampusFeedScreen();
        },
      ),
    ),
  );
}

void main() {
  Provider.debugCheckInvalidValueType = null;

  late FakeCommunityService communityService;
  late FakeAuthService authService;
  late FakeUserService userService;

  setUp(() {
    communityService = FakeCommunityService();
    authService = FakeAuthService();
    userService = FakeUserService();
  });

  tearDown(() {
    communityService.close();
  });

  testWidgets('CampusFeedScreen shows loading then empty state when posts list is empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      createCampusFeedScreenWidget(
        communityService: communityService,
        authService: authService,
        userService: userService,
      ),
    );

    // Initial state: waiting for stream data -> progress indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Emit empty list
    communityService.emitPosts([]);
    await tester.pump();

    expect(find.text('No posts yet. Be the first!'), findsOneWidget);
  });

  testWidgets('CampusFeedScreen renders posts list and caches posts stream on rebuild', (WidgetTester tester) async {
    await tester.pumpWidget(
      createCampusFeedScreenWidget(
        communityService: communityService,
        authService: authService,
        userService: userService,
      ),
    );

    expect(communityService.getPostsStreamCallCount, 1);

    // Emit posts
    communityService.emitPosts([
      {
        'id': 'post_1',
        'authorName': 'Alice',
        'content': 'Hello campus!',
        'isOfficial': false,
        'likes': 5,
        'comments': 2,
        'createdAt': null,
      },
      {
        'id': 'post_2',
        'authorName': 'Student Council',
        'content': 'Important Announcement!',
        'isOfficial': true,
        'likes': 42,
        'comments': 10,
        'createdAt': null,
      },
    ]);
    await tester.pump();

    expect(find.text('Hello campus!'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Important Announcement!'), findsOneWidget);
    expect(find.text('Student Council'), findsOneWidget);

    // Force parent rebuild
    // ignore: invalid_use_of_protected_member
    tester.state<State<StatefulWidget>>(find.byType(CampusFeedScreen)).setState(() {});
    await tester.pump();

    // Stream getter should NOT be called again due to caching
    expect(communityService.getPostsStreamCallCount, 1);
  });
}
