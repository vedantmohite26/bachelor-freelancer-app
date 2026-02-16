import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';
import 'package:freelancer/features/finance_assistant/models/financial_profile_model.dart';
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

  // Profile Fields
  RiskAppetite _riskAppetite = RiskAppetite.balanced;
  double _shortTermGoal = 50000;
  double _longTermGoal = 1000000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Goals & Budget')),
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
              const SizedBox(height: 24),
              _buildSectionHeader('Investment Profile'),
              _buildRiskSelector(),
              const SizedBox(height: 24),
              _buildSectionHeader('Financial Goals'),
              _buildGoalInput(
                'Short Term Goal (1-2 yrs)',
                (val) => _shortTermGoal = double.parse(val),
                _shortTermGoal,
              ),
              const SizedBox(height: 12),
              _buildGoalInput(
                'Long Term Goal (5+ yrs)',
                (val) => _longTermGoal = double.parse(val),
                _longTermGoal,
              ),
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

  Widget _buildRiskSelector() {
    return DropdownButtonFormField<RiskAppetite>(
      initialValue: _riskAppetite,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: RiskAppetite.values
          .map(
            (e) =>
                DropdownMenuItem(value: e, child: Text(e.name.toUpperCase())),
          )
          .toList(),
      onChanged: (val) => setState(() => _riskAppetite = val!),
    );
  }

  Widget _buildGoalInput(
    String label,
    Function(String) onSaved,
    double initial,
  ) {
    return TextFormField(
      initialValue: initial.toString(),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onSaved: (val) => onSaved(val!),
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

      final profile = FinancialProfile(
        userId: user.uid,
        riskAppetite: _riskAppetite,
        shortTermGoalAmount: _shortTermGoal,
        longTermGoalAmount: _longTermGoal,
      );

      await Future.wait([
        financeService.setBudget(budget),
        financeService.setFinancialProfile(profile),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings Saved!')));
        Navigator.pop(context);
      }
    }
  }
}
