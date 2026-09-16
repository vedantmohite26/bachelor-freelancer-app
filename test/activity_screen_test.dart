import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/payment_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/activity/screens/activity_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockUser implements User {
  @override
  String get uid => 'test_user_123';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  final User? _user;
  FakeAuthService(this._user);

  @override
  User? get user => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationService implements NotificationService {
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  void emit(List<Map<String, dynamic>> items) {
    _controller.add(items);
  }

  @override
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFriendService implements FriendService {
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  @override
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream(String userId) {
    return _controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePaymentService implements PaymentService {
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  void emit(List<Map<String, dynamic>> items) {
    _controller.add(items);
  }

  @override
  Stream<List<Map<String, dynamic>>> getAllUserPaymentsStream(String userId) {
    return _controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
  });

  Widget buildTestWidget({
    required AuthService authService,
    required NotificationService notificationService,
    required FriendService friendService,
    required PaymentService paymentService,
  }) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<FriendService>.value(value: friendService),
        Provider<PaymentService>.value(value: paymentService),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return const ActivityScreen();
          },
        ),
      ),
    );
  }

  testWidgets('ActivityScreen renders notifications correctly with RepaintBoundary', (tester) async {
    final mockUser = MockUser();
    final fakeAuth = FakeAuthService(mockUser);
    final fakeNotif = FakeNotificationService();
    final fakeFriend = FakeFriendService();
    final fakePayment = FakePaymentService();

    await tester.pumpWidget(
      buildTestWidget(
        authService: fakeAuth,
        notificationService: fakeNotif,
        friendService: fakeFriend,
        paymentService: fakePayment,
      ),
    );

    await tester.pump();

    // Emit notification item
    fakeNotif.emit([
      {
        'id': 'notif_1',
        'type': 'job',
        'title': 'Job Accepted',
        'subtitle': 'Your job request was accepted by Alex.',
        'timestamp': null,
        'isRead': false,
      }
    ]);

    await tester.pump();

    expect(find.text('Job Accepted'), findsOneWidget);
    expect(find.text('Your job request was accepted by Alex.'), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
  });
}
