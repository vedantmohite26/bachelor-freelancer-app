import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:freelancer/features/finance_assistant/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
        .snapshots()
        .map((snapshot) {
          final txs = <FinanceTransaction>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            // Filter out internal coin transactions from the financial dashboard
            if (data['isCoin'] == true) continue;

            try {
              txs.add(FinanceTransaction.fromMap(doc.id, data));
            } catch (_) {
              // Skip malformed documents (e.g. legacy transactions with missing fields)
            }
          }
          txs.sort((a, b) => b.date.compareTo(a.date));
          return txs;
        });
  }

  Stream<List<FinanceTransaction>> getTransactionsStream(String userId) {
    return getTransactions(userId);
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  // --- Budget Management ---

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

  Future<void> clearAllFinancialData(String userId) async {
    // 1. Delete transactions in batches of 500 (Firestore limit)
    final collection = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');

    // Get first batch
    var snapshot = await collection.limit(500).get();

    while (snapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit batch
      await batch.commit();

      // Get next batch
      snapshot = await collection.limit(500).get();
    }

    // 2. Delete budget settings
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('finance_settings')
        .doc('budget')
        .delete();
  }

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

  String generateLocalAdvice(
    List<FinanceTransaction> transactions, {
    Budget? budget,
    String? userMessage,
  }) {
    if (transactions.isEmpty) {
      return "No. \nReason: I don't see any transactions yet. Start adding your income and expenses so I can help you.";
    }

    // --- 0. CONVERSATIONAL INTENTS (NLP-Lite) ---
    if (userMessage != null) {
      final lowerMsg = userMessage.toLowerCase().trim();

      // Greetings & Small Talk
      if ([
        'hi',
        'hello',
        'hey',
        'greetings',
        'start',
      ].any((w) => lowerMsg.startsWith(w))) {
        final greetings = [
          "Hello! I'm your Smart Financial Assistant. Ready to save some money today? 💰",
          "Hi there! How can I help you manage your wealth?",
          "Hey! I'm here to keep your budget on track. What's on your mind?",
        ];
        return greetings[DateTime.now().second % greetings.length];
      }

      if (lowerMsg.contains('how are you')) {
        return "I'm functioning perfectly and ready to help you save! How are your finances looking today?";
      }

      // Motivation / Quotes
      if (lowerMsg.contains('motivation') ||
          lowerMsg.contains('inspire') ||
          lowerMsg.contains('quote')) {
        final quotes = [
          "“Do not save what is left after spending, but spend what is left after saving.” – Warren Buffett",
          "“A budget is telling your money where to go instead of wondering where it went.” – Dave Ramsey",
          "“Beware of little expenses. A small leak will sink a great ship.” – Benjamin Franklin",
        ];
        return "💡 **Motivation**: ${quotes[DateTime.now().second % quotes.length]}";
      }

      // Tips
      if (lowerMsg.contains('tip') ||
          lowerMsg.contains('advice') ||
          lowerMsg.contains('trick')) {
        final tips = [
          "Try the 24-hour rule: Wait 24 hours before making any non-essential purchase.",
          "Cook at home more often. It's healthier for you and your wallet!",
          "Review your subscriptions. Cancel unused ones.",
        ];
        return "🌟 **Tip**: ${tips[DateTime.now().second % tips.length]}";
      }

      // Jokes
      if (lowerMsg.contains('joke')) {
        final jokes = [
          "Why did the banker break up with his girlfriend? He lost interest. 😂",
          "Why is money called dough? Because we all knead it!",
        ];
        return "😂 ${jokes[DateTime.now().second % jokes.length]}";
      }

      // Budget Planning / Help
      if (lowerMsg.contains('plan') && lowerMsg.contains('budget') ||
          lowerMsg.contains('help') && lowerMsg.contains('budget')) {
        // Calculate Average Monthly Income
        final incomeTx = transactions.where(
          (tx) => tx.type == TransactionType.income,
        );
        if (incomeTx.isEmpty) {
          return "I'd love to help you plan a budget! However, I don't see any income records yet. Please add your income transactions so I can calculate a personalized 50/30/20 budget for you.";
        }

        // Simple average (total income / unique months found) aka "Monthly Average" logic
        // For simplicity in this version, let's take the total absolute income / number of distinct months
        // or just sum of all income if history is short.
        // Let's stick to: Sum of all income / 1 (if less than a month) or real months.
        // ACTUALLY: Let's just look at specific recent income or assume the user inputs monthly income.
        // Better approach for safe MVP: Sum of THIS month's income.

        final now = DateTime.now();
        final currentMonthMx = transactions.where(
          (tx) => tx.date.year == now.year && tx.date.month == now.month,
        );

        final thisMonthIncome = currentMonthMx
            .where((tx) => tx.type == TransactionType.income)
            .fold(0.0, (prev, tx) => prev + tx.amount);

        if (thisMonthIncome == 0) {
          return "I can help you plan! To give a good recommendation, I need to know your income for this month. Please add an income transaction first.";
        }

        double needs = thisMonthIncome * 0.50;
        double wants = thisMonthIncome * 0.30;
        double savings = thisMonthIncome * 0.20;
        double limit = needs + wants;

        return "Based on your income this month (₹${thisMonthIncome.toStringAsFixed(0)}), here is a recommended 50/30/20 budget:\n\n"
            "• **Needs (50%)**: ₹${needs.toStringAsFixed(0)}\n"
            "• **Wants (30%)**: ₹${wants.toStringAsFixed(0)}\n"
            "• **Savings (20%)**: ₹${savings.toStringAsFixed(0)}\n\n"
            "I recommend setting your **Monthly Limit** to ₹${limit.toStringAsFixed(0)} and **Savings Target** to 20%.";
      }

      // Identity / Help
      if (lowerMsg.contains('who are you') ||
          lowerMsg.contains('what can you do') ||
          lowerMsg.contains('help')) {
        return "I am a rule-based financial assistant designed to helping you stay on budget. Ask me 'Plan my budget' for advice, or 'Can I spend 500?' to check affordability.";
      }

      // Gratitude
      if (lowerMsg.contains('thank')) {
        return "You're welcome! Stay financially healthy! 💰";
      }
    }

    final now = DateTime.now();

    final currentMonthMx = transactions.where(
      (tx) => tx.date.year == now.year && tx.date.month == now.month,
    );

    // Calculate Totals
    double totalSpent = 0;
    for (var tx in currentMonthMx) {
      if (tx.type == TransactionType.expense) {
        // Exclude recurring expenses from budget calculation
        if (!tx.isRecurring) {
          totalSpent += tx.amount;
        }
      }
    }

    // Default if no budget set
    if (budget == null) {
      return "No. \nReason: You haven't set a budget yet. Go to settings to set one up.";
    }

    double remainingBudget = budget.monthlyLimit - totalSpent;

    // --- PARSE USER MESSAGE FOR AMOUNT ---
    double? requestedAmount;

    if (userMessage != null) {
      final lowerMsg = userMessage.toLowerCase();
      // Simple regex to find the first number in the string
      final RegExp regExp = RegExp(r'[0-9]+(\.[0-9]+)?');
      final match = regExp.firstMatch(userMessage);
      if (match != null) {
        requestedAmount = double.tryParse(match.group(0)!);
      }

      // Check for explicit status words if no amount
      if (requestedAmount == null) {
        if (![
          'status',
          'health',
          'budget',
          'report',
          'analysis',
          'how am i',
          'doing',
        ].any((w) => lowerMsg.contains(w))) {
          // FALLBACK handled earlier? No, flow continues.
          // If we are here, it means it wasn't a greeting, wasn't a help command, has no number.
          // It might be "status". If NOT status, return help.
          return "I'm a specialist in finance, so I might not know about that! 😅\n\nBut I can help you with:\n• Checking affordability ('Can I spend 500?')\n• Budget Advice ('Plan my budget')\n• Motivation ('Give me a quote')\n\nTry asking me one of those!";
        }
      }
    }

    // --- 1. TIME OF DAY CHECK (Late Night Impulse) ---
    // Only trigger if money is involved (presumed spending request)
    if (requestedAmount != null && (now.hour >= 23 || now.hour < 5)) {
      return "No. \nReason: It is late at night (${now.hour}:${now.minute.toString().padLeft(2, '0')}). Late-night purchases are often impulsive. Sleep on it and decide tomorrow.";
    }

    // --- 2. BUDGET PACING CHECK ---
    // Calculate days passed percentage vs budget spent percentage
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    double timeRatio = now.day / daysInMonth;
    double spentRatio = totalSpent / budget.monthlyLimit;

    // If spending is significantly ahead of time (> 15% lead), warn.
    // Only apply this check broadly if we are not asking for a specific small amount that fits easily.

    // --- 3. AFFORDABILITY & BUFFER CHECK ---
    if (requestedAmount != null) {
      if (requestedAmount > remainingBudget) {
        double deficit = requestedAmount - remainingBudget;
        return "No. \nReason: You cannot afford this. It exceeds your remaining budget by ₹${deficit.toStringAsFixed(0)}.";
      }

      // Check if this purchase eats into the 10% safety buffer
      double buffer = budget.monthlyLimit * 0.10;
      double newRemaining = remainingBudget - requestedAmount;

      if (newRemaining < buffer && remainingBudget >= buffer) {
        return "No (Caution). \nReason: Buying this leaves you with only ₹${newRemaining.toStringAsFixed(0)}, which is less than your 10% safety buffer (₹${buffer.toStringAsFixed(0)}). Only proceed if essential.";
      }

      // Pacing warning for specific purchase
      if ((totalSpent + requestedAmount) / budget.monthlyLimit >
          timeRatio + 0.15) {
        return "No (Wait). \nReason: You are spending too fast. It's only day ${now.day}, but this purchase would push your spending to ${((totalSpent + requestedAmount) / budget.monthlyLimit * 100).toStringAsFixed(0)}% of the budget.";
      }

      // Behavioral check removed

      return "Yes. \nReason: You can afford this. You will have ₹${newRemaining.toStringAsFixed(0)} remaining.";
    }

    // --- GENERAL HEALTH CHECK (Explicit or Default if no message) ---
    if (totalSpent <= budget.monthlyLimit) {
      if (spentRatio > timeRatio + 0.15) {
        return "No (Slow Down). \nReason: You are spending faster than time passes. You've used ${(spentRatio * 100).toStringAsFixed(0)}% of budget by day ${now.day}.";
      }

      double usage = totalSpent / budget.monthlyLimit;
      if (usage > 0.9) {
        return "No (Caution). \nReason: You are very close to your limit (${(usage * 100).toStringAsFixed(0)}% used). Be careful.";
      }
      return "Yes. \nReason: You are on track. You have ₹${remainingBudget.toStringAsFixed(0)} left.";
    } else {
      double overspend = totalSpent - budget.monthlyLimit;
      return "No. \nReason: You have exceeded your monthly budget by ₹${overspend.toStringAsFixed(0)}.";
    }
  }

  Future<String> getAIAdvice(
    List<FinanceTransaction> transactions, {
    Budget? budget,
    String? userMessage,
    List<Map<String, String>>? history,
    String? appData, // New parameter for general app context
  }) async {
    try {
      // 1. Prepare Expenses String
      final expensesSummary = transactions
          .take(20)
          .map((tx) {
            return "${tx.date.toString().substring(0, 10)}: ${tx.type == TransactionType.income ? '+' : '-'} ${tx.amount} (${tx.category}) - ${tx.description}${tx.isRecurring ? ' (Recurring)' : ''}";
          })
          .join("\n");

      final recurringExpenses = transactions
          .where(
            (tx) =>
                tx.type == TransactionType.expense &&
                tx.date.month == DateTime.now().month &&
                tx.isRecurring,
          )
          .fold(0.0, (prev, tx) => prev + tx.amount);

      final budgetInfo = budget != null
          ? "Monthly Budget (Variable): ${budget.monthlyLimit}\nRecurring Expenses (Fixed): $recurringExpenses"
          : "No Budget Set";

      final dateTime = DateTime.now();
      // Truncate to hour precision to maximize backend cache hits
      final dateString = DateFormat('yyyy-MM-dd HH:00').format(dateTime);

      final fullData =
          "System Date/Time: $dateString\nUser Data:\n$budgetInfo\nRecent Transactions:\n$expensesSummary";

      // 2. Call Backend API
      // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
      final url = Uri.parse(
        'https://bachelor-freelancer-app.onrender.com/finance-ai',
      );
      // final url = Uri.parse('http://10.0.2.2:8000/finance-ai');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message':
                  userMessage ??
                  "Give me financial advice based on my spending.",
              'expenses': fullData,
              'history': history ?? [],
              'app_data': appData ?? "", // Send app data to backend
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // Decode JSON if response is JSON, but currently backend returns raw string (or check backend)
        // Backend `return response.choices[0].message.content` returns a string directly?
        // FastAPI returns JSON by default if dict, but here it might be just string.
        // Let's check backend main.py... it returns `response.choices[0].message.content` which is string.
        // FastAPI wraps strings in JSON string? No, it returns content-type application/json usually if returned from path op.
        // Actually `return "some string"` in FastAPI returns a JSON string "some string".
        // The Flutter result interpretation depends.
        // If I use `response.body`, it will be `"The advice string"`.
        // I should probably decode it if it's JSON string.

        final decoded = jsonDecode(response.body);
        if (decoded is String) return decoded;
        return response.body; // Fallback if not double encoded
      } else {
        debugPrint(
          "AI Backend Error: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("AI Connection Failed: $e");
    }

    // 3. Fallback to Local Logic
    return generateLocalAdvice(
      transactions,
      budget: budget,
      userMessage: userMessage,
    );
  }
}
