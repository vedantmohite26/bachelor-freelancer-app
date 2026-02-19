import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:freelancer/core/services/notification_service.dart';

class PaymentService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

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

    // 5. Update job status → completed (Rewards will be added in a separate update below)
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

    // ----------------------------------

    // --- REWARD LOGIC ---
    int pointsEarned = 0;
    double coinsEarned = 0;

    try {
      // Fetch Job Details for Type
      final jobDoc = await _db.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data() ?? {};
      final jobType = jobData['jobType'] as String? ?? 'fixed';

      if (jobType == 'hourly') {
        // Hourly: 5 Coins/hr, 15 Points/hr
        // Rate is jobData['price']
        final hourlyRate = (jobData['price'] as num?)?.toDouble() ?? 10.0;
        final hoursWorked = amount / (hourlyRate > 0 ? hourlyRate : 1);

        coinsEarned = hoursWorked * 5;
        pointsEarned = (hoursWorked * 15).round();
      } else {
        // Fixed: 20 Coins, 50 Points
        coinsEarned = 20;
        pointsEarned = 50;
      }
    } catch (e) {
      debugPrint("Error calculating rewards: $e");
      // Fallback
      coinsEarned = 20;
      pointsEarned = 50;
    }
    // --------------------

    // Credit helper wallet + stats + rewards
    final helperRef = _db.collection('users').doc(helperId);
    batch.update(helperRef, {
      'walletBalance': FieldValue.increment(amount),
      'totalEarnings': FieldValue.increment(amount),
      'todaysEarnings': FieldValue.increment(amount),
      'gigsCompleted': FieldValue.increment(1),
      'points': FieldValue.increment(pointsEarned),
      'coins': FieldValue.increment(coinsEarned),
    });

    // ----------------------------------

    // Debit seeker wallet
    final seekerRef = _db.collection('users').doc(seekerId);
    batch.update(seekerRef, {'walletBalance': FieldValue.increment(-amount)});

    // ----------------------------------

    // Save reward summary to Job for the helper screen
    batch.update(jobRef, {
      'coinsEarned': coinsEarned,
      'pointsEarned': pointsEarned,
    });

    await batch.commit();

    // ----------------------------------

    debugPrint('Payment SUCCESS: $upiRefId for job $jobId (₹$amount)');

    // Notify Seeker (Debited)
    await _notificationService.createNotification(
      userId: seekerId,
      title: 'Payment Sent',
      subtitle: '₹$amount paid for "$jobTitle"',
      type: 'payment',
      relatedId: paymentRef.id,
    );

    // Notify Helper (Credited)
    await _notificationService.createNotification(
      userId: helperId,
      title: 'Payment Received! 💰',
      subtitle: 'You received ₹$amount for "$jobTitle"',
      type: 'payment',
      relatedId: paymentRef.id,
    );

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

  /// Get ALL payments for a user — both as seeker (expenses) and helper (earnings)
  /// Each payment is tagged with 'isIncoming' (true = earned, false = spent)
  Stream<List<Map<String, dynamic>>> getAllUserPaymentsStream(String userId) {
    final earnedStream = _db
        .collection('payments')
        .where('helperId', isEqualTo: userId)
        .where('status', isEqualTo: 'success')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => {...d.data(), 'id': d.id, 'isIncoming': true})
              .toList(),
        );

    final spentStream = _db
        .collection('payments')
        .where('seekerId', isEqualTo: userId)
        .where('status', isEqualTo: 'success')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => {...d.data(), 'id': d.id, 'isIncoming': false})
              .toList(),
        );

    // Merge both streams
    return earnedStream.asyncExpand((earned) {
      return spentStream.map((spent) {
        final all = [...earned, ...spent];
        // Sort by createdAt descending
        all.sort((a, b) {
          final aTime =
              (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime =
              (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });
        return all;
      });
    });
  }
}
