import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/chat/screens/chat_list_screen.dart';

class MockUser implements fb_auth.User {
  @override
  String get uid => 'user1';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  final MockUser _user = MockUser();

  @override
  fb_auth.User? get user => _user;

  fb_auth.User? get currentUser => _user;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChatService implements ChatService {
  final StreamController<List<Map<String, dynamic>>> _chatsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  void emitChats(List<Map<String, dynamic>> chats) {
    _chatsController.add(chats);
  }

  @override
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _chatsController.stream;
  }

  void dispose() {
    _chatsController.close();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserService implements UserService {
  int getUserProfileCallCount = 0;

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    getUserProfileCallCount++;
    return {
      'id': userId,
      'name': 'Alice',
      'profilePic': null,
    };
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ChatListScreen renders chat items and caches user profile future', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService();
    final fakeChat = FakeChatService();
    final fakeUser = FakeUserService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: fakeAuth),
          Provider<ChatService>.value(value: fakeChat),
          Provider<UserService>.value(value: fakeUser),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const ChatListScreen();
            },
          ),
        ),
      ),
    );

    // Initial state before chats stream emits
    await tester.pump();

    // Emit chat data
    fakeChat.emitChats([
      {
        'id': 'chat123',
        'participants': ['user1', 'user2'],
        'lastMessage': 'Hello world!',
        'lastMessageTime': null,
      }
    ]);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify chat item renders with fetched user profile
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Hello world!'), findsOneWidget);

    final initialCallCount = fakeUser.getUserProfileCallCount;
    expect(initialCallCount, equals(1));

    // Force parent rebuild by triggering state/pump
    await tester.pump();
    await tester.pump();

    // Verify getUserProfile was NOT called again due to future caching
    expect(fakeUser.getUserProfileCallCount, equals(initialCallCount));

    fakeChat.dispose();
  });
}
