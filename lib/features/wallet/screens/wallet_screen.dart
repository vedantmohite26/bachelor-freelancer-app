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
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _initWallet(_authService?.user?.uid);
    _authService?.addListener(_authListener);
  }

  void _authListener() {
    _initWallet(_authService?.user?.uid);
  }

  void _initWallet(String? userId) {
    if (userId == null) return;
    final walletService = Provider.of<WalletService>(context, listen: false);
    walletService.listenToWallet(userId);
    walletService.fetchTransactions(userId);
  }

  @override
  void dispose() {
    _authService?.removeListener(_authListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
      // ⚡ Bolt Optimization: Replace nested SingleChildScrollView + ListView.builder(shrinkWrap: true)
      // with CustomScrollView + SliverList for full viewport item virtualization and zero offscreen build overhead.
      body: Consumer<WalletService>(
        builder: (context, wallet, child) {
          final transactions = wallet.transactions;

          return CustomScrollView(
            slivers: [
              // 1. Balance Cards Header Section
              SliverPadding(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180.h,
                    child: PageView(
                      controller: PageController(viewportFraction: 0.9),
                      padEnds: false,
                      children: [
                        _BalanceCard(
                          title: "Earnings (Cash)",
                          amount: "₹${wallet.balance.toStringAsFixed(2)}",
                          color: AppTheme.growthGreen,
                          icon: Icons.attach_money,
                          buttonText: "Withdraw",
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Withdrawal feature coming soon!'),
                              ),
                            );
                          },
                        ),
                        _BalanceCard(
                          title: "Student Coins",
                          amount: "${wallet.coins} C",
                          color: AppTheme.coinYellow,
                          icon: Icons.monetization_on_rounded,
                          buttonText: "Spend in Shop",
                          textColor: Colors.black,
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
                ),
              ),

              // 2. Recent Activity Header Section
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Activity",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Full transaction history coming soon!'),
                            ),
                          );
                        },
                        child: const Text("See All"),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Virtualized Transaction List Section
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
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final txn = transactions[index];
                        final amount = (txn['amount'] as num).toDouble();
                        final isCoin = txn['isCoin'] as bool? ?? false;
                        final isPositive = amount > 0;

                        return _TransactionItem(
                          title: txn['title'] ?? 'Unknown',
                          date: "Just now",
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

              SliverPadding(padding: EdgeInsets.only(bottom: 24.h)),
            ],
          );
        },
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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: textColor.withValues(alpha: 0.8), size: 24.sp),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              color: textColor,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
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
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.arrow_forward_ios, size: 10.sp, color: textColor),
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
