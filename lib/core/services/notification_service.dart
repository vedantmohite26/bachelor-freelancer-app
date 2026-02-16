import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of notifications for a user
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('activity')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  // Create a notification (Internal use or Cloud Function trigger)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String subtitle,
    required String type, // 'job', 'payment', 'message', 'system'
    String? relatedId, // jobId, senderId, etc.
  }) async {
    await _firestore.collection('activity').add({
      'userId': userId,
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'relatedId': relatedId,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('activity').doc(notificationId).update({
      'isRead': true,
    });
  }
}
