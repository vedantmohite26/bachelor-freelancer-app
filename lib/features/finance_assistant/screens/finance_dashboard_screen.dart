import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/screens/add_transaction_screen.dart';
import 'package:freelancer/features/finance_assistant/screens/budget_setup_screen.dart';
import 'package:freelancer/features/finance_assistant/screens/ai_analysis_screen.dart';
import 'package:freelancer/core/widgets/shimmer_widgets.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  Stream<List<FinanceTransaction>>? _transactionsStream;
  DateTime _selectedDate = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      _transactionsStream = Provider.of<FinanceService>(
        context,
        listen: false,
      ).getTransactionsStream(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Financial Assistant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Reset Financial Data',
            onPressed: () => _showResetConfirmation(user.uid),
          ),
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
          ),
        ],
      ),
      body: StreamBuilder<List<FinanceTransaction>>(
        stream: _transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerFinanceDashboard();
          }
          final transactions = snapshot.data ?? [];

          return StreamBuilder<Budget?>(
            stream: Provider.of<FinanceService>(
              context,
              listen: false,
            ).getBudgetStream(user.uid),
            builder: (context, budgetSnapshot) {
              final budget = budgetSnapshot.data;

              if (budget == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to Finance Assistant',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set up your budget to start tracking your expenses and savings.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BudgetSetupScreen(),
                              ),
                            );
                          },
                          child: const Text('Set Up Budget'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildTopSummaryCard(budget, transactions),
                    const SizedBox(height: 16),
                    _buildSmartDailyBudgetCard(budget, transactions),
                    const SizedBox(height: 16),
                    _buildHealthBarCard(budget, transactions),
                    const SizedBox(height: 24),
                    _buildDailySpendingTrend(transactions),
                    const SizedBox(height: 24),
                    _buildIncomeSpentSummary(budget, transactions),
                    const SizedBox(height: 24),
                    _buildTopCategories(transactions),
                    const SizedBox(height: 32),
                    _buildDailyExplorer(transactions),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  Widget _buildTopSummaryCard(
    Budget? budget,
    List<FinanceTransaction> transactions,
  ) {
    final monthlyIncome = budget?.monthlyIncome ?? 0.0;
    final recurringExpenses = budget?.recurringExpenses ?? 0.0;

    final disposableIncome = (monthlyIncome - recurringExpenses).clamp(
      0.0,
      double.infinity,
    );
    final monthlyLimit = budget?.monthlyLimit ?? 18000.0;
    final savingsTargetPercent = budget?.savingsTargetPercent ?? 30.0;
    final goalSavings = (monthlyLimit * savingsTargetPercent / 100);
    final fixedSavings = (disposableIncome - monthlyLimit).clamp(
      0.0,
      double.infinity,
    );
    final totalProjectedSavings = goalSavings + fixedSavings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(
              context,
            ).colorScheme.secondaryContainer.withValues(alpha: 0.8),
            Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn(
                'Monthly Income',
                '₹${monthlyIncome.toStringAsFixed(0)}',
                Theme.of(context).colorScheme.onSurfaceVariant,
                Theme.of(context).colorScheme.secondary,
              ),
              _buildMetricColumn(
                'Fixed Expenses',
                '₹${recurringExpenses.toStringAsFixed(0)}',
                Theme.of(context).colorScheme.onSurfaceVariant,
                Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Theme.of(context).dividerColor),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn(
                'Fixed Savings',
                '₹${fixedSavings.toStringAsFixed(0)}',
                Theme.of(context).colorScheme.onSurfaceVariant,
                Theme.of(context).colorScheme.secondary,
              ),
              _buildMetricColumn(
                'Goal Savings',
                '₹${goalSavings.toStringAsFixed(0)}',
                Theme.of(context).colorScheme.onSurfaceVariant,
                Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saving Target',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${savingsTargetPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Projected Savings',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '₹${totalProjectedSavings.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  void _showResetConfirmation(String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          'Reset Financial Data',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'This will permanently delete all your transactions and budget settings. This action cannot be undone.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Provider.of<FinanceService>(
                  context,
                  listen: false,
                ).clearAllFinancialData(uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Financial data deleted successfully.'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting data: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartDailyBudgetCard(
    Budget? budget,
    List<FinanceTransaction> transactions,
  ) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = daysInMonth - now.day + 1;
    final elapsedDays = now.day;

    final monthlyLimit = budget?.monthlyLimit ?? 18000.0;
    final savingsTargetPercent = budget?.savingsTargetPercent ?? 30.0;

    // 1. Monthly Savings Goal
    final monthlySavingsGoal = (monthlyLimit * savingsTargetPercent / 100);

    // 2. Max Spendable this month (Budget - Savings Goal)
    final maxSpendable = monthlyLimit - monthlySavingsGoal;

    // 3. Spent So Far (Non-recurring only)
    final spentThisMonth = transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.date.month == now.month &&
              tx.date.year == now.year &&
              !tx.isRecurring,
        )
        .fold(0.0, (total, tx) => total + tx.amount);

    final spentToday = transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day &&
              !tx.isRecurring,
        )
        .fold(0.0, (total, tx) => total + tx.amount);

    // 4. Remaining Spendable
    final remainingSpendable = maxSpendable - spentThisMonth;

    // 5. Daily Spend Limit = Remaining / Days Left
    final dailySpendLimit = remainingDays > 0
        ? (remainingSpendable / remainingDays)
        : 0.0;

    // 6. Daily Savings Target
    // Formula: Goal Saving / Days Remaining
    // This tells the user how much they need to save per day from now on to hit the total monthly goal.
    final dailySavingsTarget = remainingDays > 0
        ? (monthlySavingsGoal / remainingDays)
        : 0.0;

    // UI Logic
    final isOverBudget = remainingSpendable < 0;
    final isOverDailyToday = spentToday > dailySpendLimit && !isOverBudget;
    final dailyProgress = dailySpendLimit > 0
        ? (spentToday / dailySpendLimit).clamp(0.0, 1.0)
        : 1.0;
    final isHighSpending =
        dailyProgress > 0.4 && !isOverDailyToday && !isOverBudget;

    // Status message
    String statusMessage;
    if (isOverBudget) {
      statusMessage =
          '⚠️ Over budget by ₹${remainingSpendable.abs().toStringAsFixed(0)}! Cut spending to recover savings.';
    } else if (isOverDailyToday) {
      statusMessage =
          '⚡ Spent ₹${(spentToday - dailySpendLimit).toStringAsFixed(0)} extra today. Tomorrow\'s limit will adjust.';
    } else if (isHighSpending) {
      statusMessage =
          '🟠 Careful! You\'ve used ${(dailyProgress * 100).toStringAsFixed(0)}% of today\'s limit. Minimize non-essential expenses.';
    } else if (spentToday == 0 && dailySpendLimit > 0) {
      statusMessage =
          '✨ No spending yet today. Full ₹${dailySpendLimit.toStringAsFixed(0)} available.';
    } else {
      statusMessage =
          '✅ On track! ₹${(dailySpendLimit - spentToday).toStringAsFixed(0)} left to spend today.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverBudget
              ? [
                  Theme.of(context).colorScheme.errorContainer,
                  Theme.of(
                    context,
                  ).colorScheme.errorContainer.withValues(alpha: 0.9),
                  Colors.redAccent.withValues(alpha: 0.2),
                ]
              : [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.surfaceContainerHigh,
                  Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer.withValues(alpha: 0.1),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: isOverBudget
            ? Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.3),
                width: 2,
              )
            : Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: isOverBudget
                ? Theme.of(context).colorScheme.error.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Budget Tracker',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.2)
                      : Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Day $elapsedDays / $daysInMonth',
                  style: TextStyle(
                    color: isOverBudget
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Two-column: Can Spend vs Must Save
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Can Spend',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${dailySpendLimit.clamp(0, double.infinity).toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'per day',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Must Save',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${dailySavingsTarget.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'per day',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Detail strip: Spent | Remaining | Days Left
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBudgetDetail(
                  'Spent',
                  '₹${spentThisMonth.toStringAsFixed(0)}',
                  Theme.of(context).colorScheme.error,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Theme.of(context).dividerColor,
                ),
                _buildBudgetDetail(
                  'Remaining',
                  '₹${remainingSpendable.clamp(0, double.infinity).toStringAsFixed(0)}',
                  Theme.of(context).colorScheme.primary,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Theme.of(context).dividerColor,
                ),
                _buildBudgetDetail(
                  'Days Left',
                  '$remainingDays',
                  Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Formula Breakdown for Transparency
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '(Pool: ₹${maxSpendable.toStringAsFixed(0)} - Spent: ₹${spentThisMonth.toStringAsFixed(0)}) ÷ $remainingDays Days = ₹${dailySpendLimit.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Today's progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Balance: ₹${(dailySpendLimit - spentToday).toStringAsFixed(0)}',
                style: TextStyle(
                  color: isOverDailyToday
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '₹${spentToday.toStringAsFixed(0)} / ₹${dailySpendLimit.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isOverBudget ? 1.0 : dailyProgress,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget
                    ? Theme.of(context).colorScheme.error
                    : isOverDailyToday
                    ? Theme.of(context).colorScheme.secondary
                    : isHighSpending
                    ? Colors.orangeAccent
                    : Theme.of(context).colorScheme.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          // Status message
          Text(
            statusMessage,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBarCard(
    Budget? budget,
    List<FinanceTransaction> transactions,
  ) {
    final now = DateTime.now();
    final monthlyLimit = budget?.monthlyLimit ?? 18000.0;
    final savingsTargetPercent = budget?.savingsTargetPercent ?? 30.0;

    final goalSavings = (monthlyLimit * savingsTargetPercent / 100);
    final recurringExpenses = budget?.recurringExpenses ?? 0.0;

    final spentThisMonthNonRecurring = transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.date.month == now.month &&
              tx.date.year == now.year &&
              !tx.isRecurring,
        )
        .fold(0.0, (total, tx) => total + tx.amount);

    final totalIncome =
        budget?.monthlyIncome ?? (recurringExpenses + monthlyLimit);

    final fixedSavings = (totalIncome - recurringExpenses - monthlyLimit).clamp(
      0.0,
      double.infinity,
    );

    // Total denominator
    final total =
        recurringExpenses +
        spentThisMonthNonRecurring +
        goalSavings +
        fixedSavings;
    final denominator = total > 0 ? total : 1.0;

    final fixedExpFrac = recurringExpenses / denominator;
    final spentFrac = spentThisMonthNonRecurring / denominator;
    final goalSavFrac = goalSavings / denominator;
    final fixedSavFrac = fixedSavings / denominator;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHigh,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Health Bar',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  if (fixedExpFrac > 0.01)
                    Expanded(
                      flex: (fixedExpFrac * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.error,
                              Colors.redAccent.shade100,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  if (spentFrac > 0.01)
                    Expanded(
                      flex: (spentFrac * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Colors.blueAccent.shade100,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  if (goalSavFrac > 0.01)
                    Expanded(
                      flex: (goalSavFrac * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.tertiary,
                              Colors.purpleAccent.shade100,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  if (fixedSavFrac > 0.01)
                    Expanded(
                      flex: (fixedSavFrac * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.secondary,
                              Colors.greenAccent.shade100,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                'Fixed Exp.',
                Theme.of(context).colorScheme.error,
              ),
              _buildLegendItem('Spent', Theme.of(context).colorScheme.primary),
              _buildLegendItem(
                'Goal Sav.',
                Theme.of(context).colorScheme.tertiary,
              ),
              _buildLegendItem(
                'Fixed Sav.',
                Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySpendingTrend(List<FinanceTransaction> transactions) {
    final now = DateTime.now();
    final List<double> dailySpending = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return transactions
          .where(
            (tx) =>
                tx.type == TransactionType.expense &&
                tx.date.day == date.day &&
                tx.date.month == date.month &&
                tx.date.year == date.year &&
                !tx.isRecurring,
          )
          .fold(0.0, (total, tx) => total + tx.amount);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Spending Trend',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:
                  (dailySpending.isEmpty
                          ? 100
                          : dailySpending.reduce((a, b) => a > b ? a : b)) *
                      1.2 +
                  100,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final day = now
                          .subtract(Duration(days: 6 - value.toInt()))
                          .day;
                      return Text(
                        '$day',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: dailySpending[i],
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeSpentSummary(
    Budget? budget,
    List<FinanceTransaction> transactions,
  ) {
    final now = DateTime.now();
    final monthlyLimit = budget?.monthlyLimit ?? 0.0;

    // Total income this month (including app earnings)
    final income = transactions
        .where(
          (tx) =>
              tx.type == TransactionType.income &&
              tx.date.month == now.month &&
              tx.date.year == now.year,
        )
        .fold(0.0, (total, tx) => total + tx.amount);

    // Total spent this month (non-recurring)
    final spent = transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.date.month == now.month &&
              tx.date.year == now.year &&
              !tx.isRecurring,
        )
        .fold(0.0, (total, tx) => total + tx.amount);

    final availableBudget = (monthlyLimit + income) - spent;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade400.withValues(alpha: 0.8),
                  Colors.cyan.shade300.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Budget',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${availableBudget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400.withValues(alpha: 0.8),
                  Colors.deepOrange.shade600.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${spent.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategories(List<FinanceTransaction> transactions) {
    final Map<String, double> categories = {};
    for (var tx in transactions.where(
      (tx) => tx.type == TransactionType.expense,
    )) {
      categories[tx.category] = (categories[tx.category] ?? 0.0) + tx.amount;
    }
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sortedCategories.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Spending Categories',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...top3.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final colors = [
            Colors.pinkAccent,
            Colors.amberAccent,
            Colors.tealAccent.shade400,
            Colors.indigoAccent,
            Colors.deepPurpleAccent,
          ];
          final dotColor = colors[i % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      e.key,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${e.value.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBudgetDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyExplorer(List<FinanceTransaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Explorer',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.calendar_month,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              tooltip: 'Pick a date',
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDatePickerMode: DatePickerMode.day,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: Theme.of(context).colorScheme.primary,
                          onPrimary: Theme.of(context).colorScheme.onPrimary,
                          surface: Theme.of(context).colorScheme.surface,
                          onSurface: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDateScroller(),
        _buildDailyTransactions(transactions),
      ],
    );
  }

  Widget _buildDateScroller() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30,
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: index));
          final isSelected =
              date.day == _selectedDate.day &&
              date.month == _selectedDate.month;
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        width: 2,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyTransactions(List<FinanceTransaction> transactions) {
    final dailyTx = transactions
        .where(
          (tx) =>
              tx.date.day == _selectedDate.day &&
              tx.date.month == _selectedDate.month &&
              tx.date.year == _selectedDate.year,
        )
        .toList();

    if (dailyTx.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No transactions for this day',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: dailyTx
          .map(
            (tx) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (tx.type == TransactionType.income
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.error)
                              .withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: tx.type == TransactionType.income
                      ? Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.25)
                      : Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.25),
                  child: Icon(
                    tx.type == TransactionType.income
                        ? Icons.add_circle
                        : Icons.remove_circle,
                    size: 20,
                    color: tx.type == TransactionType.income
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              title: Text(
                tx.category,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                tx.description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              trailing: Text(
                '${tx.type == TransactionType.income ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: tx.type == TransactionType.income
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: "ai_fab",
          backgroundColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIAnalysisScreen()),
            );
          },
          child: Icon(
            Icons.psychology,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: "add_fab",
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
      ],
    );
  }
}
