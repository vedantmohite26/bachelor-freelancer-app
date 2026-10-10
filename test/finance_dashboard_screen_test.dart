import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/screens/finance_dashboard_screen.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';

class FakeUser implements User {
  @override
  String get uid => 'test-user-id';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  final User _user = FakeUser();

  @override
  User? get user => _user;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFinanceService implements FinanceService {
  final List<FinanceTransaction> transactions;
  final Budget? budget;

  FakeFinanceService({required this.transactions, required this.budget});

  @override
  Stream<List<FinanceTransaction>> getTransactionsStream(String userId) {
    late StreamController<List<FinanceTransaction>> controller;
    controller = StreamController<List<FinanceTransaction>>.broadcast(
      onListen: () {
        controller.add(transactions);
      },
    );
    return controller.stream;
  }

  @override
  Stream<Budget?> getBudgetStream(String userId) {
    late StreamController<Budget?> controller;
    controller = StreamController<Budget?>.broadcast(
      onListen: () {
        controller.add(budget);
      },
    );
    return controller.stream;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Provider.debugCheckInvalidValueType = null;

  testWidgets('FinanceDashboardScreen renders calculated metrics and daily tracker',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final testTransactions = [
      FinanceTransaction(
        id: '1',
        userId: 'test-user-id',
        amount: 500.0,
        type: TransactionType.expense,
        category: 'Food',
        description: 'Lunch',
        date: now,
        isRecurring: false,
      ),
      FinanceTransaction(
        id: '2',
        userId: 'test-user-id',
        amount: 2000.0,
        type: TransactionType.income,
        category: 'Freelance',
        description: 'Design gig',
        date: now,
        isRecurring: false,
      ),
    ];

    final testBudget = Budget(
      userId: 'test-user-id',
      monthlyIncome: 50000.0,
      monthlyLimit: 20000.0,
      savingsTargetPercent: 20.0,
      recurringExpenses: 10000.0,
      categoryLimits: {'Food': 5000.0},
    );

    final fakeAuthService = FakeAuthService();
    final fakeFinanceService = FakeFinanceService(
      transactions: testTransactions,
      budget: testBudget,
    );

    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: fakeAuthService),
          Provider<FinanceService>.value(value: fakeFinanceService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const FinanceDashboardScreen();
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Financial Assistant'), findsOneWidget);
    expect(find.text('Daily Budget Tracker'), findsOneWidget);
    expect(find.text('Top Spending Categories'), findsOneWidget);
    expect(find.text('Food'), findsAtLeastNWidgets(1));
  });
}
