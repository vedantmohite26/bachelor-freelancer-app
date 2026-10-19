import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/leaderboard_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/features/community/screens/leaderboard_screen.dart';

class FakeAuthService extends Fake implements AuthService {
  @override
  User? get user => null;
}

class FakeLeaderboardService extends Fake implements LeaderboardService {
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  void emit(List<Map<String, dynamic>> data) {
    _controller.add(data);
  }

  @override
  Stream<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) {
    return _controller.stream;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthService fakeAuthService;
  late FakeLeaderboardService fakeLeaderboardService;

  setUp(() {
    Provider.debugCheckInvalidValueType = null;
    fakeAuthService = FakeAuthService();
    fakeLeaderboardService = FakeLeaderboardService();
  });

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: fakeAuthService),
        Provider<LeaderboardService>.value(value: fakeLeaderboardService),
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

  testWidgets('LeaderboardScreen renders empty state when no data returned', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(const LeaderboardScreen()));

    fakeLeaderboardService.emit([]);
    await tester.pumpAndSettle();

    expect(find.text("Leaderboard"), findsOneWidget);
    expect(find.text("No helpers found yet."), findsOneWidget);
  });

  testWidgets('LeaderboardScreen renders podium items and virtualized ranking list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(const LeaderboardScreen()));

    final demoLeaderboard = [
      {'id': '1', 'name': 'First Helper', 'points': 500},
      {'id': '2', 'name': 'Second Helper', 'points': 400},
      {'id': '3', 'name': 'Third Helper', 'points': 300},
      {'id': '4', 'name': 'Fourth Helper', 'points': 200},
      {'id': '5', 'name': 'Fifth Helper', 'points': 100},
    ];

    fakeLeaderboardService.emit(demoLeaderboard);
    await tester.pumpAndSettle();

    expect(find.text('First Helper'), findsOneWidget);
    expect(find.text('Second Helper'), findsOneWidget);
    expect(find.text('Third Helper'), findsOneWidget);
    expect(find.text('Fourth Helper'), findsOneWidget);
    expect(find.text('Fifth Helper'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('#3'), findsOneWidget);
    expect(find.text('#4'), findsOneWidget);
    expect(find.text('#5'), findsOneWidget);
  });
}
