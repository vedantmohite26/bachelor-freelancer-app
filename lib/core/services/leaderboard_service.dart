import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get leaderboard (top helpers by points)
  Stream<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'helper')
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            return {...doc.data(), 'id': doc.id, 'rank': index + 1};
          }).toList(),
        );
  }

  // Get user's rank
  Future<int?> getUserRank(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return null;

    final userPoints = userDoc.data()?['points'] ?? 0;

    final higherRankedCount = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'helper')
        .where('points', isGreaterThan: userPoints)
        .count()
        .get();

    return higherRankedCount.count! + 1;
  }

  // Calculate points for user based on performance
  Future<void> recalculatePoints(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final gigsCompleted = data['gigsCompleted'] ?? 0;
    final rating = data['rating'] ?? 0.0;

    // Points = (gigsCompleted * 10) + (rating * 100)
    final totalPoints = (gigsCompleted * 10) + (rating * 100).toInt();

    await _firestore.collection('users').doc(userId).update({
      'points': totalPoints,
    });
  }

  // Get badges for user based on achievements
  List<String> getUserBadges(Map<String, dynamic> userData) {
    final badges = <String>[];
    final gigsCompleted = userData['gigsCompleted'] ?? 0;
    final rating = userData['rating'] ?? 0.0;
    final reviewCount = userData['reviewCount'] ?? 0;

    // Achievement badges
    if (gigsCompleted >= 50) badges.add('Veteran');
    if (gigsCompleted >= 100) badges.add('Legend');
    if (rating >= 4.8 && reviewCount >= 10) badges.add('Top Rated');
    if (rating == 5.0 && reviewCount >= 5) badges.add('Perfect');

    return badges;
  }

  // Generate 10 Demo Helpers (For Testing)
  Future<void> generateDemoHelpers() async {
    final batch = _firestore.batch();

    final demoUsers = [
      {'name': 'Arjun Singh', 'points': 2450, 'gigs': 52, 'rating': 4.9},
      {'name': 'Priya Patel', 'points': 2100, 'gigs': 45, 'rating': 4.8},
      {'name': 'Rahul Sharma', 'points': 1850, 'gigs': 38, 'rating': 4.7},
      {'name': 'Sneha Gupta', 'points': 1600, 'gigs': 30, 'rating': 4.6},
      {'name': 'Vikram Malhotra', 'points': 1450, 'gigs': 28, 'rating': 4.5},
      {'name': 'Anjali Desai', 'points': 1200, 'gigs': 22, 'rating': 4.8},
      {'name': 'Rohan Kumar', 'points': 950, 'gigs': 18, 'rating': 4.4},
      {'name': 'Kavita Reddy', 'points': 800, 'gigs': 15, 'rating': 4.3},
      {'name': 'Amit Verma', 'points': 650, 'gigs': 12, 'rating': 4.2},
      {'name': 'Neha Joshi', 'points': 500, 'gigs': 8, 'rating': 4.5},
    ];

    for (var i = 0; i < demoUsers.length; i++) {
      final user = demoUsers[i];
      final docRef = _firestore.collection('users').doc('demo_helper_$i');

      batch.set(docRef, {
        'name': user['name'],
        'email': 'demo$i@unnati.app',
        'role': 'helper',
        'points': user['points'],
        'gigsCompleted': user['gigs'],
        'rating': user['rating'],
        'walletBalance': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'isDemo': true, // Flag to easily identify/remove later
      });
    }

    await batch.commit();
  }
}
