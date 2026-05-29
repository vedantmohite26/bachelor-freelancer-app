import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/community/screens/leaderboard_screen.dart';
import 'package:freelancer/core/services/leaderboard_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'leaderboard_screen_test.mocks.dart';

@GenerateMocks([LeaderboardService, AuthService])
void main() {
  late MockLeaderboardService mockLeaderboardService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockLeaderboardService = MockLeaderboardService();
    mockAuthService = MockAuthService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<LeaderboardService>.value(value: mockLeaderboardService),
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ],
        child: Builder(builder: (context) {
          Responsive.init(context);
          return const LeaderboardScreen();
        }),
      ),
    );
  }

  testWidgets('LeaderboardScreen displays data correctly with slivers', (WidgetTester tester) async {
    final mockData = [
      {'id': '1', 'name': 'User 1', 'points': 1000, 'rank': 1},
      {'id': '2', 'name': 'User 2', 'points': 900, 'rank': 2},
      {'id': '3', 'name': 'User 3', 'points': 800, 'rank': 3},
      {'id': '4', 'name': 'User 4', 'points': 700, 'rank': 4},
    ];

    when(mockLeaderboardService.getLeaderboard(limit: 50)).thenAnswer(
      (_) => Stream.value(mockData),
    );
    when(mockAuthService.user).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Start stream
    await tester.pump(const Duration(milliseconds: 100)); // Get stream data

    // Verify Podium items
    expect(find.text('User 1'), findsOneWidget);
    expect(find.text('User 2'), findsOneWidget);
    expect(find.text('User 3'), findsOneWidget);

    // Verify SliverList item
    expect(find.text('User 4'), findsOneWidget);
    expect(find.text('#4'), findsOneWidget);
    expect(find.text('700 pts'), findsOneWidget);

    // Verify CustomScrollView is present
    expect(find.byType(CustomScrollView), findsOneWidget);
  });
}
