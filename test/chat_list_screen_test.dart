import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/chat/screens/chat_list_screen.dart';

class FakeAuthService extends ChangeNotifier implements AuthService {
  final User? _fakeUser;
  FakeAuthService(this._fakeUser);

  @override
  User? get user => _fakeUser;

  @override
  bool get isAuthenticated => _fakeUser != null;

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

class FakeChatService implements ChatService {
  final StreamController<List<Map<String, dynamic>>> _chatsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  void emitChats(List<Map<String, dynamic>> chats) {
    _chatsController.add(chats);
  }

  @override
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) async* {
    yield [
      {
        'id': 'chat_123',
        'participants': [userId, 'helper_456'],
        'lastMessage': 'Hello there!',
        'lastMessageTime': Timestamp.now(),
      }
    ];
    yield* _chatsController.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CountingUserService implements UserService {
  int getUserProfileCallCount = 0;

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    getUserProfileCallCount++;
    return {
      'id': userId,
      'name': 'Helper Jane',
      'profilePic': null,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ChatListScreen renders chats and caches user profile futures across rebuilds', (
    WidgetTester tester,
  ) async {
    final fakeUser = FakeUser('seeker_123');
    final fakeAuth = FakeAuthService(fakeUser);
    final fakeChat = FakeChatService();
    final countingUser = CountingUserService();

    Widget buildTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: fakeAuth),
          Provider<ChatService>.value(value: fakeChat),
          Provider<UserService>.value(value: countingUser),
        ],
        child: MaterialApp(
          builder: (context, child) {
            Responsive.init(context);
            return child!;
          },
          home: const ChatListScreen(),
        ),
      );
    }

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify chat item is rendered with the fetched name
    expect(find.text('Helper Jane'), findsOneWidget);
    expect(find.text('Hello there!'), findsOneWidget);

    final initialCallCount = countingUser.getUserProfileCallCount;
    expect(initialCallCount, equals(1));

    // Re-pump widget tree to simulate parent rebuild
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Call count should remain unchanged because profile future was cached in state
    expect(countingUser.getUserProfileCallCount, equals(initialCallCount));
  });
}
