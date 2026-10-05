import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/home/screens/home_screen.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/wallet_service.dart';
import 'package:freelancer/core/services/firestore_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/payment_service.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';

// Test Mocks

class MockAuthService extends ChangeNotifier implements AuthService {
  final User _user = MockUser(uid: 'user_123');

  @override
  User? get user => _user;

  @override
  bool get isAuthenticated => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserService implements UserService {
  int getUserProfileStreamCallCount = 0;
  final StreamController<Map<String, dynamic>?> _controller =
      StreamController<Map<String, dynamic>?>.broadcast();

  @override
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    getUserProfileStreamCallCount++;
    return _controller.stream;
  }

  void emitProfile(Map<String, dynamic>? profile) {
    _controller.add(profile);
  }

  @override
  Stream<List<Map<String, dynamic>>> getNearbyHelpers({int limit = 10}) {
    return Stream.value([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockJobService implements JobService {
  @override
  Stream<List<Map<String, dynamic>>> getUserPostedJobs(String userId) =>
      Stream.value([]);

  @override
  Stream<List<Map<String, dynamic>>> getHelperApplications(String userId) =>
      Stream.value([]);

  @override
  Stream<List<Map<String, dynamic>>> getHelperUpcomingGigs(String userId) =>
      Stream.value([]);

  @override
  Stream<List<Map<String, dynamic>>> getOpenJobs() => Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWalletService extends ChangeNotifier implements WalletService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFirestoreService implements FirestoreService {
  @override
  Stream<List<Map<String, dynamic>>> getJobsStream({String? currentUserId}) =>
      Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNotificationService implements NotificationService {
  @override
  void listenForNotifications(String userId) {}

  @override
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) =>
      Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFinanceService implements FinanceService {
  @override
  Stream<List<FinanceTransaction>> getTransactions(String userId) =>
      Stream.value([]);

  @override
  Stream<List<FinanceTransaction>> getTransactionsStream(String userId) =>
      Stream.value([]);

  @override
  Stream<Budget?> getBudgetStream(String userId) => Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFriendService implements FriendService {
  @override
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream(String userId) =>
      Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPaymentService extends ChangeNotifier implements PaymentService {
  @override
  Stream<List<Map<String, dynamic>>> getUserPaymentsStream(
    String userId, {
    bool asSeeker = true,
  }) => Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUser implements User {
  @override
  final String uid;
  MockUser({required this.uid});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockAuthService mockAuth;
  late MockUserService mockUser;

  setUp(() {
    mockAuth = MockAuthService();
    mockUser = MockUserService();
  });

  Widget createWidgetUnderTest({bool isSeeker = true}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: mockAuth),
        Provider<UserService>.value(value: mockUser),
        Provider<JobService>.value(value: MockJobService()),
        ChangeNotifierProvider<WalletService>.value(value: MockWalletService()),
        Provider<FirestoreService>.value(value: MockFirestoreService()),
        Provider<NotificationService>.value(value: MockNotificationService()),
        Provider<FinanceService>.value(value: MockFinanceService()),
        Provider<FriendService>.value(value: MockFriendService()),
        ChangeNotifierProvider<PaymentService>.value(value: MockPaymentService()),
      ],
      child: MaterialApp(
        builder: (context, child) {
          Responsive.init(context);
          return child!;
        },
        home: HomeScreen(isSeeker: isSeeker),
      ),
    );
  }

  testWidgets('HomeScreen caches user profile stream across tab switches', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(createWidgetUnderTest(isSeeker: true));
    await tester.pump();

    // Stream should have been requested exactly once during initial build
    expect(mockUser.getUserProfileStreamCallCount, equals(1));

    // Switch to Posted Jobs tab
    await tester.tap(find.text('Posted Jobs'));
    await tester.pump();

    // Stream call count must still be 1 (cached stream used)
    expect(mockUser.getUserProfileStreamCallCount, equals(1));

    // Switch to Finance tab
    await tester.tap(find.text('Finance'));
    await tester.pump();

    // Stream call count must still be 1
    expect(mockUser.getUserProfileStreamCallCount, equals(1));

    // Switch back to Find Help tab
    await tester.tap(find.text('Find Help'));
    await tester.pump();

    // Stream call count must still be 1
    expect(mockUser.getUserProfileStreamCallCount, equals(1));
  });
}
