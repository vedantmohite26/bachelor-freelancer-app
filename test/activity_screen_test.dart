// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/core/services/payment_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/activity/screens/activity_screen.dart';
import 'package:provider/provider.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'test_user_123';
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  final User _user = FakeUser();

  @override
  User? get user => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationService extends Fake implements NotificationService {
  int getUserNotificationsCallCount = 0;

  @override
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    getUserNotificationsCallCount++;
    late StreamController<List<Map<String, dynamic>>> controller;
    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () {
        controller.add([
          {
            'id': 'notif_1',
            'type': 'job',
            'title': 'Job Application Accepted',
            'subtitle': 'Your application for Math Tutor was accepted.',
            'timestamp': Timestamp.fromDate(DateTime.now()),
            'isRead': false,
          },
        ]);
      },
    );
    return controller.stream;
  }

  @override
  Future<void> deleteAllUserNotifications(String userId) async {}
}

class FakePaymentService extends ChangeNotifier implements PaymentService {
  int getAllUserPaymentsCallCount = 0;

  @override
  Stream<List<Map<String, dynamic>>> getAllUserPaymentsStream(String userId) {
    getAllUserPaymentsCallCount++;
    late StreamController<List<Map<String, dynamic>>> controller;
    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () {
        controller.add([
          {
            'id': 'pay_1',
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'amount': 500,
            'isIncoming': true,
            'jobTitle': 'Gardening Work',
          },
        ]);
      },
    );
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFriendService extends Fake implements FriendService {
  int getIncomingRequestsCallCount = 0;

  @override
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream(String userId) {
    getIncomingRequestsCallCount++;
    late StreamController<List<Map<String, dynamic>>> controller;
    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () {
        controller.add([
          {'id': 'req_1', 'senderId': 'user_2'},
        ]);
      },
    );
    return controller.stream;
  }
}

void main() {
  late FakeAuthService fakeAuthService;
  late FakeNotificationService fakeNotificationService;
  late FakePaymentService fakePaymentService;
  late FakeFriendService fakeFriendService;

  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
  });

  setUp(() {
    fakeAuthService = FakeAuthService();
    fakeNotificationService = FakeNotificationService();
    fakePaymentService = FakePaymentService();
    fakeFriendService = FakeFriendService();
  });

  Widget buildTestableWidget({void Function(StateSetter setter)? setParentState}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: fakeAuthService),
        Provider<NotificationService>.value(value: fakeNotificationService),
        ChangeNotifierProvider<PaymentService>.value(value: fakePaymentService),
        Provider<FriendService>.value(value: fakeFriendService),
      ],
      child: MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            if (setParentState != null) {
              setParentState(setState);
            }
            Responsive.init(context);
            return const ActivityScreen();
          },
        ),
      ),
    );
  }

  testWidgets('ActivityScreen renders tabs and caches notification stream on rebuild', (
    WidgetTester tester,
  ) async {
    StateSetter? parentSetState;

    await tester.pumpWidget(buildTestableWidget(
      setParentState: (setter) => parentSetState = setter,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Job Updates'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);

    expect(find.text('Job Application Accepted'), findsOneWidget);
    expect(fakeNotificationService.getUserNotificationsCallCount, equals(1));

    // Rebuild the parent widget
    parentSetState?.call(() {});
    await tester.pumpAndSettle();

    // Stream should remain cached and not called again
    expect(fakeNotificationService.getUserNotificationsCallCount, equals(1));
  });

  testWidgets('Switching tabs to Payments shows payment items and uses cached stream', (
    WidgetTester tester,
  ) async {
    StateSetter? parentSetState;

    await tester.pumpWidget(buildTestableWidget(
      setParentState: (setter) => parentSetState = setter,
    ));
    await tester.pumpAndSettle();

    // Tap Payments tab
    await tester.tap(find.text('Payments'));
    await tester.pumpAndSettle();

    expect(find.text('Gardening Work'), findsOneWidget);
    expect(find.text('+₹500.00'), findsOneWidget);
    expect(fakePaymentService.getAllUserPaymentsCallCount, equals(1));

    // Rebuild tree
    parentSetState?.call(() {});
    await tester.pumpAndSettle();

    expect(fakePaymentService.getAllUserPaymentsCallCount, equals(1));
  });

  testWidgets('Switching tabs to Community shows incoming friend request count', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap Community tab
    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();

    expect(find.text('Friend Requests'), findsOneWidget);
    expect(find.text('1 new requests'), findsOneWidget);
    expect(fakeFriendService.getIncomingRequestsCallCount, equals(1));
  });
}
