import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory static cache for user profiles
  // We store the Future directly so concurrent requests for the same user ID share the same future and avoid duplicate network calls.
  static final Map<String, Future<Map<String, dynamic>?>> _cache = {};

  // Invalidate a specific user profile cache entry
  static void invalidateCache(String userId) {
    _cache.remove(userId);
  }

  // Create user profile with search optimization and email uniqueness enforcement
  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
    required String role, // 'helper' or 'seeker'
    String? university,
    String? bio,
    List<String>? skills,
    String? phoneNumber,
  }) async {
    final batch = _firestore.batch();

    // Create searchable name tokens for better search
    final nameTokens = name.toLowerCase().split(RegExp(r'\s+'));

    // 1. Create the user profile
    final userDoc = _firestore.collection('users').doc(userId);
    batch.set(userDoc, {
      'name': name,
      'email': email,
      'role': role,
      'university': university,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'isOnline': false,
      'totalEarnings': 0.0,
      'todaysEarnings': 0.0,
      'gigsCompleted': 0,
      'rating': 0.0,
      'reviewCount': 0,
      'points': 0,
      'skills': skills ?? [],
      'skillsLower': skills?.map((s) => s.toLowerCase()).toList() ?? [],
      'nameTokens': nameTokens,
      'verifiedStudent': false,
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Create the email lookup entry (uniqueness enforced by rules)
    // We use the email as the document ID for constant time lookup
    final emailDoc = _firestore.collection('email_lookup').doc(email);
    batch.set(emailDoc, {
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Commit the batch
    await batch.commit();

    // Invalidate cache since profile has been created/updated
    invalidateCache(userId);
  }

  // Get user profile - Optimized with in-memory static caching
  Future<Map<String, dynamic>?> getUserProfile(String userId) {
    if (userId.isEmpty) return Future.value(null);

    // If already in cache, return a deep copy of the resolved data to prevent shared mutation issues
    if (_cache.containsKey(userId)) {
      return _cache[userId]!.then((data) => data != null ? Map<String, dynamic>.from(data) : null);
    }

    // Otherwise, fetch from Firestore and cache the future
    final Future<Map<String, dynamic>?> fetchFuture = _firestore
        .collection('users')
        .doc(userId)
        .get()
        .then((doc) {
          if (!doc.exists) return null;
          return {...doc.data()!, 'id': doc.id};
        })
        .catchError((error) {
          // If an error occurs, remove the future from the cache so subsequent requests can try again
          invalidateCache(userId);
          throw error;
        });

    _cache[userId] = fetchFuture;

    // Return deep copy
    return fetchFuture.then((data) => data != null ? Map<String, dynamic>.from(data) : null);
  }

  // Get user profile stream
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {...doc.data()!, 'id': doc.id};
    });
  }

  // Update online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await _firestore.collection('users').doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
    // Invalidate cache to reflect updated online status / last seen
    invalidateCache(userId);
  }

  // Get nearby helpers
  Stream<List<Map<String, dynamic>>> getNearbyHelpers({int limit = 10}) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'helper')
        .where('isOnline', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Optimized search using name tokens (server-side)
  Future<List<Map<String, dynamic>>> searchHelpers(String query) async {
    if (query.trim().isEmpty) {
      // Return top helpers if no query
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'helper')
          .orderBy('rating', descending: true)
          .limit(20)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    }

    final queryLower = query.toLowerCase();
    final tokens = queryLower.split(RegExp(r'\s+'));

    // Use array-contains-any for optimized search (max 10 tokens)
    final searchTokens = tokens.take(10).toList();

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'helper')
          .where('nameTokens', arrayContainsAny: searchTokens)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      // Fallback to client-side search if server-side fails
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'helper')
          .limit(50)
          .get();

      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final name = (data['name'] as String?)?.toLowerCase() ?? '';
            final skills =
                (data['skills'] as List?)
                    ?.map((s) => s.toString().toLowerCase())
                    .toList() ??
                [];

            return name.contains(queryLower) ||
                skills.any((skill) => skill.contains(queryLower));
          })
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    }
  }

  // Search user by email (exact match)
  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    if (email.trim().isEmpty) return null;

    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return {...doc.data(), 'id': doc.id};
    }
    return null;
  }

  // Search users by email prefix (real-time style)
  Future<List<Map<String, dynamic>>> searchUsersByEmailPrefix(
    String query,
  ) async {
    if (query.trim().isEmpty) return [];

    final searchTerm = query.trim();

    // Firestore prefix search pattern
    final snapshot = await _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: searchTerm)
        .where('email', isLessThan: '$searchTerm\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  // Update user skills with search optimization
  Future<void> updateSkills(String userId, List<String> skills) async {
    final skillsLower = skills.map((s) => s.toLowerCase()).toList();
    await _firestore.collection('users').doc(userId).update({
      'skills': skills,
      'skillsLower': skillsLower, // For optimized search
    });
    // Invalidate cache to reflect updated skills
    invalidateCache(userId);
  }

  // Update user profile
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Invalidate cache to reflect updated profile fields
    invalidateCache(userId);
  }

  // Reset daily earnings (should be called at midnight)
  Future<void> resetDailyEarnings(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'todaysEarnings': 0.0,
    });
    // Invalidate cache to reflect updated daily earnings
    invalidateCache(userId);
  }

  // Update safety settings
  Future<void> updateSafetySettings(
    String userId,
    Map<String, bool> settings,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'safetySettings': settings,
    });
    // Invalidate cache to reflect updated safety settings
    invalidateCache(userId);
  }

  // Add a trusted contact
  Future<void> addTrustedContact(
    String userId,
    Map<String, String> contact,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'trustedContacts': FieldValue.arrayUnion([contact]),
    });
    // Invalidate cache to reflect new trusted contact
    invalidateCache(userId);
  }

  // Remove a trusted contact
  Future<void> removeTrustedContact(
    String userId,
    Map<String, String> contact,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'trustedContacts': FieldValue.arrayRemove([contact]),
    });
    // Invalidate cache to reflect removed trusted contact
    invalidateCache(userId);
  }
}
