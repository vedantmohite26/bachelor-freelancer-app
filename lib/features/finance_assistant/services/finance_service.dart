import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';
import 'package:freelancer/features/finance_assistant/models/financial_profile_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FinanceService();

  // --- Transaction Management ---

  Future<void> addTransaction(FinanceTransaction transaction) async {
    await _firestore
        .collection('users')
        .doc(transaction.userId)
        .collection('transactions')
        .add(transaction.toMap());
  }

  Stream<List<FinanceTransaction>> getTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FinanceTransaction.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  // --- Budget & Profile Management ---

  Future<void> setBudget(Budget budget) async {
    await _firestore
        .collection('users')
        .doc(budget.userId)
        .collection('finance_settings')
        .doc('budget')
        .set(budget.toMap());
  }

  Stream<Budget?> getBudgetStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('finance_settings')
        .doc('budget')
        .snapshots()
        .map((doc) => doc.exists ? Budget.fromMap(doc.data()!) : null);
  }

  Future<void> setFinancialProfile(FinancialProfile profile) async {
    await _firestore
        .collection('users')
        .doc(profile.userId)
        .collection('finance_settings')
        .doc('profile')
        .set(profile.toMap());
  }

  Stream<FinancialProfile?> getProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('finance_settings')
        .doc('profile')
        .snapshots()
        .map(
          (doc) => doc.exists ? FinancialProfile.fromMap(doc.data()!) : null,
        );
  }

  // --- AI & Analysis ---

  // --- AI & Analysis ---

  Future<List<FinanceTransaction>> analyzeBankStatement(
    File file,
    String userId,
  ) async {
    // Mock implementation for now
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing

    return [
      FinanceTransaction(
        id: 'temp_1',
        userId: userId,
        amount: 1500.0,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Grocery Store (Extracted)',
        paymentMethod: PaymentMethod.upi,
        necessity: Necessity.mustHave,
      ),
      FinanceTransaction(
        id: 'temp_2',
        userId: userId,
        amount: 5000.0,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime.now().subtract(const Duration(days: 5)),
        description: 'Monthly Salary (Extracted)',
        source: 'Salary',
      ),
    ];
  }

  Future<String> getAIAdvice(
    List<FinanceTransaction> transactions, {
    Budget? budget,
    FinancialProfile? profile,
  }) async {
    try {
      final message =
          "Please provide financial advice based on my recent transactions and profile.";
      final expensesSummary = _buildPrompt(transactions, budget, profile);

      // ---------------------------------------------------------
      // URL Configuration:
      // 1. Localhost (Android Emulator): "http://10.0.2.2:8000/finance-ai"
      // 2. Production (Render): "https://<your-service>.onrender.com/finance-ai"
      // ---------------------------------------------------------

      // TODO: Replace with your actual Render URL after deployment
      const String baseUrl = "http://10.0.2.2:8000";
      // const String baseUrl = "https://freelancer-finance-backend.onrender.com";

      final url = Uri.parse("$baseUrl/finance-ai");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message, "expenses": expensesSummary}),
      );

      if (response.statusCode == 200) {
        // The backend returns the raw text response directly (based on our python code)
        // or a JSON string if we returned json.
        // Our python code returns response.json() from HF or error dict.
        // Let's decode to be safe.
        final data = jsonDecode(response.body);
        return data.toString();
      } else {
        return "Failed to get advice. Server error: ${response.statusCode}";
      }
    } catch (e) {
      if (kDebugMode) {
        print("AI Backend Error: $e");
      }
      return "Error connecting to AI backend. Make sure the Python server is running.";
    }
  }

  String _buildPrompt(
    List<FinanceTransaction> transactions,
    Budget? budget,
    FinancialProfile? profile,
  ) {
    StringBuffer prompt = StringBuffer();

    // 1. User Profile Context
    if (profile != null) {
      prompt.writeln(
        "User Profile: Risk Appetite: ${profile.riskAppetite.name}, Short-term Goal: ₹${profile.shortTermGoalAmount}, Long-term Goal: ₹${profile.longTermGoalAmount}.",
      );
    }

    // 2. Budget Context
    if (budget != null) {
      prompt.writeln(
        "Monthly Budget Limit: ₹${budget.monthlyLimit}. Savings Target: ${budget.savingsTargetPercent}%.",
      );
    }

    prompt.writeln("Transactions:");

    // Limit to last 30 transactions
    final recent = transactions.take(30);
    for (var tx in recent) {
      String details =
          "- ${tx.type.name.toUpperCase()}: ${tx.amount} (${tx.category}) - ${tx.description}";
      if (tx.type == TransactionType.expense) {
        details += " [${tx.necessity.name}, ${tx.mood.name}]";
      }
      prompt.writeln(details);
    }

    return prompt.toString();
  }
}
