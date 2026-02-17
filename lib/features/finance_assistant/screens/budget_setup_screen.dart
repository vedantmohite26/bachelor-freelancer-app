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

  // Budget Fields
  double _monthlyLimit = 10000;
  double _savingsTarget = 20;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentBudget();
  }

  Future<void> _loadCurrentBudget() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      final financeService = Provider.of<FinanceService>(
        context,
        listen: false,
      );
      final budget = await financeService.getBudgetStream(user.uid).first;
      if (budget != null) {
        setState(() {
          _monthlyLimit = budget.monthlyLimit;
          _savingsTarget = budget.savingsTargetPercent;
        });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Monthly Budget'),
              _buildBudgetSlider(),
              const SizedBox(height: 24),
              _buildSectionHeader('Savings Goal (%)'),
              _buildSavingsSlider(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBudgetSlider() {
    return Column(
      children: [
        Text(
          '₹${_monthlyLimit.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Slider(
          value: _monthlyLimit,
          min: 1000,
          max: 200000,
          divisions: 199,
          label: _monthlyLimit.round().toString(),
          onChanged: (value) => setState(() => _monthlyLimit = value),
        ),
      ],
    );
  }

  Widget _buildSavingsSlider() {
    return Column(
      children: [
        Text(
          '${_savingsTarget.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Slider(
          value: _savingsTarget,
          min: 0,
          max: 100,
          divisions: 100,
          label: _savingsTarget.round().toString(),
          onChanged: (value) => setState(() => _savingsTarget = value),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) return;

      final financeService = Provider.of<FinanceService>(
        context,
        listen: false,
      );

      final budget = Budget(
        userId: user.uid,
        monthlyLimit: _monthlyLimit,
        categoryLimits: {}, // Simplified for now
        savingsTargetPercent: _savingsTarget,
      );

      await financeService.setBudget(budget);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings Saved!')));
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    }
  }
}
