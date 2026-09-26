// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/chat/screens/new_chat_screen.dart';
import 'package:provider/provider.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'user123';
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  final User? _user;
  FakeAuthService([this._user]);

  @override
  User? get user => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFriendService implements FriendService {
  int getFriendsStreamCallCount = 0;
  final StreamController<List<Map<String, dynamic>>> controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  @override
  Stream<List<Map<String, dynamic>>> getFriendsStream(String userId) {
    getFriendsStreamCallCount++;
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChatService implements ChatService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestWidget({
    required AuthService authService,
    required FriendService friendService,
    required ChatService chatService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<FriendService>.value(value: friendService),
        Provider<ChatService>.value(value: chatService),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return const NewChatScreen();
          },
        ),
      ),
    );
  }

  testWidgets('Renders login message when user is null', (WidgetTester tester) async {
    final authService = FakeAuthService(null);
    final friendService = FakeFriendService();
    final chatService = FakeChatService();

    await tester.pumpWidget(
      buildTestWidget(
        authService: authService,
        friendService: friendService,
        chatService: chatService,
      ),
    );

    expect(find.text("Please log in to chat"), findsOneWidget);
  });

  testWidgets('Renders empty state when friends stream emits empty list', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService(FakeUser());
    final friendService = FakeFriendService();
    final chatService = FakeChatService();

    await tester.pumpWidget(
      buildTestWidget(
        authService: authService,
        friendService: friendService,
        chatService: chatService,
      ),
    );

    friendService.controller.add([]);
    await tester.pump();

    expect(find.text("No friends yet"), findsOneWidget);
    expect(find.text("Add friends from the Community tab!"), findsOneWidget);
  });

  testWidgets('Renders friend items and caches stream across rebuilds', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService(FakeUser());
    final friendService = FakeFriendService();
    final chatService = FakeChatService();

    await tester.pumpWidget(
      buildTestWidget(
        authService: authService,
        friendService: friendService,
        chatService: chatService,
      ),
    );

    expect(friendService.getFriendsStreamCallCount, equals(1));

    friendService.controller.add([
      {
        'id': 'friend_1',
        'name': 'Alice Smith',
        'role': 'Helper',
        'profilePic': null,
      },
      {
        'id': 'friend_2',
        'name': 'Bob Jones',
        'role': 'Seeker',
        'profilePic': null,
      },
    ]);
    await tester.pump();

    expect(find.text("Alice Smith"), findsOneWidget);
    expect(find.text("Bob Jones"), findsOneWidget);

    // Trigger parent rebuild
    tester.binding.scheduleFrame();
    await tester.pump();

    // Verify stream was NOT re-requested
    expect(friendService.getFriendsStreamCallCount, equals(1));
  });
}
