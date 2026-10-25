import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/community_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/community/screens/campus_feed_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

class FakeUser implements User {
  @override
  final String uid;
  FakeUser({required this.uid});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  @override
  User? get user => FakeUser(uid: 'user_1');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCommunityService implements CommunityService {
  int getPostsStreamCallCount = 0;
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  final List<Map<String, dynamic>> posts;

  FakeCommunityService({this.posts = const []});

  @override
  Stream<List<Map<String, dynamic>>> getPostsStream({int limit = 20}) {
    getPostsStreamCallCount++;
    return Stream.multi((controller) {
      controller.add(posts);
      final sub = _controller.stream.listen(controller.add);
      controller.onCancel = () => sub.cancel();
    });
  }

  void emitPosts(List<Map<String, dynamic>> newPosts) {
    _controller.add(newPosts);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserService implements UserService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAuthService fakeAuthService;
  late FakeCommunityService fakeCommunityService;
  late FakeUserService fakeUserService;

  setUp(() {
    fakeAuthService = FakeAuthService();
    fakeCommunityService = FakeCommunityService(posts: [
      {
        'id': 'post_1',
        'authorName': 'Alice',
        'authorId': 'user_1',
        'content': 'Welcome to Campus Feed!',
        'isOfficial': false,
        'likes': 5,
        'comments': 2,
        'createdAt': null,
      },
    ]);
    fakeUserService = FakeUserService();
  });

  Widget createWidgetUnderTest(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: fakeAuthService),
        Provider<CommunityService>.value(value: fakeCommunityService),
        Provider<UserService>.value(value: fakeUserService),
      ],
      child: MaterialApp(
        builder: (context, child) {
          Responsive.init(context);
          return child!;
        },
        home: child,
      ),
    );
  }

  testWidgets('CampusFeedScreen renders posts list and caches stream on rebuild', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest(const CampusFeedScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Campus Community'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Welcome to Campus Feed!'), findsOneWidget);
    expect(fakeCommunityService.getPostsStreamCallCount, equals(1));

    // Rebuild CampusFeedScreen
    await tester.pumpWidget(createWidgetUnderTest(const CampusFeedScreen()));
    await tester.pumpAndSettle();

    // Stream getter should NOT be called again due to state caching
    expect(fakeCommunityService.getPostsStreamCallCount, equals(1));
  });

  testWidgets('CampusFeedScreen displays empty state when posts list is empty', (
    WidgetTester tester,
  ) async {
    fakeCommunityService = FakeCommunityService(posts: []);

    await tester.pumpWidget(createWidgetUnderTest(const CampusFeedScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No posts yet. Be the first!'), findsOneWidget);
  });
}
