import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Input Controllers
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _fixedExpensesController =
      TextEditingController();

  // Budget Fields
  double _monthlyLimit = 18000;
  double _savingsTargetPercent = 30;
  double _monthlyIncome = 50000;
  double _recurringExpenses = 20000;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentBudget();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _fixedExpensesController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentBudget() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      final financeService = Provider.of<FinanceService>(
        context,
        listen: false,
      );

      // Load Budget
      final budget = await financeService.getBudgetStream(user.uid).first;
      if (budget != null) {
        setState(() {
          _monthlyLimit = budget.monthlyLimit;
          _savingsTargetPercent = budget.savingsTargetPercent;
          _monthlyIncome = budget.monthlyIncome;
          _recurringExpenses = budget.recurringExpenses;

          _incomeController.text = _monthlyIncome.toStringAsFixed(0);
          _fixedExpensesController.text = _recurringExpenses.toStringAsFixed(0);
        });
      } else {
        _incomeController.text = _monthlyIncome.toStringAsFixed(0);
        _fixedExpensesController.text = _recurringExpenses.toStringAsFixed(0);
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final disposableIncome = (_monthlyIncome - _recurringExpenses).clamp(
      0.0,
      double.infinity,
    );
    final projectedFixedSavings = (disposableIncome - _monthlyLimit).clamp(
      0.0,
      double.infinity,
    );
    final targetSavings = _monthlyLimit * _savingsTargetPercent / 100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Financial Profile Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Income Input
              _buildInputField(
                label: 'Monthly Income',
                controller: _incomeController,
                onChanged: (val) {
                  setState(() {
                    _monthlyIncome = double.tryParse(val) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Fixed Expenses Input
              _buildInputField(
                label: 'Recurring Expenses (Fixed)',
                controller: _fixedExpensesController,
                onChanged: (val) {
                  setState(() {
                    _recurringExpenses = double.tryParse(val) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Disposable Income Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Disposable Income (Savings Potential)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${disposableIncome.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Divider(color: Theme.of(context).dividerColor, height: 1),
              const SizedBox(height: 30),

              // Budgeting & Goals Section
              Text(
                'Budgeting & Goals',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Allocate your disposable income into spending budget and savings.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 30),

              // Monthly Spending Budget Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Spending Budget',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEditDialog(
                      title: 'Monthly Spending Budget',
                      currentValue: _monthlyLimit,
                      suffix: '₹',
                      max: disposableIncome > 0 ? disposableIncome : 100000,
                      onSaved: (val) => setState(() => _monthlyLimit = val),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${_monthlyLimit.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _monthlyLimit.clamp(
                  0,
                  disposableIncome > 0 ? disposableIncome : 1.0,
                ),
                min: 0,
                max: disposableIncome > 0 ? disposableIncome : 1.0,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                onChanged: (val) => setState(() => _monthlyLimit = val),
              ),

              // Projected Fixed Savings Tag
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.savings,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Projected Fixed Savings: ₹${projectedFixedSavings.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Savings Goal Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Savings Goal (%)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEditDialog(
                      title: 'Savings Goal',
                      currentValue: _savingsTargetPercent,
                      suffix: '%',
                      max: 100,
                      onSaved: (val) =>
                          setState(() => _savingsTargetPercent = val),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_savingsTargetPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _savingsTargetPercent,
                min: 0,
                max: 100,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                onChanged: (val) => setState(() => _savingsTargetPercent = val),
              ),

              // Target Savings Text
              Center(
                child: Text(
                  'Target Savings: ₹${targetSavings.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Save Button
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog({
    required String title,
    required double currentValue,
    required String suffix,
    required double max,
    required Function(double) onSaved,
  }) async {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(0),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          'Edit $title',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                // visual clamp only, or allow override?
                // For now, clamp to safe ranges to avoid breaking sliders
                final clamped = val.clamp(0.0, max);
                onSaved(clamped);
              }
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user == null) return;

    final financeService = Provider.of<FinanceService>(context, listen: false);

    final budget = Budget(
      userId: user.uid,
      monthlyLimit: _monthlyLimit,
      categoryLimits: {},
      savingsTargetPercent: _savingsTargetPercent,
      monthlyIncome: _monthlyIncome,
      recurringExpenses: _recurringExpenses,
    );

    await financeService.setBudget(budget);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings Saved!')));
      Navigator.pop(context);
    }
  }
}
