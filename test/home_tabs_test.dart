// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/location_service.dart';
import 'package:freelancer/features/home/screens/helper_dashboard_tab.dart';
import 'package:freelancer/features/home/screens/seeker_home_tab.dart';
import 'package:geolocator/geolocator.dart';

class TestUser implements User {
  @override
  final String uid;
  TestUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  User? _user;
  FakeAuthService(String uid) {
    _user = TestUser(uid);
  }

  @override
  User? get user => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TrackedUserService implements UserService {
  int getUserProfileStreamCalls = 0;
  int getNearbyHelpersCalls = 0;

  final Map<String, dynamic> profileData = {
    'isOnline': true,
    'todaysEarnings': 150.0,
    'gigsCompleted': 5,
    'coins': 200,
  };

  @override
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    getUserProfileStreamCalls++;
    return Stream.value(profileData);
  }

  @override
  Stream<List<Map<String, dynamic>>> getNearbyHelpers({int limit = 10}) {
    getNearbyHelpersCalls++;
    return Stream.value([
      {
        'id': 'helper1',
        'name': 'Alice Smith',
        'rating': 4.8,
        'reviewCount': 12,
        'verifiedStudent': true,
      },
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TrackedJobService implements JobService {
  int getHelperApplicationsCalls = 0;
  int getHelperUpcomingGigsCalls = 0;

  @override
  Stream<List<Map<String, dynamic>>> getHelperApplications(String helperId) {
    getHelperApplicationsCalls++;
    return Stream.value([
      {
        'id': 'app1',
        'status': 'pending',
      },
    ]);
  }

  @override
  Stream<List<Map<String, dynamic>>> getHelperUpcomingGigs(String helperId) {
    getHelperUpcomingGigsCalls++;
    return Stream.value([
      {
        'id': 'job1',
        'title': 'Campus Delivery',
        'category': 'Delivery',
        'price': 25.0,
        'time': '14:00 PM',
        'status': 'assigned',
      },
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocationService implements LocationService {
  @override
  Future<Position?> getCurrentLocation() async {
    return Position(
      longitude: -122.2585,
      latitude: 37.8719,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAuthService fakeAuthService;
  late TrackedUserService trackedUserService;
  late TrackedJobService trackedJobService;
  late FakeLocationService fakeLocationService;

  setUp(() {
    fakeAuthService = FakeAuthService('user_123');
    trackedUserService = TrackedUserService();
    trackedJobService = TrackedJobService();
    fakeLocationService = FakeLocationService();
  });

  Widget createWidgetWrapper(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: fakeAuthService),
        Provider<UserService>.value(value: trackedUserService),
        Provider<JobService>.value(value: trackedJobService),
        Provider<LocationService>.value(value: fakeLocationService),
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

  testWidgets('HelperDashboardTab renders correctly and caches streams across rebuilds', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(createWidgetWrapper(const HelperDashboardTab()));
    await tester.pump();
    await tester.pump(); // Second pump for nested StreamBuilders

    // Verify initial rendering
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text("You're Online"), findsOneWidget);
    expect(find.text('₹150.00'), findsOneWidget);
    expect(find.text('Application #1'), findsOneWidget);
    expect(find.text('Campus Delivery'), findsOneWidget);

    expect(trackedUserService.getUserProfileStreamCalls, equals(1));
    expect(trackedJobService.getHelperApplicationsCalls, equals(1));
    expect(trackedJobService.getHelperUpcomingGigsCalls, equals(1));

    // Rebuild the widget tree
    await tester.pumpWidget(createWidgetWrapper(const HelperDashboardTab()));
    await tester.pump();
    await tester.pump();

    // Verify stream getters were NOT called again
    expect(trackedUserService.getUserProfileStreamCalls, equals(1));
    expect(trackedJobService.getHelperApplicationsCalls, equals(1));
    expect(trackedJobService.getHelperUpcomingGigsCalls, equals(1));
  });

  testWidgets('SeekerHomeTab renders correctly and caches streams across rebuilds', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(createWidgetWrapper(const SeekerHomeTab()));
    await tester.pump();
    await tester.pump();

    // Verify initial rendering
    expect(find.text('Nearby Helpers'), findsOneWidget);
    expect(find.text('Alice Smith'), findsOneWidget);

    expect(trackedUserService.getNearbyHelpersCalls, equals(1));

    // Rebuild the widget tree
    await tester.pumpWidget(createWidgetWrapper(const SeekerHomeTab()));
    await tester.pump();
    await tester.pump();

    // Verify stream getter was NOT called again
    expect(trackedUserService.getNearbyHelpersCalls, equals(1));
  });
}
