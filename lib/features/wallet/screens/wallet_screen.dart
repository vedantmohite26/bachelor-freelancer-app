import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      Provider.of<WalletService>(
        context,
        listen: false,
      ).listenToWallet(user.uid);
      Provider.of<WalletService>(
        context,
        listen: false,
      ).fetchTransactions(user.uid);
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. Balance Cards
            SizedBox(
              height: 180,
              child: Consumer<WalletService>(
                builder: (context, wallet, child) {
                  return PageView(
                    controller: PageController(viewportFraction: 0.9),
                    padEnds: false,
                    children: [
                      _BalanceCard(
                        title: "Earnings (Cash)",
                        amount: "₹${wallet.balance.toStringAsFixed(2)}",
                        color: AppTheme.growthGreen,
                        icon: Icons.attach_money,
                        buttonText: "Withdraw",
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _BalanceCard(
                        title: "Student Coins",
                        amount: "${wallet.coins} C",
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
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // 2. Recent Activity Section
            Row(
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
            const SizedBox(height: 8),

            Consumer<WalletService>(
              builder: (context, wallet, child) {
                if (wallet.transactions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No recent transactions"),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: wallet.transactions.length,
                  itemBuilder: (context, index) {
                    final txn = wallet.transactions[index];
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
                );
              },
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: textColor.withValues(alpha: 0.8), size: 28),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: textColor),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isPositive ? AppTheme.growthGreen : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
