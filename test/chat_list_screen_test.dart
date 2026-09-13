import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/features/chat/screens/chat_list_screen.dart';

class FakeAuthService extends Fake implements AuthService {
  final MockUser? mockUser;
  FakeAuthService(this.mockUser);

  @override
  User? get user => mockUser;
}

class MockUser extends Fake implements User {
  @override
  final String uid;
  MockUser(this.uid);
}

class FakeChatService extends Fake implements ChatService {
  final Stream<List<Map<String, dynamic>>> chatsStream;
  FakeChatService(this.chatsStream);

  @override
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return chatsStream;
  }
}

class FakeUserService extends Fake implements UserService {
  int getUserProfileCallCount = 0;

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    getUserProfileCallCount++;
    return {
      'id': userId,
      'name': 'Test User $userId',
      'profilePic': null,
    };
  }
}

void main() {
  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
  });

  testWidgets('ChatListScreen renders chats and caches profile future in _ChatListItem', (WidgetTester tester) async {
    final fakeUser = MockUser('user1');
    final fakeAuth = FakeAuthService(fakeUser);
    final chatStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
    final fakeChat = FakeChatService(chatStreamController.stream);
    final fakeUserSvc = FakeUserService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: fakeAuth),
          Provider<ChatService>.value(value: fakeChat),
          Provider<UserService>.value(value: fakeUserSvc),
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

    // Push stream data
    chatStreamController.add([
      {
        'id': 'chat1',
        'participants': ['user1', 'user2'],
        'lastMessage': 'Hello there!',
        'lastMessageTime': null,
      }
    ]);

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text("Messages"), findsOneWidget);
    expect(find.text("Hello there!"), findsOneWidget);
    expect(find.text("Test User user2"), findsOneWidget);

    final initialCallCount = fakeUserSvc.getUserProfileCallCount;
    expect(initialCallCount, equals(1));

    // Rebuild ChatListScreen widget tree
    tester.element(find.byType(ChatListScreen)).markNeedsBuild();
    await tester.pumpAndSettle();

    // Verify getUserProfile was NOT called again because _userProfileFuture is cached in state
    expect(fakeUserSvc.getUserProfileCallCount, equals(initialCallCount));

    await chatStreamController.close();
  });
}
