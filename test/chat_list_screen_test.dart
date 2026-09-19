import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/chat/screens/chat_list_screen.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeUser implements User {
  @override
  final String uid;
  FakeUser(this.uid);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  final String _uid;
  FakeAuthService(this._uid);

  @override
  User? get user => FakeUser(_uid);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChatService implements ChatService {
  final List<Map<String, dynamic>> chats;
  FakeChatService(this.chats);

  @override
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return Stream.value(chats);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserService implements UserService {
  int getUserProfileCallCount = 0;
  final Map<String, Map<String, dynamic>> userProfiles;

  FakeUserService(this.userProfiles);

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) {
    getUserProfileCallCount++;
    return Future.value(userProfiles[userId]);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Provider.debugCheckInvalidValueType = null;
  });

  testWidgets('ChatListScreen renders chats and caches user profile future', (
    WidgetTester tester,
  ) async {
    final fakeAuth = FakeAuthService('user_me');
    final fakeChat = FakeChatService([
      {
        'id': 'chat_1',
        'participants': ['user_me', 'user_other'],
        'lastMessage': 'Hello Bolt!',
        'lastMessageTime': null,
      },
    ]);
    final fakeUser = FakeUserService({
      'user_other': {'name': 'Alice', 'profilePic': null},
    });

    late StateSetter parentSetState;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: fakeAuth),
          Provider<ChatService>.value(value: fakeChat),
          Provider<UserService>.value(value: fakeUser),
        ],
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              parentSetState = setState;
              Responsive.init(context);
              return const ChatListScreen();
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Hello Bolt!'), findsOneWidget);
    expect(fakeUser.getUserProfileCallCount, equals(1));

    // Trigger a rebuild of the parent widget
    parentSetState(() {});
    await tester.pump();

    // Call count should remain 1 because _ChatListItem caches the future in state
    expect(fakeUser.getUserProfileCallCount, equals(1));
  });
}
