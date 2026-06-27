import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:freelancer/core/services/user_service.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService? userService;

  RatingService({this.userService});

  // In-memory cache for rating distributions to avoid redundant aggregation queries
  final Map<String, Future<Map<int, int>>> _distributionCache = {};

  // Invalidate distribution cache for a helper
  void _invalidateDistributionCache(String helperId) {
    _distributionCache.remove(helperId);
  }

  // Submit rating with validation
  Future<void> submitRating({
    required String helperId,
    required String seekerId,
    required String jobId,
    required int overallRating,
    required double communication,
    required double punctuality,
    required double quality,
    String? feedback,
    List<String>? tags,
    String? photoUrl,
  }) async {
    // Validate inputs
    if (helperId.isEmpty || seekerId.isEmpty || jobId.isEmpty) {
      throw ArgumentError('Helper ID, Seeker ID, and Job ID are required');
    }
    if (overallRating < 1 || overallRating > 5) {
      throw ArgumentError('Overall rating must be between 1 and 5');
    }
    if (communication < 1 ||
        communication > 5 ||
        punctuality < 1 ||
        punctuality > 5 ||
        quality < 1 ||
        quality > 5) {
      throw ArgumentError('All ratings must be between 1 and 5');
    }

    // Check for duplicate rating
    final existing = await _firestore
        .collection('ratings')
        .where('seekerId', isEqualTo: seekerId)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already rated this job');
    }

    // Create rating document
    await _firestore.collection('ratings').add({
      'helperId': helperId,
      'seekerId': seekerId,
      'jobId': jobId,
      'overallRating': overallRating,
      'communication': communication,
      'punctuality': punctuality,
      'quality': quality,
      'feedback': feedback?.trim(),
      'tags': tags ?? [],
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update helper's average rating
    _invalidateDistributionCache(helperId);
    await _updateHelperRating(helperId);
  }

  // Update helper's average rating
  Future<void> _updateHelperRating(String helperId) async {
    final ratingsSnapshot = await _firestore
        .collection('ratings')
        .where('helperId', isEqualTo: helperId)
        .get();

    if (ratingsSnapshot.docs.isEmpty) return;

    final ratings = ratingsSnapshot.docs
        .map((doc) => (doc.data()['overallRating'] as num).toInt())
        .toList();

    final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
    final reviewCount = ratings.length;

    // Simple approach: just update rating and reviewCount
    // Points are recalculated by LeaderboardService separately
    await _firestore.collection('users').doc(helperId).update({
      'rating': avgRating,
      'reviewCount': reviewCount,
    });
    userService?.invalidateCache(helperId);
  }

  // Get ratings for a helper
  Stream<List<Map<String, dynamic>>> getHelperRatings(String helperId) {
    return _firestore
        .collection('ratings')
        .where('helperId', isEqualTo: helperId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Get rating distribution (for profile page)
  Future<Map<int, int>> getRatingDistribution(String helperId) async {
    if (helperId.isEmpty) return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    // Return cached Future if it exists
    if (_distributionCache.containsKey(helperId)) {
      return _distributionCache[helperId]!;
    }

    // Basic cache eviction
    if (_distributionCache.length >= 100) {
      _distributionCache.clear();
    }

    final future = _fetchRatingDistribution(helperId);
    _distributionCache[helperId] = future;

    return future.catchError((e) {
      _distributionCache.remove(helperId);
      throw e;
    });
  }

  // Internal helper to fetch distribution from Firestore
  Future<Map<int, int>> _fetchRatingDistribution(String helperId) async {
    final ratingsSnapshot = await _firestore
        .collection('ratings')
        .where('helperId', isEqualTo: helperId)
        .get();

    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (final doc in ratingsSnapshot.docs) {
      final rating = (doc.data()['overallRating'] as num).toInt();
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return distribution;
  }

  // Check if user already rated this job
  Future<bool> hasUserRatedJob(String seekerId, String jobId) async {
    final snapshot = await _firestore
        .collection('ratings')
        .where('seekerId', isEqualTo: seekerId)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
