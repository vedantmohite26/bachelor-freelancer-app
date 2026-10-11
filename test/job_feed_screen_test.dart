// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/firestore_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/features/jobs/screens/job_feed_screen.dart';
import 'package:freelancer/core/utils/responsive.dart';

class FakeAuthService extends Fake implements AuthService {
  final FakeUser _user = FakeUser('user123');

  @override
  User? get user => _user;
}

class FakeUser extends Fake implements User {
  @override
  final String uid;
  FakeUser(this.uid);
}

class FakeFirestoreService extends Fake implements FirestoreService {
  final StreamController<List<Map<String, dynamic>>> _jobsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  int getJobsStreamCallCount = 0;

  @override
  Stream<List<Map<String, dynamic>>> getJobsStream({String? currentUserId}) {
    getJobsStreamCallCount++;
    return _jobsController.stream;
  }

  void emitJobs(List<Map<String, dynamic>> jobs) {
    _jobsController.add(jobs);
  }

  void disposeController() {
    _jobsController.close();
  }
}

class FakeJobService extends Fake implements JobService {
  @override
  Stream<List<Map<String, dynamic>>> getAllHelperApplications(String helperId) {
    return Stream.value([]);
  }
}

class FakeUserService extends Fake implements UserService {}

class FakeNotificationService extends Fake implements NotificationService {}

void main() {
  late FakeAuthService fakeAuthService;
  late FakeFirestoreService fakeFirestoreService;
  late FakeJobService fakeJobService;
  late FakeUserService fakeUserService;
  late FakeNotificationService fakeNotificationService;

  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
  });

  setUp(() {
    fakeAuthService = FakeAuthService();
    fakeFirestoreService = FakeFirestoreService();
    fakeJobService = FakeJobService();
    fakeUserService = FakeUserService();
    fakeNotificationService = FakeNotificationService();
  });

  tearDown(() {
    fakeFirestoreService.disposeController();
  });

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: fakeAuthService),
        Provider<FirestoreService>.value(value: fakeFirestoreService),
        Provider<JobService>.value(value: fakeJobService),
        Provider<UserService>.value(value: fakeUserService),
        Provider<NotificationService>.value(value: fakeNotificationService),
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

  testWidgets('JobFeedScreen renders loading state initially', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const JobFeedScreen()));

    // Verify app bar location title
    expect(find.text("Fetching location..."), findsOneWidget);

    // Initial stream state shows loading shimmer
    expect(find.byType(JobFeedScreen), findsOneWidget);
  });

  testWidgets('JobFeedScreen displays empty state when stream emits no jobs', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const JobFeedScreen()));

    fakeFirestoreService.emitJobs([]);
    await tester.pump();

    expect(find.text("No jobs found nearby."), findsOneWidget);
  });

  testWidgets('JobFeedScreen displays jobs and caches stream across rebuilds', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const JobFeedScreen()));

    expect(fakeFirestoreService.getJobsStreamCallCount, 1);

    final testJobs = [
      {
        'id': 'job_1',
        'title': 'Tutoring Math',
        'price': 500,
        'category': 'Academics',
        'time': '2 hours',
        'priceType': 'fixed',
        'latitude': 12.9716,
        'longitude': 77.5946,
      },
    ];

    fakeFirestoreService.emitJobs(testJobs);
    await tester.pump();

    expect(find.text('Tutoring Math'), findsOneWidget);
    expect(find.text('₹500'), findsOneWidget);
    expect(find.text('Academics'), findsOneWidget);

    // Trigger parent rebuild
    tester.binding.scheduleFrame();
    await tester.pump();

    // Stream getter should NOT be called again due to caching
    expect(fakeFirestoreService.getJobsStreamCallCount, 1);
  });
}
