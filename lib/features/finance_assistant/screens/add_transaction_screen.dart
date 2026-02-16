import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

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
  Necessity _necessity = Necessity.mustHave;
  ExpenseMood _mood = ExpenseMood.neutral;
  String _source = 'Salary';

  bool _isLoading = false;

  final List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Investment',
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 24),
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildDatePicker(),

                    const Divider(height: 32),
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    _buildPaymentMethodDropdown(),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Recurring Transaction?'),
                      value: _isRecurring,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),
                    if (_isRecurring) _buildFrequencyDropdown(),

                    if (_type == TransactionType.expense) ...[
                      const SizedBox(height: 16),
                      _buildNecessitySelector(),
                      const SizedBox(height: 16),
                      _buildMoodSelector(),
                    ],

                    if (_type == TransactionType.income) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _source,
                        decoration: const InputDecoration(
                          labelText: 'Income Source',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => _source = val ?? 'Other',
                      ),
                    ],

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _type == TransactionType.income
                            ? Colors.green
                            : Colors.red,
                      ),
                      child: const Text(
                        'Save Transaction',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildAmountField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Amount',
        prefixText: '₹ ',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) => (value == null || double.tryParse(value) == null)
          ? 'Invalid amount'
          : null,
      onSaved: (value) => _amount = double.parse(value!),
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
      tileColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildNecessitySelector() {
    return DropdownButtonFormField<Necessity>(
      decoration: const InputDecoration(
        labelText: 'Was this necessary?',
        border: OutlineInputBorder(),
      ),
      initialValue: _necessity,
      items: Necessity.values
          .map(
            (e) =>
                DropdownMenuItem(value: e, child: Text(e.name.toUpperCase())),
          )
          .toList(),
      onChanged: (val) => setState(() => _necessity = val!),
    );
  }

  Widget _buildMoodSelector() {
    return DropdownButtonFormField<ExpenseMood>(
      decoration: const InputDecoration(
        labelText: 'Mood while spending',
        border: OutlineInputBorder(),
      ),
      initialValue: _mood,
      items: ExpenseMood.values
          .map(
            (e) =>
                DropdownMenuItem(value: e, child: Text(e.name.toUpperCase())),
          )
          .toList(),
      onChanged: (val) => setState(() => _mood = val!),
    );
  }

  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final user = Provider.of<AuthService>(context, listen: false).user;
        if (user == null) throw Exception('User not logged in');

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
          necessity: _necessity,
          mood: _mood,
          source: _source,
        );

        await Provider.of<FinanceService>(
          context,
          listen: false,
        ).addTransaction(transaction);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
