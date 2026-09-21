import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/community_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/community/screens/campus_feed_screen.dart';

class FakeCommunityService implements CommunityService {
  int getPostsStreamCallCount = 0;
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  @override
  Stream<List<Map<String, dynamic>>> getPostsStream({int limit = 20}) {
    getPostsStreamCallCount++;
    return Stream.multi((controller) {
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  void emitPosts(List<Map<String, dynamic>> posts) {
    _controller.add(posts);
  }

  @override
  Future<void> createPost({
    required String content,
    required String userId,
    required String userName,
    required bool isOfficial,
  }) async {}

  @override
  Future<void> toggleLike(String postId, String userId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  @override
  User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserService implements UserService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeCommunityService fakeCommunityService;
  late FakeAuthService fakeAuthService;
  late FakeUserService fakeUserService;

  setUp(() {
    fakeCommunityService = FakeCommunityService();
    fakeAuthService = FakeAuthService();
    fakeUserService = FakeUserService();
  });

  Widget buildTestWidget() {
    Provider.debugCheckInvalidValueType = null;
    return MultiProvider(
      providers: [
        Provider<CommunityService>.value(value: fakeCommunityService),
        Provider<AuthService>.value(value: fakeAuthService),
        Provider<UserService>.value(value: fakeUserService),
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

  testWidgets('CampusFeedScreen initializes stream once and updates UI on stream events', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    // Initially waiting
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(fakeCommunityService.getPostsStreamCallCount, equals(1));

    // Emit empty list
    fakeCommunityService.emitPosts([]);
    await tester.pumpAndSettle();

    expect(find.text("No posts yet. Be the first!"), findsOneWidget);

    // Trigger rebuild to ensure stream is cached and not re-subscribed
    tester.state<State<CampusFeedScreen>>(find.byType(CampusFeedScreen)).setState(() {});
    await tester.pumpAndSettle();

    expect(fakeCommunityService.getPostsStreamCallCount, equals(1));

    // Emit posts
    fakeCommunityService.emitPosts([
      {
        'id': '1',
        'authorName': 'Alice',
        'content': 'Welcome to campus!',
        'isOfficial': true,
        'likes': 5,
        'comments': 2,
        'createdAt': null,
      }
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Welcome to campus!'), findsOneWidget);
  });
}
