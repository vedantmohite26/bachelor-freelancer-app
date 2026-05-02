import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/wallet_service.dart';
import 'package:freelancer/features/wallet/screens/coin_shop_screen.dart';

import 'package:freelancer/core/services/auth_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);

    // Listen for auth changes to init wallet
    final authService = Provider.of<AuthService>(context, listen: false);

    // Check if already logged in
    if (authService.user != null) {
      _initWallet(authService.user!.uid);
    }

    // Add listener for future updates
    authService.addListener(_authListener);
  }

  void _authListener() {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      _initWallet(user.uid);
    }
  }

  void _initWallet(String userId) {
    Provider.of<WalletService>(context, listen: false).listenToWallet(userId);
    Provider.of<WalletService>(
      context,
      listen: false,
    ).fetchTransactions(userId);
  }

  @override
  void dispose() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.removeListener(_authListener);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Bolt Optimization: Use context.select to narrow rebuild scope.
    // This ensures WalletScreen only rebuilds when relevant wallet data changes.
    final walletData = context.select<WalletService, Map<String, dynamic>>(
      (wallet) => {
        'balance': wallet.balance,
        'coins': wallet.coins,
        'transactions': wallet.transactions,
      },
    );

    final double balance = walletData['balance'];
    final int coins = walletData['coins'];
    final List<Map<String, dynamic>> transactions = walletData['transactions'];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "My Wallet",
          style: TextStyle(color: colorScheme.onSurface),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Full transaction history coming soon!'),
                ),
              );
            },
            tooltip: "Transaction History",
          ),
        ],
      ),
      // Bolt Optimization: Replaced SingleChildScrollView with CustomScrollView
      // to enable virtualization for the transaction list.
      // Expected Impact: Reduces initial build time from O(N) to O(visible)
      // and significantly lowers memory usage for long transaction histories.
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(24.w, 24.w, 24.w, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // 1. Balance Cards
                  SizedBox(
                    height: 180.h,
                    child: PageView(
                      controller: _pageController,
                      padEnds: false,
                      children: [
                        _BalanceCard(
                          title: "Earnings (Cash)",
                          amount: "₹${balance.toStringAsFixed(2)}",
                          color: AppTheme.growthGreen,
                          icon: Icons.attach_money,
                          buttonText: "Withdraw",
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Withdrawal feature coming soon!'),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 16.w),
                        _BalanceCard(
                          title: "Student Coins",
                          amount: "$coins C",
                          color: AppTheme.coinYellow,
                          icon: Icons.monetization_on_rounded, // Coin icon
                          buttonText: "Spend in Shop",
                          textColor: Colors.black, // Better contrast on yellow
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CoinShopScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // 2. Recent Activity Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Activity",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Full transaction history coming soon!'),
                            ),
                          );
                        },
                        child: const Text("See All"),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
          if (transactions.isEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0.w),
                  child: const Text("No recent transactions"),
                ),
              ),
            )
          else
            // Bolt Optimization: Replaced shrink-wrapped ListView with SliverList.
            // This enables virtualization where items are built/rendered only when visible.
            SliverPadding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final txn = transactions[index];
                    final amount = (txn['amount'] as num).toDouble();
                    final isCoin = txn['isCoin'] as bool? ?? false;
                    final isPositive = amount > 0;

                    return _TransactionItem(
                      title: txn['title'] ?? 'Unknown',
                      date: "Just now", // In real app, format timestamp
                      amount:
                          "${isPositive ? '+' : ''}${isCoin ? '' : '₹'}${amount.abs()}${isCoin ? ' C' : ''}",
                      isPositive: isPositive,
                      isCoin: isCoin,
                    );
                  },
                  childCount: transactions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;
  final String buttonText;
  final VoidCallback onTap;
  final Color textColor;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.buttonText,
    required this.onTap,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 16.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24.w),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: textColor.withValues(alpha: 0.8), size: 28.sp),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: textColor,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buttonText,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.arrow_forward_ios, size: 12.sp, color: textColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final bool isPositive;
  final bool isCoin;

  const _TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.isPositive,
    this.isCoin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCoin
                ? AppTheme.coinYellow.withValues(alpha: 0.1)
                : AppTheme.growthGreen.withValues(alpha: 0.1),
            child: Icon(
              isCoin ? Icons.star : Icons.attach_money,
              color: isCoin ? Colors.orange : AppTheme.growthGreen,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: isPositive ? AppTheme.growthGreen : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
