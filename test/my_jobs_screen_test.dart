// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/jobs/screens/my_jobs_screen.dart';

class FakeUser extends Fake implements User {
  @override
  final String uid;
  FakeUser(this.uid);
}

class FakeAuthService implements AuthService {
  final User? _mockUser;

  FakeAuthService([this._mockUser]);

  @override
  User? get user => _mockUser;

  @override
  bool get isAuthenticated => _mockUser != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeJobService implements JobService {
  final List<Map<String, dynamic>> _postedJobs;
  int getApplicationCountStreamCallCount = 0;

  FakeJobService(this._postedJobs);

  @override
  Stream<List<Map<String, dynamic>>> getUserPostedJobs(String userId) {
    return Stream.value(_postedJobs);
  }

  @override
  Stream<int> getApplicationCountStream(String jobId, String seekerId) {
    getApplicationCountStreamCallCount++;
    return Stream.value(3);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createWidgetToTest({
  required AuthService authService,
  required JobService jobService,
}) {
  return MultiProvider(
    providers: [
      Provider<AuthService>.value(value: authService),
      Provider<JobService>.value(value: jobService),
    ],
    child: MaterialApp(
      builder: (context, child) {
        Responsive.init(context);
        return child!;
      },
      home: const MyJobsScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
  });

  testWidgets('MyJobsScreen renders jobs list and filter tabs correctly', (WidgetTester tester) async {
    final fakeUser = FakeUser('user123');
    final fakeAuth = FakeAuthService(fakeUser);
    final fakeJobs = [
      {
        'id': 'job1',
        'title': 'Deliver Groceries',
        'price': 250.0,
        'status': 'open',
        'applications': 3,
      },
      {
        'id': 'job2',
        'title': 'Fix Bike Chain',
        'price': 150.0,
        'status': 'completed',
        'applications': 1,
      },
    ];
    final fakeJobService = FakeJobService(fakeJobs);

    await tester.pumpWidget(
      createWidgetToTest(
        authService: fakeAuth,
        jobService: fakeJobService,
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Posted Jobs'), findsOneWidget);
    expect(find.text('Deliver Groceries'), findsOneWidget);
    expect(find.text('Fix Bike Chain'), findsOneWidget);
  });

  testWidgets('_JobCard caches _applicationCountStream across rebuilds', (WidgetTester tester) async {
    final fakeUser = FakeUser('user123');
    final fakeAuth = FakeAuthService(fakeUser);
    final fakeJobs = [
      {
        'id': 'job1',
        'title': 'Deliver Groceries',
        'price': 250.0,
        'status': 'open',
        'applications': 3,
      },
    ];
    final fakeJobService = FakeJobService(fakeJobs);

    await tester.pumpWidget(
      createWidgetToTest(
        authService: fakeAuth,
        jobService: fakeJobService,
      ),
    );

    await tester.pump();
    await tester.pump();

    // Initial count of getApplicationCountStream calls for 1 job card
    final initialCalls = fakeJobService.getApplicationCountStreamCallCount;
    expect(initialCalls, equals(1));

    // Tap "Open" filter chip to trigger setState on MyJobsScreen
    await tester.tap(find.text('Open'));
    await tester.pump();

    // Tap "All" filter chip to trigger setState on MyJobsScreen again
    await tester.tap(find.text('All'));
    await tester.pump();

    // Since _JobCard is a StatefulWidget and caches _applicationCountStream,
    // getApplicationCountStream should NOT be re-called when switching filters back and forth for the same job.
    expect(fakeJobService.getApplicationCountStreamCallCount, equals(initialCalls));
  });
}
