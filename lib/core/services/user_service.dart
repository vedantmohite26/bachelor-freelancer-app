import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
    invalidateCache(userId);
  }

  // Static in-memory cache for user profiles to prevent redundant Firestore fetches.
  // Storing the Future itself ensures that multiple concurrent calls for the same ID
  // (e.g., in a list of review cards) share the exact same network request.
  static final Map<String, Future<Map<String, dynamic>?>> _cache = {};

  // Invalidates the cache for a specific user ID to prevent serving stale data
  static void invalidateCache(String userId) {
    _cache.remove(userId);
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (userId.isEmpty) return null;

    if (_cache.containsKey(userId)) {
      try {
        final data = await _cache[userId]!;
        // Return a fresh deep copy of the cached resolved data.
        // This prevents parallel callers from sharing and mutating the same map reference.
        return data != null ? Map<String, dynamic>.from(data) : null;
      } catch (e) {
        // Cache contains a failed future, let's remove it and rethrow
        _cache.remove(userId);
        rethrow;
      }
    }

    // Wrap the async fetch in a future immediately so concurrent callers can share it
    final Future<Map<String, dynamic>?> fetchFuture = () async {
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (!doc.exists) return null;
        return {...doc.data()!, 'id': doc.id};
      } catch (e) {
        _cache.remove(userId);
        rethrow;
      }
    }();

    // Register a silent error handler synchronously on the cached future.
    // This prevents Dart's Zone system from treating failures as unhandled asynchronous errors
    // while we wait for other microtasks or callers to await the future.
    fetchFuture.catchError((_) => null);

    _cache[userId] = fetchFuture;

    try {
      final data = await fetchFuture;
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      _cache.remove(userId);
      rethrow;
    }
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
    invalidateCache(userId);
  }

  // Reset daily earnings (should be called at midnight)
  Future<void> resetDailyEarnings(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'todaysEarnings': 0.0,
    });
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
    invalidateCache(userId);
  }
}
