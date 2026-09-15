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
  final String _uid;
  FakeUser(this._uid);

  @override
  String get uid => _uid;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  final String? _uid;
  FakeAuthService([this._uid = 'user_1']);

  @override
  User? get user => _uid != null ? FakeUser(_uid) : null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLeaderboardService implements LeaderboardService {
  final List<Map<String, dynamic>> _data;
  FakeLeaderboardService(this._data);

  @override
  Stream<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) {
    return Stream.value(_data);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestableWidget({
    required AuthService authService,
    required LeaderboardService leaderboardService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<LeaderboardService>.value(value: leaderboardService),
      ],
      child: MaterialApp(
        builder: (context, child) {
          Responsive.init(context);
          return child!;
        },
        home: const LeaderboardScreen(),
      ),
    );
  }

  testWidgets('LeaderboardScreen displays podium and virtualized list items', (
    WidgetTester tester,
  ) async {
    final mockData = [
      {'id': 'user_1', 'name': 'Alice', 'points': 1000},
      {'id': 'user_2', 'name': 'Bob', 'points': 850},
      {'id': 'user_3', 'name': 'Charlie', 'points': 700},
      {'id': 'user_4', 'name': 'David', 'points': 550},
      {'id': 'user_5', 'name': 'Eve', 'points': 400},
    ];

    final fakeAuth = FakeAuthService('user_1');
    final fakeLeaderboard = FakeLeaderboardService(mockData);

    await tester.pumpWidget(
      buildTestableWidget(
        authService: fakeAuth,
        leaderboardService: fakeLeaderboard,
      ),
    );

    await tester.pump();

    // Verify Podium items (Top 3)
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);

    // Verify Rank 4 and 5 items in SliverList
    expect(find.text('#4'), findsOneWidget);
    expect(find.text('David'), findsOneWidget);
    expect(find.text('550 pts'), findsOneWidget);

    expect(find.text('#5'), findsOneWidget);
    expect(find.text('Eve'), findsOneWidget);
    expect(find.text('400 pts'), findsOneWidget);
  });

  testWidgets('LeaderboardScreen displays empty state when leaderboard is empty', (
    WidgetTester tester,
  ) async {
    final fakeAuth = FakeAuthService('user_1');
    final fakeLeaderboard = FakeLeaderboardService([]);

    await tester.pumpWidget(
      buildTestableWidget(
        authService: fakeAuth,
        leaderboardService: fakeLeaderboard,
      ),
    );

    await tester.pump();

    expect(find.text('No helpers found yet.'), findsOneWidget);
  });
}
