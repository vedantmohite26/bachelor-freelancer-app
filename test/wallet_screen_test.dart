import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelancer/core/services/wallet_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/wallet/screens/wallet_screen.dart';

class MockAuthService extends ChangeNotifier implements AuthService {
  @override
  String? get currentUserUid => 'test_user';

  @override
  User? get user => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWalletService extends ChangeNotifier implements WalletService {
  @override
  double balance = 150.0;
  @override
  int coins = 50;
  @override
  List<Map<String, dynamic>> transactions = [
    {'title': 'Task Payment', 'amount': 100.0, 'isCoin': false},
    {'title': 'Bonus Coins', 'amount': 20.0, 'isCoin': true},
  ];

  @override
  void listenToWallet(String userId) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('WalletScreen renders properly with virtualized transaction list',
      (WidgetTester tester) async {
    final mockAuth = MockAuthService();
    final mockWallet = MockWalletService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuth),
          ChangeNotifierProvider<WalletService>.value(value: mockWallet),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const WalletScreen();
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("My Wallet"), findsOneWidget);
    expect(find.text("Earnings (Cash)"), findsOneWidget);
    expect(find.text("Recent Activity"), findsOneWidget);
    expect(find.text("Task Payment"), findsOneWidget);
    expect(find.text("Bonus Coins"), findsOneWidget);
  });
}
