import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

enum PaymentMethod { cash, upi, creditCard, debitCard, netBanking, other }

enum ExpenseMood { happy, sad, stressed, neutral, excited, regretful }

enum Necessity { mustHave, niceToHave, waste }

enum Frequency { daily, weekly, monthly, yearly, oneTime }

class FinanceTransaction {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String description;
  final String? receiptUrl;

  // New Fields
  final PaymentMethod paymentMethod;
  final bool isRecurring;
  final Frequency frequency;

  // Expense Specific
  final Necessity necessity;
  final ExpenseMood mood;

  // Income Specific
  final String source; // e.g., Salary, Freelance

  FinanceTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.description,
    this.receiptUrl,
    this.paymentMethod = PaymentMethod.upi,
    this.isRecurring = false,
    this.frequency = Frequency.oneTime,
    this.necessity = Necessity.mustHave,
    this.mood = ExpenseMood.neutral,
    this.source = 'Other',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'category': category,
      'date': Timestamp.fromDate(date),
      'description': description,
      'receiptUrl': receiptUrl,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'isRecurring': isRecurring,
      'frequency': frequency.toString().split('.').last,
      'necessity': necessity.toString().split('.').last,
      'mood': mood.toString().split('.').last,
      'source': source,
    };
  }

  factory FinanceTransaction.fromMap(String id, Map<String, dynamic> map) {
    return FinanceTransaction(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: (map['type'] == 'income')
          ? TransactionType.income
          : TransactionType.expense,
      category: map['category'] ?? 'General',
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'] ?? '',
      receiptUrl: map['receiptUrl'],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == (map['paymentMethod'] ?? 'upi'),
        orElse: () => PaymentMethod.upi,
      ),
      isRecurring: map['isRecurring'] ?? false,
      frequency: Frequency.values.firstWhere(
        (e) => e.toString().split('.').last == (map['frequency'] ?? 'oneTime'),
        orElse: () => Frequency.oneTime,
      ),
      necessity: Necessity.values.firstWhere(
        (e) => e.toString().split('.').last == (map['necessity'] ?? 'mustHave'),
        orElse: () => Necessity.mustHave,
      ),
      mood: ExpenseMood.values.firstWhere(
        (e) => e.toString().split('.').last == (map['mood'] ?? 'neutral'),
        orElse: () => ExpenseMood.neutral,
      ),
      source: map['source'] ?? 'Other',
    );
  }
}
