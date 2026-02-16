import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection Reference
  CollectionReference get _posts => _firestore.collection('posts');

  // Get real-time posts stream
  Stream<List<Map<String, dynamic>>> getPostsStream({int limit = 20}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data; // Return raw data, let UI handle parsing/models for now
          }).toList();
        });
  }

  // Create a new post
  Future<void> createPost({
    required String content,
    required String userId,
    required String userName,
    required bool isOfficial, // e.g. Student Council
  }) async {
    if (content.trim().isEmpty) throw Exception("Content cannot be empty");

    await _posts.add({
      'content': content.trim(),
      'authorId': userId,
      'authorName': userName,
      'isOfficial': isOfficial,
      'likes': 0,
      'comments': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Toggle Like (Simple implementation)
  Future<void> toggleLike(String postId, String userId) async {
    // In a real app, successful like tracking would be a subcollection 'likes'
    // For MVP/Optimization check: just increment/decrement
    // Logic: check valid ID then run transaction or optimistic update
    // We'll proceed with simple increment for now to ensure smoothness
    final docRef = _posts.doc(postId);
    await docRef.update({'likes': FieldValue.increment(1)});
  }
}
