import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';
import 'package:freelancer/features/finance_assistant/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class PaymentService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generate a simulated UPI reference ID
  String _generateUpiRefId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final code = random.nextInt(999999).toString().padLeft(6, '0');
    return 'UPI$timestamp$code';
  }

  /// Create a payment record in Firestore and simulate UPI payment
  /// Returns the payment document ID on success
  Future<Map<String, dynamic>> simulateUPIPayment({
    required String jobId,
    required String seekerId,
    required String helperId,
    required double amount,
    required String jobTitle,
    String? helperName,
    String? helperUpiId,
  }) async {
    final upiRefId = _generateUpiRefId();

    // 1. Create payment record in 'pending' state
    final paymentRef = _db.collection('payments').doc();
    await paymentRef.set({
      'jobId': jobId,
      'seekerId': seekerId,
      'helperId': helperId,
      'amount': amount,
      'jobTitle': jobTitle,
      'helperName': helperName ?? 'Helper',
      'helperUpiId': helperUpiId ?? '$helperId@unnati',
      'upiRefId': upiRefId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Simulate UPI processing delay (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // 3. Execute atomic payment: update balances, job status, transactions
    final batch = _db.batch();

    // Update payment status → success
    batch.update(paymentRef, {
      'status': 'success',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Update job status → completed
    final jobRef = _db.collection('jobs').doc(jobId);
    batch.update(jobRef, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'paymentId': paymentRef.id,
      'paymentStatus': 'success',
      // Clean up completion tokens
      'completionToken': FieldValue.delete(),
      'completionTokenExpiresAt': FieldValue.delete(),
    });

    // Credit helper wallet + stats
    final helperRef = _db.collection('users').doc(helperId);
    batch.update(helperRef, {
      'walletBalance': FieldValue.increment(amount),
      'totalEarnings': FieldValue.increment(amount),
      'todaysEarnings': FieldValue.increment(amount),
      'gigsCompleted': FieldValue.increment(1),
      'points': FieldValue.increment(50), // 50 XP for completion
    });

    // Helper transaction record
    final helperTxnRef = helperRef.collection('transactions').doc();
    batch.set(helperTxnRef, {
      'title': 'Payment: $jobTitle',
      'amount': amount,
      'isCoin': false,
      'type': 'job_payment',
      'upiRefId': upiRefId,
      'relatedJobId': jobId,
      'paymentId': paymentRef.id,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Debit seeker wallet
    final seekerRef = _db.collection('users').doc(seekerId);
    batch.update(seekerRef, {'walletBalance': FieldValue.increment(-amount)});

    // Seeker transaction record
    final seekerTxnRef = seekerRef.collection('transactions').doc();
    batch.set(seekerTxnRef, {
      'title': 'Paid: $jobTitle',
      'amount': -amount,
      'isCoin': false,
      'type': 'job_payment',
      'upiRefId': upiRefId,
      'relatedJobId': jobId,
      'paymentId': paymentRef.id,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // --- AUTOMATED FINANCE TRACKING ---
    try {
      final financeService = FinanceService(); // Instantiate directly for now

      // 1. Log Expense for Seeker
      final seekerTransaction = FinanceTransaction(
        id: const Uuid().v4(),
        userId: seekerId,
        amount: amount,
        type: TransactionType.expense,
        category: 'Freelance',
        date: DateTime.now(),
        description: 'Payment for $jobTitle',
      );
      await financeService.addTransaction(seekerTransaction);

      // 2. Log Income for Helper
      final helperTransaction = FinanceTransaction(
        id: const Uuid().v4(),
        userId: helperId,
        amount: amount,
        type: TransactionType.income,
        category: 'Freelance',
        date: DateTime.now(),
        description: 'Earnings from $jobTitle',
      );
      await financeService.addTransaction(helperTransaction);
    } catch (e) {
      debugPrint('Error logging finance transaction: $e');
      // Don't fail the payment if tracking fails
    }
    // ----------------------------------

    debugPrint('Payment SUCCESS: $upiRefId for job $jobId (₹$amount)');

    return {
      'paymentId': paymentRef.id,
      'upiRefId': upiRefId,
      'amount': amount,
      'status': 'success',
    };
  }

  /// Get payment details by payment ID
  Future<Map<String, dynamic>?> getPayment(String paymentId) async {
    final doc = await _db.collection('payments').doc(paymentId).get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  /// Get all payments for a user (seeker or helper)
  Future<List<Map<String, dynamic>>> getUserPayments(
    String userId, {
    bool asSeeker = true,
  }) async {
    final field = asSeeker ? 'seekerId' : 'helperId';
    final snapshot = await _db
        .collection('payments')
        .where(field, isEqualTo: userId)
        .where('status', isEqualTo: 'success')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Get payments stream for a user
  Stream<List<Map<String, dynamic>>> getUserPaymentsStream(
    String userId, {
    bool asSeeker = true,
  }) {
    final field = asSeeker ? 'seekerId' : 'helperId';
    return _db
        .collection('payments')
        .where(field, isEqualTo: userId)
        .where('status', isEqualTo: 'success')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }
}
