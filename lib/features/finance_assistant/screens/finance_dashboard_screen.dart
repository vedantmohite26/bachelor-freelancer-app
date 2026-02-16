import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';
import 'package:freelancer/features/finance_assistant/screens/add_transaction_screen.dart';
import 'package:freelancer/features/finance_assistant/screens/budget_setup_screen.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';
import 'package:intl/intl.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  int _touchedIndex = -1;
  Stream<List<FinanceTransaction>>? _transactionsStream;
  String? _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthService>(context).user;
    if (user != null && user.uid != _currentUserId) {
      _currentUserId = user.uid;
      _transactionsStream = Provider.of<FinanceService>(
        context,
        listen: false,
      ).getTransactions(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we have the user for other checks, but usage for stream is handled in didChangeDependencies
    final user = Provider.of<AuthService>(context).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetSetupScreen(),
                ),
              );
            },
            tooltip: 'Budget Settings',
          ),
        ],
      ),
      body: StreamBuilder<List<FinanceTransaction>>(
        stream: _transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];
          if (transactions.isEmpty) return _buildEmptyState();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBudgetStatus(user.uid, transactions),
                const SizedBox(height: 24),
                _buildSummaryCards(transactions),
                const SizedBox(height: 24),
                _buildBehavioralInsights(transactions),
                const SizedBox(height: 24),
                _buildChartSection(transactions),
                const SizedBox(height: 24),
                _buildRecentTransactions(transactions),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBudgetStatus(
    String userId,
    List<FinanceTransaction> transactions,
  ) {
    return StreamBuilder<Budget?>(
      stream: Provider.of<FinanceService>(
        context,
        listen: false,
      ).getBudgetStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Card(
            child: ListTile(
              title: const Text('Set up your Budget'),
              subtitle: const Text('Tap to set monthly limits and goals'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetSetupScreen(),
                ),
              ),
            ),
          );
        }

        final budget = snapshot.data!;
        double totalExpense = transactions
            .where(
              (tx) =>
                  tx.type == TransactionType.expense &&
                  tx.date.month == DateTime.now().month,
            )
            .fold(0, (sum, tx) => sum + tx.amount);

        final progress = (totalExpense / budget.monthlyLimit).clamp(0.0, 1.0);
        final isOverBudget = totalExpense > budget.monthlyLimit;

        return Card(
          color: isOverBudget ? Colors.red.shade50 : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Used',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: isOverBudget ? Colors.red : Colors.blue,
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Text(
                  'Spent: ₹${totalExpense.toStringAsFixed(0)} / ₹${budget.monthlyLimit.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (isOverBudget)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '⚠️ You have exceeded your monthly budget!',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBehavioralInsights(List<FinanceTransaction> transactions) {
    int impulseBuys = transactions
        .where((tx) => tx.mood == ExpenseMood.regretful)
        .length;
    int unnecessary = transactions
        .where((tx) => tx.necessity == Necessity.waste)
        .length;

    if (impulseBuys == 0 && unnecessary == 0) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Behavioral Insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (impulseBuys > 0)
              Text('⚠️ $impulseBuys "Regretful" purchases this month.'),
            if (unnecessary > 0)
              Text('⚠️ $unnecessary expenses marked as "Waste".'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text('No transactions yet', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              );
            },
            child: const Text('Add your first transaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<FinanceTransaction> transactions) {
    double income = 0;
    double expense = 0;

    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return Row(
      children: [
        Expanded(child: _buildCard('Income', income, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildCard('Expense', expense, Colors.red)),
      ],
    );
  }

  Widget _buildCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: '₹').format(amount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<FinanceTransaction> transactions) {
    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    for (var tx in transactions) {
      if (tx.type == TransactionType.expense) {
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0) + tx.amount;
      }
    }

    if (categoryTotals.isEmpty) return const SizedBox();

    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    int i = 0;
    categoryTotals.forEach((category, amount) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: amount,
          title:
              '${(amount / categoryTotals.values.reduce((a, b) => a + b) * 100).toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });

    return AspectRatio(
      aspectRatio: 1.3,
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Expense Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryTotals.entries.map((e) {
                final index = categoryTotals.keys.toList().indexOf(e.key);
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: colors[index % colors.length],
                    radius: 6,
                  ),
                  label: Text('${e.key}: ₹${e.value.toStringAsFixed(0)}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<FinanceTransaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...transactions
            .take(5)
            .map(
              (tx) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tx.type == TransactionType.income
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    child: Icon(
                      tx.type == TransactionType.income
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: tx.type == TransactionType.income
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  title: Text(tx.category),
                  subtitle: Text(tx.description),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tx.type == TransactionType.income ? '+' : '-'} ₹${tx.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: tx.type == TransactionType.income
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d').format(tx.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
