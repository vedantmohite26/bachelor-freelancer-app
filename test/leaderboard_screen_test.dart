// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/leaderboard_service.dart';
import 'package:freelancer/features/community/screens/leaderboard_screen.dart';
import 'package:freelancer/core/utils/responsive.dart';

class FakeUser implements User {
  @override
  final String uid;
  FakeUser(this.uid);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService with ChangeNotifier implements AuthService {
  final FakeUser? _currentUser;
  FakeAuthService([this._currentUser]);

  @override
  User? get user => _currentUser;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLeaderboardService implements LeaderboardService {
  final List<Map<String, dynamic>> _data;
  FakeLeaderboardService(this._data);

  @override
  Stream<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) {
    return Stream.multi((controller) {
      controller.add(_data);
    });
  }

  @override
  Future<void> generateDemoHelpers() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('LeaderboardScreen renders top 3 podium items and virtualized ranking cards', (WidgetTester tester) async {
    final mockLeaderboardData = [
      {'id': '1', 'name': 'Alice Gold', 'points': 500},
      {'id': '2', 'name': 'Bob Silver', 'points': 400},
      {'id': '3', 'name': 'Charlie Bronze', 'points': 300},
      {'id': '4', 'name': 'David Fourth', 'points': 200},
      {'id': '5', 'name': 'Eve Fifth', 'points': 100},
    ];

    final fakeAuth = FakeAuthService(FakeUser('4')); // David is current user
    final fakeLeaderboard = FakeLeaderboardService(mockLeaderboardData);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: fakeAuth),
          Provider<LeaderboardService>.value(value: fakeLeaderboard),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const LeaderboardScreen();
            },
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Title
    expect(find.text('Leaderboard'), findsOneWidget);

    // Verify Podium Names
    expect(find.text('Alice Gold'), findsOneWidget);
    expect(find.text('Bob Silver'), findsOneWidget);
    expect(find.text('Charlie Bronze'), findsOneWidget);

    // Verify Rank 4 item
    expect(find.text('David Fourth'), findsOneWidget);
    expect(find.text('#4'), findsOneWidget);
  });

  testWidgets('LeaderboardScreen renders empty state when leaderboard data is empty', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService();
    final fakeLeaderboard = FakeLeaderboardService([]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: fakeAuth),
          Provider<LeaderboardService>.value(value: fakeLeaderboard),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const LeaderboardScreen();
            },
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('No helpers found yet.'), findsOneWidget);
  });
}
