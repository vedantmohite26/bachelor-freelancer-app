import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/features/community/screens/friend_requests_screen.dart';

// Suppress subtype of sealed class and override warnings for test fake classes
// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

class FakeUser implements User {
  @override
  final String uid;
  FakeUser({required this.uid});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  final User? _user;
  FakeAuthService({User? user}) : _user = user;

  @override
  User? get user => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFriendService implements FriendService {
  List<Map<String, dynamic>> _incomingData = [];
  List<Map<String, dynamic>> _sentData = [];

  final StreamController<List<Map<String, dynamic>>> _incomingNotifier =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _sentNotifier =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  int incomingStreamCallCount = 0;
  int sentStreamCallCount = 0;

  void emitIncoming(List<Map<String, dynamic>> requests) {
    _incomingData = requests;
    _incomingNotifier.add(requests);
  }

  void emitSent(List<Map<String, dynamic>> requests) {
    _sentData = requests;
    _sentNotifier.add(requests);
  }

  Stream<List<Map<String, dynamic>>> _createMultiSubscriberStream(
    List<Map<String, dynamic>> Function() getData,
    StreamController<List<Map<String, dynamic>>> notifier,
  ) {
    return Stream.multi((multiController) {
      multiController.add(getData());
      final sub = notifier.stream.listen((data) {
        multiController.add(data);
      });
      multiController.onCancel = () {
        sub.cancel();
      };
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream(String userId) {
    incomingStreamCallCount++;
    return _createMultiSubscriberStream(() => _incomingData, _incomingNotifier);
  }

  @override
  Stream<List<Map<String, dynamic>>> getSentRequestsStream(String userId) {
    sentStreamCallCount++;
    return _createMultiSubscriberStream(() => _sentData, _sentNotifier);
  }

  @override
  Stream<FriendStatus> getFriendStatusStream(
    String currentUserId,
    String targetUserId,
  ) {
    return Stream.value(FriendStatus.none);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserService implements UserService {
  @override
  Future<List<Map<String, dynamic>>> searchUsersByEmailPrefix(String prefix) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestableWidget({
    required AuthService authService,
    required FriendService friendService,
    required UserService userService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<FriendService>.value(value: friendService),
        Provider<UserService>.value(value: userService),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return const FriendRequestsScreen();
          },
        ),
      ),
    );
  }

  testWidgets('renders unauthenticated state when user is null', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeAuth = FakeAuthService(user: null);
    final fakeFriend = FakeFriendService();
    final fakeUser = FakeUserService();

    await tester.pumpWidget(
      buildTestableWidget(
        authService: fakeAuth,
        friendService: fakeFriend,
        userService: fakeUser,
      ),
    );

    expect(find.text('Please login to view requests'), findsOneWidget);
  });

  testWidgets(
    'caches stream invocations and displays request items and badges correctly',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeAuth = FakeAuthService(user: FakeUser(uid: 'user_123'));
      final fakeFriend = FakeFriendService();
      final fakeUser = FakeUserService();

      // Set initial data before widget tree renders
      fakeFriend.emitIncoming([
        {
          'requestId': 'req_1',
          'senderId': 'sender_1',
          'name': 'Alice Smith',
          'role': 'Student',
          'profilePic': null,
          'createdAt': null,
        },
      ]);

      fakeFriend.emitSent([
        {
          'requestId': 'req_2',
          'receiverId': 'receiver_1',
          'name': 'Bob Jones',
          'role': 'Tutor',
          'profilePic': null,
          'createdAt': null,
        },
      ]);

      await tester.pumpWidget(
        buildTestableWidget(
          authService: fakeAuth,
          friendService: fakeFriend,
          userService: fakeUser,
        ),
      );

      await tester.pumpAndSettle();

      // Verify each stream getter was called only ONCE during initState (caching working)
      expect(fakeFriend.incomingStreamCallCount, equals(1));
      expect(fakeFriend.sentStreamCallCount, equals(1));

      // Verify Tab titles exist
      expect(find.text('Find'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);

      // Tap on Received tab
      await tester.tap(find.text('Received'));
      await tester.pumpAndSettle();

      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap on Sent tab
      await tester.tap(find.text('Sent'));
      await tester.pumpAndSettle();

      expect(find.text('Bob Jones'), findsOneWidget);
      expect(find.text('Cancel Request'), findsOneWidget);

      // Ensure no additional stream getter calls occurred during tab switching or parent rebuilds
      expect(fakeFriend.incomingStreamCallCount, equals(1));
      expect(fakeFriend.sentStreamCallCount, equals(1));
    },
  );
}
