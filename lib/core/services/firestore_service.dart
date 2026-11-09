import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _jobs => _db.collection('jobs');

  // Optimization: specific streams/futures rather than fetching whole collections

  // Real-time Job Feed
  Stream<List<Map<String, dynamic>>> getJobsStream({String? currentUserId}) {
    // Optimization: Limit fetch size for faster loading
    return _jobs
        .where('status', isEqualTo: 'open') // Only show open jobs
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          // Single-pass list population avoiding intermediate iterable allocations
          // (.map().where().toList() creates multiple lazy wrappers and intermediate objects).
          final List<Map<String, dynamic>> results = [];
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (currentUserId != null && data['posterId'] == currentUserId) {
              continue;
            }
            results.add({
              ...data,
              'id': doc.id,
            });
          }
          return results;
        });
  }

  // Create Job
  Future<void> createJob(Map<String, dynamic> jobData) async {
    await _jobs.add({
      ...jobData,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }

  // User Profile Management
  Future<void> saveUserProfile(
    String uid,
    Map<String, dynamic> profileData,
  ) async {
    await _users.doc(uid).set(profileData, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }
}
