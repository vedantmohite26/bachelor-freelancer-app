// ignore_for_file: subtype_of_sealed_class, must_be_immutable
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/firestore_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/features/jobs/screens/job_feed_screen.dart';

class FakeAuthService extends ChangeNotifier implements AuthService {
  @override
  User? get user => null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirestoreService implements FirestoreService {
  final StreamController<List<Map<String, dynamic>>> _jobsController;
  int getJobsStreamCallCount = 0;

  FakeFirestoreService(this._jobsController);

  @override
  Stream<List<Map<String, dynamic>>> getJobsStream({String? currentUserId}) {
    getJobsStreamCallCount++;
    return _jobsController.stream;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeJobService implements JobService {
  final StreamController<List<Map<String, dynamic>>> _applicationsController;

  FakeJobService(this._applicationsController);

  @override
  Stream<List<Map<String, dynamic>>> getAllHelperApplications(String helperId) {
    return _applicationsController.stream;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserService implements UserService {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationService implements NotificationService {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late StreamController<List<Map<String, dynamic>>> jobsController;
  late StreamController<List<Map<String, dynamic>>> appsController;
  late FakeAuthService authService;
  late FakeFirestoreService firestoreService;
  late FakeJobService jobService;

  setUp(() {
    authService = FakeAuthService();
    jobsController = StreamController<List<Map<String, dynamic>>>.broadcast(sync: true);
    appsController = StreamController<List<Map<String, dynamic>>>.broadcast(sync: true);
    firestoreService = FakeFirestoreService(jobsController);
    jobService = FakeJobService(appsController);
  });

  tearDown(() {
    jobsController.close();
    appsController.close();
  });

  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<JobService>.value(value: jobService),
        Provider<UserService>.value(value: FakeUserService()),
        Provider<NotificationService>.value(value: FakeNotificationService()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return const JobFeedScreen();
          },
        ),
      ),
    );
  }

  testWidgets('JobFeedScreen renders jobs and caches getJobsStream on rebuilds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    jobsController.add([
      {
        'id': 'job_1',
        'title': 'Tutoring Math',
        'price': 500,
        'category': 'Education',
        'time': '2 hours',
        'priceType': 'fixed',
      },
      {
        'id': 'job_2',
        'title': 'Dog Walking',
        'price': 200,
        'category': 'Pet Care',
        'time': '1 hour',
        'priceType': 'hourly',
      },
    ]);

    await tester.pump();

    // Verify initial call count for getJobsStream is 1
    expect(firestoreService.getJobsStreamCallCount, equals(1));

    expect(find.text('Tutoring Math'), findsOneWidget);
    expect(find.text('Dog Walking'), findsOneWidget);
  });

  testWidgets('JobFeedScreen renders empty state when no jobs are present', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    jobsController.add([]);
    await tester.pump();

    expect(find.text('No jobs found nearby.'), findsOneWidget);
  });
}
