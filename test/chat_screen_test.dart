import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/chat/screens/chat_screen.dart';

class FakeUser implements User {
  @override
  final String uid;

  FakeUser(this.uid);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  final User? _fakeUser;

  FakeAuthService(String uid) : _fakeUser = FakeUser(uid);

  @override
  User? get user => _fakeUser;

  @override
  bool get isAuthenticated => _fakeUser != null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChatService implements ChatService {
  int getMessagesCallCount = 0;
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  final List<Map<String, dynamic>> messages;

  FakeChatService(this.messages);

  @override
  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    getMessagesCallCount++;
    // Emit current messages when listened to
    Future.microtask(() => _controller.add(List.from(messages)));
    return _controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    messages.insert(0, {
      'id': 'msg_${messages.length + 1}',
      'senderId': senderId,
      'content': content,
      'timestamp': null,
    });
    _controller.add(List.from(messages));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestWidget({
    required Widget child,
    required AuthService authService,
    required ChatService chatService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<ChatService>.value(value: chatService),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return child;
          },
        ),
      ),
    );
  }

  testWidgets('ChatScreen renders messages and caches stream across rebuilds', (
    WidgetTester tester,
  ) async {
    final fakeMessages = [
      {'id': '1', 'senderId': 'user_2', 'content': 'Hello there!'},
      {'id': '2', 'senderId': 'user_1', 'content': 'Hi! How can I help?'},
    ];
    final fakeChatService = FakeChatService(fakeMessages);
    final fakeAuthService = FakeAuthService('user_1');

    await tester.pumpWidget(
      buildTestWidget(
        child: const ChatScreen(chatId: 'chat_123', otherUserName: 'Alice'),
        authService: fakeAuthService,
        chatService: fakeChatService,
      ),
    );

    await tester.pump(); // Flush microtask

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Hello there!'), findsOneWidget);
    expect(find.text('Hi! How can I help?'), findsOneWidget);
    expect(fakeChatService.getMessagesCallCount, equals(1));

    // Trigger state change in ChatScreen (e.g. typing in textfield)
    await tester.enterText(find.byType(TextField), 'Testing message');
    await tester.pump();

    // Stream should remain cached and getMessages should NOT be called again
    expect(fakeChatService.getMessagesCallCount, equals(1));
  });
}
