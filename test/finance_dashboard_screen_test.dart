import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/screens/finance_dashboard_screen.dart';

class MockUser implements User {
  @override
  final String uid = 'test_user_id';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  final User? _user;

  FakeAuthService([this._user]);

  @override
  User? get user => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFinanceService implements FinanceService {
  final List<FinanceTransaction> _transactions;
  final Budget? _budget;

  FakeFinanceService({
    List<FinanceTransaction>? transactions,
    Budget? budget,
  })  : _transactions = transactions ?? [],
        _budget = budget;

  @override
  Stream<List<FinanceTransaction>> getTransactionsStream(String userId) {
    return Stream.value(_transactions);
  }

  @override
  Stream<Budget?> getBudgetStream(String userId) {
    return Stream.value(_budget);
  }

  @override
  Future<void> clearAllFinancialData(String userId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final mockUser = MockUser();
  final now = DateTime.now();

  final testTransactions = [
    FinanceTransaction(
      id: 'tx1',
      userId: mockUser.uid,
      amount: 5000.0,
      type: TransactionType.income,
      category: 'Salary',
      date: now,
      description: 'Monthly Stipend',
    ),
    FinanceTransaction(
      id: 'tx2',
      userId: mockUser.uid,
      amount: 200.0,
      type: TransactionType.expense,
      category: 'Food',
      date: now,
      description: 'Lunch at Canteen',
      isRecurring: false,
    ),
    FinanceTransaction(
      id: 'tx3',
      userId: mockUser.uid,
      amount: 150.0,
      type: TransactionType.expense,
      category: 'Transport',
      date: now.subtract(const Duration(days: 1)),
      description: 'Bus Pass',
      isRecurring: false,
    ),
    FinanceTransaction(
      id: 'tx4',
      userId: mockUser.uid,
      amount: 1000.0,
      type: TransactionType.expense,
      category: 'Rent',
      date: now,
      description: 'Room Rent',
      isRecurring: true,
    ),
  ];

  final testBudget = Budget(
    userId: mockUser.uid,
    monthlyIncome: 10000.0,
    monthlyLimit: 6000.0,
    recurringExpenses: 1000.0,
    categoryLimits: {},
    savingsTargetPercent: 20.0,
  );

  Widget createWidgetUnderTest({
    required FakeAuthService authService,
    required FakeFinanceService financeService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<FinanceService>.value(value: financeService),
      ],
      child: MaterialApp(
        builder: (context, child) {
          Responsive.init(context);
          return child!;
        },
        home: const FinanceDashboardScreen(),
      ),
    );
  }

  testWidgets('Renders empty budget state when budget is null', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService(mockUser);
    final financeService = FakeFinanceService(
      transactions: [],
      budget: null,
    );

    await tester.pumpWidget(
      createWidgetUnderTest(
        authService: authService,
        financeService: financeService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Finance Assistant'), findsOneWidget);
    expect(find.text('Set Up Budget'), findsOneWidget);
  });

  testWidgets('Renders FinanceDashboardScreen with budget and metrics', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    final authService = FakeAuthService(mockUser);
    final financeService = FakeFinanceService(
      transactions: testTransactions,
      budget: testBudget,
    );

    await tester.pumpWidget(
      createWidgetUnderTest(
        authService: authService,
        financeService: financeService,
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar Title
    expect(find.text('Financial Assistant'), findsOneWidget);

    // Verify Metric Cards
    expect(find.text('Monthly Income'), findsOneWidget);
    expect(find.text('Fixed Expenses'), findsOneWidget);
    expect(find.text('Daily Budget Tracker'), findsOneWidget);
    expect(find.text('Financial Health Bar'), findsOneWidget);
    expect(find.text('Daily Spending Trend'), findsOneWidget);
    expect(find.text('Top Spending Categories'), findsOneWidget);
    expect(find.text('Daily Explorer'), findsOneWidget);

    // Verify Transactions in Daily Explorer
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Lunch at Canteen'), findsOneWidget);
  });
}
