import 'package:cloud_firestore/cloud_firestore.dart';

class RewardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch rewards by category
  Stream<List<Map<String, dynamic>>> getRewards(String category) {
    return _firestore
        .collection('rewards')
        .where('category', isEqualTo: category)
        .orderBy('cost')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Seed Initial Data (For Demo/Setup)
  Future<void> seedRewards() async {
    final collection = _firestore.collection('rewards');

    // 1. Clear existing rewards to prevent duplicates
    final snapshot = await collection.get();
    final deleteBatch = _firestore.batch();
    for (final doc in snapshot.docs) {
      deleteBatch.delete(doc.reference);
    }
    await deleteBatch.commit();

    // 2. Add new rewards
    final createBatch = _firestore.batch();

    // ... Redeem Codes
    final redeemCodes = [
      {
        'title': 'Google Play ₹10',
        'subtitle': 'Digital Code',
        'cost': 1000,
        'category': 'redeem_code',
        'icon': 'play_arrow', // Mapped in UI
        'color': 0xFF4CAF50, // Green
      },
      {
        'title': 'Amazon ₹50',
        'subtitle': 'Gift Card',
        'cost': 4500,
        'category': 'redeem_code',
        'icon': 'shopping_cart',
        'color': 0xFFFF9800, // Orange
      },
      {
        'title': 'Flipkart ₹500',
        'subtitle': 'Shopping Voucher',
        'cost': 45000,
        'category': 'redeem_code',
        'icon': 'shopping_bag',
        'color': 0xFF2874F0, // Flipkart Blue
      },
      {
        'title': 'Myntra ₹1000',
        'subtitle': 'Fashion Card',
        'cost': 90000,
        'category': 'redeem_code',
        'icon': 'checkroom',
        'color': 0xFFE91E63, // Myntra Pink
      },
      {
        'title': 'Uber ₹250',
        'subtitle': 'Ride Voucher',
        'cost': 22000,
        'category': 'redeem_code',
        'icon': 'directions_car',
        'color': 0xFF000000, // Uber Black
      },
      {
        'title': 'BookMyShow ₹500',
        'subtitle': 'Movie Voucher',
        'cost': 45000,
        'category': 'redeem_code',
        'icon': 'movie',
        'color': 0xFFF44336, // Red
      },
      {
        'title': 'Spotify 1 Month',
        'subtitle': 'Premium Sub',
        'cost': 12000,
        'category': 'redeem_code',
        'icon': 'music_note',
        'color': 0xFF1DB954, // Spotify Green
      },
      {
        'title': 'Zomato ₹100',
        'subtitle': 'Food Voucher',
        'cost': 9000,
        'category': 'redeem_code',
        'icon': 'restaurant',
        'color': 0xFFE23744, // Zomato Red
      },
    ];

    // 2. Power-ups
    final powerUps = [
      {
        'title': 'Coins Boost (24h)',
        'subtitle': '2x Coins Outcome',
        'cost': 300,
        'category': 'power_up',
        'icon': 'monetization_on',
        'color': 0xFF2196F3, // Blue
      },

      {
        'title': 'XP Boost (24h)',
        'subtitle': '2x Points Outcome',
        'cost': 500,
        'category': 'power_up',
        'icon': 'bolt',
        'color': 0xFFFFEB3B, // Yellow
      },
      {
        'title': 'Highlight Profile',
        'subtitle': 'Stand out to Seekers',
        'cost': 2000,
        'category': 'power_up',
        'icon': 'verified',
        'color': 0xFF9C27B0, // Purple
      },
    ];

    // Add all to batch
    for (var item in [...redeemCodes, ...powerUps]) {
      final docRef = collection.doc(); // Auto-ID
      createBatch.set(docRef, item);
    }

    await createBatch.commit();
  }
}
