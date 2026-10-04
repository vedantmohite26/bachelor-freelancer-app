import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/rewards_service.dart';
import 'package:freelancer/core/services/wallet_service.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/wallet/screens/coin_shop_screen.dart';
import 'package:provider/provider.dart';

class FakeUser implements fb_auth.User {
  @override
  String get uid => 'test_user_123';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  final FakeUser _fakeUser = FakeUser();

  @override
  fb_auth.User? get user => _fakeUser;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWalletService extends ChangeNotifier implements WalletService {
  @override
  int get coins => 1500;

  @override
  void listenToWallet(String userId) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRewardsService implements RewardsService {
  int redeemCodeCalls = 0;
  int powerUpCalls = 0;

  final List<Map<String, dynamic>> sampleRedeemCodes = [
    {
      'id': '1',
      'title': 'Google Play ₹10',
      'subtitle': 'Digital Code',
      'cost': 1000,
      'category': 'redeem_code',
      'icon': 'play_arrow',
      'color': 0xFF4CAF50,
    },
  ];

  final List<Map<String, dynamic>> samplePowerUps = [
    {
      'id': '2',
      'title': 'Coins Boost (24h)',
      'subtitle': '2x Coins Outcome',
      'cost': 300,
      'category': 'power_up',
      'icon': 'bolt',
      'color': 0xFF2196F3,
    },
  ];

  @override
  Stream<List<Map<String, dynamic>>> getRewards(String category) {
    if (category == 'redeem_code') {
      redeemCodeCalls++;
      return Stream.multi((controller) {
        controller.add(sampleRedeemCodes);
      });
    } else {
      powerUpCalls++;
      return Stream.multi((controller) {
        controller.add(samplePowerUps);
      });
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('CoinShopScreen displays balance, tabs, items, and caches streams across rebuilds', (WidgetTester tester) async {
    final fakeAuthService = FakeAuthService();
    final fakeWalletService = FakeWalletService();
    final fakeRewardsService = FakeRewardsService();

    Widget buildTestableWidget({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: fakeAuthService),
          ChangeNotifierProvider<WalletService>.value(value: fakeWalletService),
          Provider<RewardsService>.value(value: fakeRewardsService),
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

    await tester.pumpWidget(
      buildTestableWidget(
        child: const RebuildHostWidget(),
      ),
    );
    await tester.pump();

    // Verify Title and Balance display
    expect(find.text('Earnify Shop'), findsOneWidget);
    expect(find.text('1500'), findsOneWidget);
    expect(find.text('Google Play ₹10'), findsOneWidget);

    // Initial stream subscription count should be 1 for each category
    expect(fakeRewardsService.redeemCodeCalls, equals(1));
    expect(fakeRewardsService.powerUpCalls, equals(1));

    // Switch to Power-ups tab
    await tester.tap(find.text('Power-ups'));
    await tester.pumpAndSettle();

    expect(find.text('Coins Boost (24h)'), findsOneWidget);

    // Trigger parent rebuild
    fakeWalletService.notifyListeners();
    await tester.pump();

    // Streams should be cached, so stream getters are NOT called again
    expect(fakeRewardsService.redeemCodeCalls, equals(1));
    expect(fakeRewardsService.powerUpCalls, equals(1));
  });
}

class RebuildHostWidget extends StatefulWidget {
  const RebuildHostWidget({super.key});

  @override
  State<RebuildHostWidget> createState() => _RebuildHostWidgetState();
}

class _RebuildHostWidgetState extends State<RebuildHostWidget> {
  @override
  Widget build(BuildContext context) {
    return const CoinShopScreen();
  }
}
