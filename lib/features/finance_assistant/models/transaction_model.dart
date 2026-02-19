import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

enum PaymentMethod { cash, upi, creditCard, debitCard, netBanking, other }

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

  // Income Specific
  final String source; // e.g., Salary, Freelance

  // App Generated Fields
  final bool isAppGenerated;
  final String? jobId;
  final bool isCoin;

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
    this.source = 'Other',
    this.isAppGenerated = false,
    this.jobId,
    this.isCoin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': type == TransactionType.expense ? -amount.abs() : amount.abs(),
      'type': type.toString().split('.').last,
      'category': category,
      'date': Timestamp.fromDate(date),
      'description': description,
      'receiptUrl': receiptUrl,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'isRecurring': isRecurring,
      'frequency': frequency.toString().split('.').last,
      'source': source,
      'isAppGenerated': isAppGenerated,
      'jobId': jobId,
      'isCoin': isCoin,
      'timestamp': Timestamp.fromDate(
        date,
      ), // Added for compatibility with WalletService
    };
  }

  factory FinanceTransaction.fromMap(String id, Map<String, dynamic> map) {
    final amount = (map['amount'] ?? 0.0).toDouble();
    final rawType = map['type']?.toString().toLowerCase() ?? '';

    // Determine type:
    // 1. If amount is negative, it's definitely an expense.
    // 2. If it's a known income type string and amount is positive, it's income.
    TransactionType type;
    if (amount < 0) {
      type = TransactionType.expense;
    } else if (rawType == 'income' ||
        rawType == 'job_payment' ||
        rawType == 'bonus') {
      type = TransactionType.income;
    } else {
      type = TransactionType.expense;
    }

    // Handle both 'date' and 'timestamp' fields
    DateTime transactionDate;
    if (map['date'] != null) {
      transactionDate = (map['date'] as Timestamp).toDate();
    } else if (map['timestamp'] != null) {
      transactionDate = (map['timestamp'] as Timestamp).toDate();
    } else {
      transactionDate = DateTime.now();
    }

    return FinanceTransaction(
      id: id,
      userId: map['userId'] ?? '',
      amount: amount.abs(),
      type: type,
      category: map['category'] ?? map['title'] ?? 'General',
      date: transactionDate,
      description: map['description'] ?? map['title'] ?? '',
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
      source: map['source'] ?? (rawType == 'job_payment' ? 'Job' : 'Other'),
      isAppGenerated: map['isAppGenerated'] ?? (rawType == 'job_payment'),
      jobId: map['jobId'],
      isCoin: map['isCoin'] ?? false,
    );
  }
}
