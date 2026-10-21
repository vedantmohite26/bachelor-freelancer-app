import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/screens/add_transaction_screen.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'user123';
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  @override
  User? get user => FakeUser();

  @override
  bool get isAuthenticated => true;

  @override
  Future<UserCredential> signInWithEmailOnly(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signUpWithEmailOnly(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential?> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

class FakeFinanceService extends Fake implements FinanceService {
  int budgetListenCount = 0;
  int txListenCount = 0;

  final StreamController<Budget?> _budgetController =
      StreamController<Budget?>.broadcast();
  final StreamController<List<FinanceTransaction>> _txController =
      StreamController<List<FinanceTransaction>>.broadcast();

  FakeFinanceService() {
    _budgetController.onListen = () {
      budgetListenCount++;
      _budgetController.add(
        Budget(
          userId: 'user123',
          monthlyLimit: 10000,
          categoryLimits: {},
          savingsTargetPercent: 20,
        ),
      );
    };

    _txController.onListen = () {
      txListenCount++;
      _txController.add([]);
    };
  }

  @override
  Stream<Budget?> getBudgetStream(String userId) {
    return _budgetController.stream;
  }

  @override
  Stream<List<FinanceTransaction>> getTransactionsStream(String userId) {
    return _txController.stream;
  }

  @override
  Future<void> addTransaction(FinanceTransaction transaction) async {}
}

void main() {
  testWidgets('AddTransactionScreen renders correctly and caches streams across rebuilds', (
    WidgetTester tester,
  ) async {
    final fakeAuthService = FakeAuthService();
    final fakeFinanceService = FakeFinanceService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: fakeAuthService),
          Provider<FinanceService>.value(value: fakeFinanceService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const AddTransactionScreen();
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify UI components rendered
    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Save Transaction'), findsOneWidget);

    // Initial stream listen counts should be 1
    expect(fakeFinanceService.budgetListenCount, 1);
    expect(fakeFinanceService.txListenCount, 1);

    // Enter amount to trigger text field state changes
    final amountFinder = find.widgetWithText(TextFormField, 'Amount');
    await tester.enterText(amountFinder, '500');
    await tester.pumpAndSettle();

    // Stream listen count should remain 1 (no redundant stream re-subscriptions)
    expect(fakeFinanceService.budgetListenCount, 1);
    expect(fakeFinanceService.txListenCount, 1);

    // Toggle type to Income to trigger state update
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    // Stream listen count should still be 1
    expect(fakeFinanceService.budgetListenCount, 1);
    expect(fakeFinanceService.txListenCount, 1);
  });
}
