import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/features/jobs/screens/job_feed_screen.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/firestore_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/core/utils/responsive.dart';

class FakeUser implements User {
  @override
  final String uid;
  FakeUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  final User? _user;
  FakeAuthService(this._user);

  @override
  User? get user => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirestoreService implements FirestoreService {
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  void emitJobs(List<Map<String, dynamic>> jobs) {
    _controller.add(jobs);
  }

  @override
  Stream<List<Map<String, dynamic>>> getJobsStream({String? currentUserId}) {
    return _controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeJobService implements JobService {
  @override
  Stream<List<Map<String, dynamic>>> getAllHelperApplications(String userId) {
    return Stream.value([
      {'jobId': 'job_1'},
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserService implements UserService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationService implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAuthService fakeAuthService;
  late FakeFirestoreService fakeFirestoreService;
  late FakeJobService fakeJobService;
  late FakeUserService fakeUserService;
  late FakeNotificationService fakeNotificationService;

  setUp(() {
    fakeAuthService = FakeAuthService(FakeUser('test_user_id'));
    fakeFirestoreService = FakeFirestoreService();
    fakeJobService = FakeJobService();
    fakeUserService = FakeUserService();
    fakeNotificationService = FakeNotificationService();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: fakeAuthService),
        Provider<FirestoreService>.value(value: fakeFirestoreService),
        Provider<JobService>.value(value: fakeJobService),
        Provider<UserService>.value(value: fakeUserService),
        Provider<NotificationService>.value(value: fakeNotificationService),
      ],
      child: MaterialApp(
        builder: (context, child) {
          Responsive.init(context);
          return child!;
        },
        home: const JobFeedScreen(),
      ),
    );
  }

  testWidgets('JobFeedScreen displays empty state when no jobs are emitted', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(createWidgetUnderTest());

    // Initial state is loading
    expect(find.byType(JobFeedScreen), findsOneWidget);

    // Emit empty list
    fakeFirestoreService.emitJobs([]);
    await tester.pump();

    expect(find.text('No jobs found nearby.'), findsOneWidget);
  });

  testWidgets(
    'JobFeedScreen renders job items with distance display correctly',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(createWidgetUnderTest());

      fakeFirestoreService.emitJobs([
        {
          'id': 'job_1',
          'title': 'Couch Moving',
          'price': 150,
          'category': 'Moving',
          'time': '2 hours',
          'latitude': 12.9716,
          'longitude': 77.5946,
        },
        {
          'id': 'job_2',
          'title': 'Math Tutoring',
          'price': 200,
          'category': 'Tutoring',
          'time': 'Flexible',
        },
      ]);
      await tester.pump();

      expect(find.text('Couch Moving'), findsOneWidget);
      expect(find.text('Math Tutoring'), findsOneWidget);
      expect(find.text('₹150'), findsOneWidget);
      expect(find.text('₹200'), findsOneWidget);
      expect(find.text('Applied'), findsOneWidget); // For job_1 from FakeJobService
    },
  );
}
