import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/features/auth/screens/login_screen.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/wallet_service.dart';
import 'package:freelancer/core/services/firestore_service.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/leaderboard_service.dart';
import 'package:freelancer/core/services/location_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/core/services/community_service.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/cloudinary_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/category_service.dart';
import 'package:freelancer/core/services/rewards_service.dart';
import 'package:freelancer/core/services/payment_service.dart';

// Manual Mocks

class MockAuthService extends ChangeNotifier implements AuthService {
  User? _user;

  @override
  User? get user => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  Future<UserCredential> signInWithEmailOnly(
    String email,
    String password,
  ) async {
    _user = MockUser(uid: 'test_uid');
    notifyListeners();
    return MockUserCredential(user: _user);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserService implements UserService {
  final _controller = StreamController<Map<String, dynamic>?>.broadcast();
  Map<String, dynamic>? _profile;

  void setProfile(Map<String, dynamic> profile) {
    _profile = profile;
    _controller.add(profile);
  }

  @override
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    if (_profile != null) {
      _profile!.addAll(updates);
    } else {
      _profile = updates;
    }
    _controller.add(_profile);
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return _profile;
  }

  @override
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) async* {
    if (_profile != null) {
      yield _profile;
    }
    yield* _controller.stream;
  }

  @override
  Stream<List<Map<String, dynamic>>> getNearbyHelpers({int limit = 10}) {
    return Stream.value([]);
  }

  @override
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    // no-op
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MyMockJobService implements JobService {
  @override
  Stream<List<Map<String, dynamic>>> getHelperApplications(String userId) {
    return Stream.value([]);
  }

  @override
  Stream<List<Map<String, dynamic>>> getHelperUpcomingGigs(String userId) {
    return Stream.value([]);
  }

  @override
  Stream<List<Map<String, dynamic>>> getAllHelperApplications(String userId) {
    debugPrint('MyMockJobService.getAllHelperApplications called for $userId');
    return Stream.value([]);
  }

  @override
  Stream<List<Map<String, dynamic>>> getOpenJobs() {
    return Stream.value([]);
  }

  @override
  Stream<List<Map<String, dynamic>>> getUserPostedJobs(String userId) {
    return Stream.value([]);
  }

  @override
  Stream<int> getApplicationCountStream(String jobId, String seekerId) {
    return Stream.value(0);
  }

  @override
  Future<Map<String, dynamic>?> getJobById(String jobId) async => null;

  @override
  Stream<Map<String, dynamic>?> getJobStream(String jobId) =>
      Stream.value(null);

  @override
  Future<String> createJob(Map<String, dynamic> jobData) async => 'job_id';

  @override
  Future<void> applyForJob(String jobId, String helperId) async {}

  @override
  Future<bool> hasAppliedToJob(String jobId, String helperId) async => false;

  @override
  Future<List<Map<String, dynamic>>> getHelperCompletedJobs(
    String helperId,
  ) async => [];

  @override
  Future<void> updateJobStatus(String jobId, String status) async {}

  @override
  Future<void> completeJob(
    String jobId,
    String helperId,
    double earnings,
    String jobTitle,
  ) async {}

  @override
  Future<void> claimJob(String jobId, String helperId) async {}

  @override
  Stream<List<Map<String, dynamic>>> getJobApplications(
    String jobId,
    String seekerId,
  ) => Stream.value([]);

  @override
  Future<void> acceptApplication(
    String jobId,
    String applicationId,
    String helperId,
  ) async {}

  @override
  Future<void> rejectApplication(String applicationId) async {}

  @override
  Future<void> cancelJob(String jobId) async {}

  @override
  Stream<List<Map<String, dynamic>>> getActiveJobsForUser(
    String userId, {
    bool isSeeker = true,
  }) => Stream.value([]);

  @override
  Future<void> startJob(String jobId) async {}

  @override
  Future<String> generateVerificationToken(String jobId) async => 'token';

  @override
  Future<void> requestJobStart(String jobId) async {}

  @override
  Future<bool> verifyAndStartJob(String jobId, String scannedToken) async =>
      true;

  @override
  Future<String> generateCompletionToken(String jobId) async => 'token';

  @override
  Future<bool> verifyAndCompleteJob(String jobId, String scannedToken) async =>
      true;

  @override
  Stream<List<Map<String, dynamic>>> getJobsByCategory(String category) =>
      Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    debugPrint('MyMockJobService.noSuchMethod: ${invocation.memberName}');
    return super.noSuchMethod(invocation);
  }
}

// Additional Mocks for HomeScreen dependencies

class MockWalletService extends ChangeNotifier implements WalletService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFirestoreService implements FirestoreService {
  @override
  Stream<List<Map<String, dynamic>>> getJobsStream({String? currentUserId}) {
    return Stream.value([]);
  }

  @override
  Future<void> createJob(Map<String, dynamic> jobData) async {}

  @override
  Future<void> saveUserProfile(
    String uid,
    Map<String, dynamic> profileData,
  ) async {}

  @override
  Future<Map<String, dynamic>?> getUserProfile(String uid) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRatingService implements RatingService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLeaderboardService implements LeaderboardService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLocationService implements LocationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNotificationService implements NotificationService {
  @override
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return Stream.value([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCommunityService implements CommunityService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockChatService implements ChatService {
  @override
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return Stream.value([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCloudinaryService implements CloudinaryService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFriendService implements FriendService {
  @override
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream(String userId) {
    return Stream.value([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPaymentService extends ChangeNotifier implements PaymentService {
  @override
  Stream<List<Map<String, dynamic>>> getUserPaymentsStream(
    String userId, {
    bool asSeeker = true,
  }) {
    return Stream.value([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCategoryService implements CategoryService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRewardsService implements RewardsService {
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

class MockUserCredential implements UserCredential {
  @override
  final User? user;
  MockUserCredential({required this.user});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockAuthService mockAuthService;
  late MockUserService mockUserService;
  late MyMockJobService mockJobService;

  // Late initialize other mocks
  late MockWalletService mockWalletService;
  late MockFirestoreService mockFirestoreService;
  late MockRatingService mockRatingService;
  late MockLeaderboardService mockLeaderboardService;
  late MockLocationService mockLocationService;
  late MockNotificationService mockNotificationService;
  late MockCommunityService mockCommunityService;
  late MockChatService mockChatService;
  late MockCloudinaryService mockCloudinaryService;
  late MockFriendService mockFriendService;
  late MockCategoryService mockCategoryService;
  late MockRewardsService mockRewardsService;
  late MockPaymentService mockPaymentService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUserService = MockUserService();
    mockJobService = MyMockJobService();
    mockWalletService = MockWalletService();
    mockFirestoreService = MockFirestoreService();
    mockRatingService = MockRatingService();
    mockLeaderboardService = MockLeaderboardService();
    mockLocationService = MockLocationService();
    mockNotificationService = MockNotificationService();
    mockCommunityService = MockCommunityService();
    mockChatService = MockChatService();
    mockCloudinaryService = MockCloudinaryService();
    mockFriendService = MockFriendService();
    mockCategoryService = MockCategoryService();
    mockRewardsService = MockRewardsService();
    mockPaymentService = MockPaymentService();

    // Set default profile to avoid infinite loading
    mockUserService.setProfile({
      'uid': 'test_uid',
      'role': 'seeker', // Default, will be updated in tests or handled
      'name': 'Test User',
      'email': 'test@example.com',
      'photoUrl': null,
      'isOnline': false,
      'todaysEarnings': 0.0,
      'gigsCompleted': 0,
      'coins': 100,
    });
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ChangeNotifierProvider<WalletService>.value(value: mockWalletService),
        Provider<UserService>.value(value: mockUserService),
        Provider<JobService>.value(value: mockJobService),
        Provider<FirestoreService>.value(value: mockFirestoreService),
        Provider<RatingService>.value(value: mockRatingService),
        Provider<LeaderboardService>.value(value: mockLeaderboardService),
        Provider<LocationService>.value(value: mockLocationService),
        Provider<NotificationService>.value(value: mockNotificationService),
        Provider<CommunityService>.value(value: mockCommunityService),
        Provider<ChatService>.value(value: mockChatService),
        Provider<CloudinaryService>.value(value: mockCloudinaryService),
        Provider<FriendService>.value(value: mockFriendService),
        Provider<CategoryService>.value(value: mockCategoryService),
        Provider<RewardsService>.value(value: mockRewardsService),
        ChangeNotifierProvider<PaymentService>.value(value: mockPaymentService),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('Selecting "I need help" and logging in updates role to seeker', (
    WidgetTester tester,
  ) async {
    debugPrint('Starting test: Seeker Redirection');

    // Set screen size to avoid overflow
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(createWidgetUnderTest());

    // Verify "I need help" is selected by default
    expect(find.text('I need help'), findsOneWidget);

    debugPrint('Tapping "I need help"');
    await tester.tap(find.text('I need help'));
    await tester.pump();

    // Fill in email and password
    debugPrint('Entering credentials');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    // Tap Login
    debugPrint('Tapping Login');
    final loginButton = find.text('Login');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump(); // Start animation
    await tester.pump(
      const Duration(seconds: 1),
    ); // Wait for dialog (avoid pumpAndSettle due to spinner)

    // Tap OK on the Debug Dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle(); // Wait for navigation

    // Check for Seeker specific text
    expect(find.textContaining('What do you need'), findsWidgets);
    debugPrint('Test passed: Seeker Redirection');
  });

  testWidgets(
    'Selecting "I want to work" and logging in updates role to helper',
    (WidgetTester tester) async {
      debugPrint('Starting test: Helper Redirection');

      // Set screen size to avoid overflow
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap "I want to work"
      debugPrint('Tapping "I want to work"');
      await tester.tap(find.text('I want to work'));
      await tester.pumpAndSettle();

      // Fill in email and password
      debugPrint('Entering credentials');
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Tap Login
      debugPrint('Tapping Login');
      final loginButton = find.text('Login');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pump(); // Start animation
      await tester.pump(
        const Duration(seconds: 1),
      ); // Wait for dialog (avoid pumpAndSettle due to spinner)

      // Tap OK on the Debug Dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle(); // Wait for navigation

      // Verify we navigated to HomeScreen with isSeeker=false
      // HelperDashboardTab has "Dashboard"
      expect(find.text('Dashboard'), findsWidgets);
      debugPrint('Test passed: Helper Redirection');
    },
  );
}
