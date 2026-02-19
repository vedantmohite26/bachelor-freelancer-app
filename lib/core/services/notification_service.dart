import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:freelancer/core/services/local_notification_service.dart';
import 'dart:async';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  // Stream of notifications for a user
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('activity')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          // Check for new unread notifications to trigger local alert
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null && (data['isRead'] == false)) {
                debugPrint(
                  "DEBUG: New unread notification detected: ${data['title']}",
                );
                final timestamp = data['timestamp'];

                DateTime? notificationTime;
                if (timestamp is Timestamp) {
                  notificationTime = timestamp.toDate();
                } else if (timestamp is String) {
                  notificationTime = DateTime.tryParse(timestamp);
                }

                if (notificationTime != null) {
                  final now = DateTime.now();
                  final diff = now.difference(notificationTime).inSeconds.abs();

                  debugPrint("DEBUG: Notification time diff: ${diff}s");

                  if (diff < 60) {
                    debugPrint("DEBUG: Triggering local notification");
                    LocalNotificationService.showNotification(
                      id: change.doc.hashCode,
                      title: data['title'] ?? 'New Notification',
                      body: data['subtitle'] ?? 'You have a new update',
                      payload: change.doc.id,
                    );
                  } else {
                    debugPrint("DEBUG: Notification too old to trigger pop-up");
                  }
                } else {
                  debugPrint("DEBUG: Invalid or missing timestamp");
                }
              }
            }
          }

          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  // Start listening for notifications globally
  void listenForNotifications(String userId) {
    debugPrint("DEBUG: Starting global notification listener for $userId");
    _subscription?.cancel();
    _subscription = getUserNotifications(userId).listen(
      (_) {
        // The stream map transformation already handles the triggering.
        // We just need to keep the stream active.
      },
      onError: (e) {
        debugPrint("DEBUG: Global notification stream error: $e");
      },
    );
  }

  // Stop listening
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
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
