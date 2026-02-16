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
}
