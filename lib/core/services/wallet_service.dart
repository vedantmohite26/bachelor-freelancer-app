import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WalletService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Wallet Data
  double _balance = 0.0;
  int _coins = 0;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic> _activePowerUps = {};

  double get balance => _balance;
  int get coins => _coins;
  List<Map<String, dynamic>> get transactions => _transactions;
  Map<String, dynamic> get activePowerUps => _activePowerUps;

  // Stream listening to user wallet changes
  void listenToWallet(String userId) {
    _db.collection('users').doc(userId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        _balance = (data?['walletBalance'] as num? ?? 0.0).toDouble();
        _coins = (data?['coins'] as num? ?? 0).toInt();
        _activePowerUps = data?['activePowerUps'] ?? {};
        notifyListeners();
      }
    });
  }

  // Fetch Transaction History
  Future<void> fetchTransactions(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      _transactions = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
    }
  }

  // Add Transaction (Internal use mainly)
  Future<void> addTransaction({
    required String userId,
    required String title,
    required double amount, // Positive for earnings, negative for spending
    required bool isCoin, // True if coin transaction
    String? type, // 'job_payment', 'withdrawal', 'shop_purchase', 'bonus'
    String category = 'General',
    bool isAppGenerated = false,
  }) async {
    final batch = _db.batch();
    final userRef = _db.collection('users').doc(userId);
    final txnRef = userRef.collection('transactions').doc();

    // 1. Update User Balance
    if (isCoin) {
      batch.update(userRef, {'coins': FieldValue.increment(amount.toInt())});
    } else {
      batch.update(userRef, {'walletBalance': FieldValue.increment(amount)});
    }

    // 2. Add Transaction Record
    batch.set(txnRef, {
      'title': title,
      'amount': amount,
      'isCoin': isCoin,
      'type': type ?? 'general',
      'category': category,
      'isAppGenerated': isAppGenerated,
      'timestamp': FieldValue.serverTimestamp(),
      'date':
          FieldValue.serverTimestamp(), // Added for Finance Assistant compatibility
      'userId': userId,
    });

    await batch.commit();
  }

  // Withdraw Funds (Mock for now)
  Future<bool> withdrawFunds(String userId, double amount) async {
    if (_balance < amount) return false;

    await addTransaction(
      userId: userId,
      title: "Withdrawal to Bank",
      amount: -amount,
      isCoin: false,
      type: 'withdrawal',
      category: 'Freelance',
      isAppGenerated: true,
    );
    return true;
  }

  // Convert Coins (Example logic: Buy coupon)
  Future<bool> spendCoins(String userId, int cost, String itemName) async {
    if (_coins < cost) return false;

    await addTransaction(
      userId: userId,
      title: "Purchased: $itemName",
      amount: -cost.toDouble(),
      isCoin: true,
      type: 'shop_purchase',
      category: 'Freelance',
      isAppGenerated: true,
    );
    return true;
  }

  // Activate Power-Up
  Future<void> activatePowerUp(
    String userId,
    String powerUpType,
    Duration duration,
  ) async {
    final expiresAt = DateTime.now().add(duration);

    await _db.collection('users').doc(userId).update({
      'activePowerUps.$powerUpType': Timestamp.fromDate(expiresAt),
    });
  }
}
