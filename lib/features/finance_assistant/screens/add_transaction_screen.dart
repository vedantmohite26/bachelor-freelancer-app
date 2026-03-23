import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';

import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';
import 'package:uuid/uuid.dart';

import 'dart:async';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  // Core Fields
  TransactionType _type = TransactionType.expense;
  double _amount = 0;
  String _category = 'Food';
  String _description = '';
  DateTime _date = DateTime.now();

  // Advanced Fields
  PaymentMethod _paymentMethod = PaymentMethod.upi;
  bool _isRecurring = false;
  Frequency _frequency = Frequency.monthly;
  String _source = 'Salary';

  Stream<Budget?>? _budgetStream;
  Stream<List<FinanceTransaction>>? _transactionsStream;

  final List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Investment',
    'Freelance',
    'Other',
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Interest',
    'Gift',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      setState(() {
        _amount = double.tryParse(_amountController.text) ?? 0;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      final financeService = Provider.of<FinanceService>(
        context,
        listen: false,
      );
      _budgetStream = financeService.getBudgetStream(user.uid);
      _transactionsStream = financeService.getTransactionsStream(user.uid);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: StreamBuilder<Budget?>(
        stream: _budgetStream,
        builder: (context, budgetSnapshot) {
          return StreamBuilder<List<FinanceTransaction>>(
            stream: _transactionsStream,
            builder: (context, txSnapshot) {
              final budget = budgetSnapshot.data;
              final transactions = txSnapshot.data ?? [];
              final warning = _type == TransactionType.expense
                  ? _getBudgetWarning(budget, transactions)
                  : null;

              return SingleChildScrollView(
                padding: EdgeInsets.all(16.0.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTypeSelector(),
                      SizedBox(height: 24.h),
                      _buildAmountField(warning),
                      SizedBox(height: 16.h),
                      _buildCategoryDropdown(),
                      SizedBox(height: 16.h),
                      _buildDescriptionField(),
                      SizedBox(height: 16.h),
                      _buildDatePicker(),

                      Divider(height: 32.h),
                      Text(
                        'Details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 16.h),

                      _buildPaymentMethodDropdown(),
                      SizedBox(height: 16.h),
                      SwitchListTile(
                        title: const Text('Recurring Transaction?'),
                        activeThumbColor: Theme.of(context).primaryColor,
                        value: _isRecurring,
                        onChanged: (val) => setState(() => _isRecurring = val),
                      ),
                      if (_isRecurring) _buildFrequencyDropdown(),

                      if (_type == TransactionType.expense) ...[
                        SizedBox(height: 16.h),
                        // Removed Necessity and Mood selectors
                      ],

                      if (_type == TransactionType.income) ...[
                        SizedBox(height: 16.h),
                        TextFormField(
                          initialValue: _source,
                          decoration: const InputDecoration(
                            labelText: 'Income Source',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => _source = val ?? 'Other',
                        ),
                      ],

                      SizedBox(height: 32.h),
                      ElevatedButton(
                        onPressed: _submitTransaction,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          backgroundColor: _type == TransactionType.income
                              ? Theme.of(context).colorScheme.secondary
                              : (warning?.color ??
                                    Theme.of(context).colorScheme.error),
                          shadowColor: warning?.color.withValues(alpha: 0.5),
                          elevation: warning != null ? 8 : 2,
                        ),
                        child: Text(
                          'Save Transaction',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.white,
                            fontWeight: warning != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<TransactionType>(
      segments: const [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text('Expense'),
          icon: Icon(Icons.remove_circle_outline),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text('Income'),
          icon: Icon(Icons.add_circle_outline),
        ),
      ],
      selected: {_type},
      onSelectionChanged: (Set<TransactionType> newSelection) {
        setState(() {
          _type = newSelection.first;
          _category = _type == TransactionType.expense
              ? _expenseCategories.first
              : _incomeCategories.first;
        });
      },
    );
  }

  Widget _buildAmountField(_BudgetWarning? warning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
            border: const OutlineInputBorder(),
            focusedBorder: warning != null
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: warning.color, width: 2.w),
                  )
                : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) =>
              (value == null || double.tryParse(value) == null)
              ? 'Invalid amount'
              : null,
          onSaved: (value) => _amount = double.parse(value!),
        ),
        if (warning != null) ...[
          SizedBox(height: 8.h),
          _buildWarningChip(warning),
        ],
      ],
    );
  }

  _BudgetWarning? _getBudgetWarning(
    Budget? budget,
    List<FinanceTransaction> transactions,
  ) {
    if (budget == null || _amount <= 0) return null;

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final remainingDays = daysInMonth - now.day + 1;

    // 1. Monthly Savings Goal
    final monthlySavingsGoal =
        (budget.monthlyLimit * budget.savingsTargetPercent / 100);

    // 2. Max Spendable this month (Budget - Savings Goal)
    final maxSpendable = budget.monthlyLimit - monthlySavingsGoal;

    // 3. Spent So Far (Non-recurring only)
    final spentThisMonth = transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.date.month == now.month &&
              tx.date.year == now.year &&
              !tx.isRecurring,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final spentToday = transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day &&
              !tx.isRecurring,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final remainingSpendable = maxSpendable - spentThisMonth;
    final dailySpendLimit = remainingDays > 0
        ? (remainingSpendable / remainingDays)
        : 0.0;

    final projectedSpentToday = spentToday + _amount;
    final projectedSpentMonth = spentThisMonth + _amount;
    final projectedRemainingSpendable = maxSpendable - projectedSpentMonth;
    final projectedDailyProgress = dailySpendLimit > 0
        ? (projectedSpentToday / dailySpendLimit).clamp(0.0, 1.0)
        : 1.0;

    final isOverBudget = projectedSpentMonth > maxSpendable;
    final isOverDailyToday =
        projectedSpentToday > dailySpendLimit && !isOverBudget;
    final isHighSpending =
        projectedDailyProgress > 0.4 && !isOverDailyToday && !isOverBudget;

    if (isOverBudget) {
      return _BudgetWarning(
        message:
            '⚠️ Over budget by ₹${projectedRemainingSpendable.abs().toStringAsFixed(0)}! Cut spending to recover savings.',
        color: Colors.redAccent,
        icon: Icons.dangerous,
      );
    }

    if (isOverDailyToday) {
      return _BudgetWarning(
        message:
            '⚡ Spent ₹${(projectedSpentToday - dailySpendLimit).toStringAsFixed(0)} extra today. Tomorrow\'s limit will adjust.',
        color: Colors.orangeAccent,
        icon: Icons.warning_amber_rounded,
      );
    }

    if (isHighSpending) {
      return _BudgetWarning(
        message:
            '🟠 Careful! You\'ve used ${(projectedDailyProgress * 100).toStringAsFixed(0)}% of today\'s limit. Minimize non-essential expenses.',
        color: Colors.amber,
        icon: Icons.info_outline,
      );
    }

    return _BudgetWarning(
      message:
          '✅ On track! ₹${(dailySpendLimit - projectedSpentToday).toStringAsFixed(0)} left to spend today.',
      color: Colors.greenAccent.shade700,
      icon: Icons.check_circle_outline,
    );
  }

  Widget _buildWarningChip(_BudgetWarning warning) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: warning.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: warning.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(warning.icon, color: warning.color, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              warning.message,
              style: TextStyle(
                color: warning.color,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('category_$_type'), // Force rebuild when type changes
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      initialValue: _category,
      items:
          (_type == TransactionType.expense
                  ? _expenseCategories
                  : _incomeCategories)
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
      onChanged: (value) => setState(() => _category = value!),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        border: OutlineInputBorder(),
      ),
      onSaved: (value) => _description = value ?? '',
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: const Text('Date'),
      subtitle: Text("${_date.toLocal()}".split(' ')[0]),
      trailing: const Icon(Icons.calendar_today),
      tileColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _date = picked);
      },
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<PaymentMethod>(
      decoration: const InputDecoration(
        labelText: 'Payment Method',
        border: OutlineInputBorder(),
      ),
      initialValue: _paymentMethod,
      items: PaymentMethod.values
          .map(
            (e) =>
                DropdownMenuItem(value: e, child: Text(e.name.toUpperCase())),
          )
          .toList(),
      onChanged: (val) => setState(() => _paymentMethod = val!),
    );
  }

  Widget _buildFrequencyDropdown() {
    return DropdownButtonFormField<Frequency>(
      decoration: const InputDecoration(
        labelText: 'Frequency',
        border: OutlineInputBorder(),
      ),
      initialValue: _frequency,
      items: Frequency.values
          .map(
            (e) =>
                DropdownMenuItem(value: e, child: Text(e.name.toUpperCase())),
          )
          .toList(),
      onChanged: (val) => setState(() => _frequency = val!),
    );
  }

  // Removed _buildNecessitySelector and _buildMoodSelector

  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in')),
        );
        return;
      }

      final transaction = FinanceTransaction(
        id: const Uuid().v4(),
        userId: user.uid,
        amount: _amount,
        type: _type,
        category: _category,
        date: _date,
        description: _description,
        paymentMethod: _paymentMethod,
        isRecurring: _isRecurring,
        frequency: _frequency,
        source: _source,
      );

      final financeService = Provider.of<FinanceService>(
        context,
        listen: false,
      );
      final messenger = ScaffoldMessenger.of(context);

      // Optimistic UI: pop immediately, save in background
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Transaction saved ✓'),
          duration: Duration(seconds: 2),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });

      // Background write — show error snackbar only if it fails
      unawaited(
        financeService.addTransaction(transaction).catchError((e) {
          messenger.showSnackBar(
            SnackBar(content: Text('Save failed: $e. Please try again.')),
          );
        }),
      );
    }
  }
}

class _BudgetWarning {
  final String message;
  final Color color;
  final IconData icon;

  _BudgetWarning({
    required this.message,
    required this.color,
    required this.icon,
  });
}
