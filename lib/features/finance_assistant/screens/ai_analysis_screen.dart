import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  File? _selectedFile;
  bool _isAnalyzing = false;
  String _aiAdvice = '';
  List<FinanceTransaction> _extractedTransactions = [];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'csv', 'txt'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _extractedTransactions = [];
        _aiAdvice = '';
      });
      _analyzeFile();
    }
  }

  Future<void> _analyzeFile() async {
    setState(() => _isAnalyzing = true);

    try {
      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) return;

      final financeService = Provider.of<FinanceService>(
        context,
        listen: false,
      );

      // 1. Analyze file (extract transactions)
      final transactions = await financeService.analyzeBankStatement(
        _selectedFile!,
        user.uid,
      );

      // 2. Get AI Advice based on extracted + existing transactions
      // We need to fetch budget and profile to pass to the AI
      final budgetStream = financeService.getBudgetStream(user.uid);
      final profileStream = financeService.getProfileStream(user.uid);

      final budget = await budgetStream.first;
      final profile = await profileStream.first;

      final advice = await financeService.getAIAdvice(
        transactions,
        budget: budget,
        profile: profile,
      );

      if (mounted) {
        setState(() {
          _extractedTransactions = transactions;
          _aiAdvice = advice;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error analyzing file: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Financial Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUploadSection(),
            const SizedBox(height: 24),
            if (_isAnalyzing)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_aiAdvice.isNotEmpty) _buildAdviceSection(),
              if (_extractedTransactions.isNotEmpty)
                _buildExtractedDataSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.upload_file, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Upload Bank Statement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supports PDF, CSV, TXT',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Select File'),
            ),
            if (_selectedFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Selected: ${_selectedFile!.path.split('/').last}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceSection() {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'AI Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(_aiAdvice),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Extracted Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _extractedTransactions.length,
          itemBuilder: (context, index) {
            final tx = _extractedTransactions[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  tx.type == TransactionType.income
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: tx.type == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                ),
                title: Text(tx.description),
                subtitle: Text(tx.category),
                trailing: Text(
                  '₹${tx.amount}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // In a real app, we would save these to Firestore here
            // Provider.of<FinanceService>(context, listen: false).addAll(transactions);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Transactions saved to your dashboard! (Simulated)',
                ),
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Confirm & Save to Dashboard'),
        ),
      ],
    );
  }
}
