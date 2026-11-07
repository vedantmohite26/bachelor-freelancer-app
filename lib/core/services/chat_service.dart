import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:freelancer/core/services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  /// In-memory cache mapping two sorted participant user IDs to their chatId.
  /// Eliminates redundant Firestore queries across the app when opening chats.
  final Map<String, String> _chatIdCache = {};

  ChatService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService();

  /// Generates a normalized cache key for two user IDs regardless of argument order.
  static String _participantKey(String userA, String userB) {
    return userA.compareTo(userB) < 0 ? '$userA:$userB' : '$userB:$userA';
  }

  /// Clears in-memory chat cache (useful for testing or sign-out).
  void clearCache() {
    _chatIdCache.clear();
  }

  // Get stream of chats for a user
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;

            // Cache 2-participant chat IDs to accelerate subsequent createChat calls
            final participants = data['participants'];
            if (participants is List && participants.length == 2) {
              final p0 = participants[0]?.toString();
              final p1 = participants[1]?.toString();
              if (p0 != null && p1 != null && p0.isNotEmpty && p1.isNotEmpty) {
                _chatIdCache[_participantKey(p0, p1)] = doc.id;
              }
            }

            return data;
          }).toList();

          // Optimization: Directly compare Firestore Timestamps to eliminate
          // repeated DateTime allocations inside O(N log N) comparator iterations.
          chats.sort((a, b) {
            final aTs = a['lastMessageTime'] as Timestamp?;
            final bTs = b['lastMessageTime'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });

          return chats;
        });
  }

  // Get messages for a specific chat
  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    final batch = _firestore.batch();
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    final timestamp = FieldValue.serverTimestamp();

    // 1. Add message
    batch.set(messageRef, {
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
      'isRead': false,
    });

    // 2. Update chat metadata
    batch.update(chatRef, {
      'lastMessage': content,
      'lastMessageTime': timestamp,
      'lastSenderId': senderId,
    });

    await batch.commit();

    // 3. Notify recipient
    try {
      final chatDoc = await chatRef.get();
      if (chatDoc.exists) {
        final participants = List<String>.from(
          chatDoc.data()?['participants'] ?? [],
        );
        final recipientId = participants.firstWhere(
          (id) => id != senderId,
          orElse: () => '',
        );

        if (recipientId.isNotEmpty) {
          await _notificationService.createNotification(
            userId: recipientId,
            title: 'New Message',
            subtitle: content,
            type: 'message',
            relatedId: chatId,
          );
        }
      }
    } catch (e) {
      debugPrint("Error sending chat notification: $e");
    }
  }

  // Create or get existing chat between two users (only if friends)
  Future<String> createChat(
    String otherUserId,
    String currentUserId, {
    bool checkFriendship = true,
  }) async {
    // Check friendship if required
    if (checkFriendship) {
      final friendDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(otherUserId)
          .get();

      if (!friendDoc.exists) {
        throw Exception(
          'You can only chat with friends. Send a friend request first!',
        );
      }
    }

    final cacheKey = _participantKey(currentUserId, otherUserId);
    final cachedChatId = _chatIdCache[cacheKey];
    if (cachedChatId != null) {
      return cachedChatId;
    }

    // Check if chat exists (optimized for cost and read count)
    final query = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(otherUserId)) {
        _chatIdCache[cacheKey] = doc.id;
        return doc.id;
      }
    }

    // Create new
    final doc = await _firestore.collection('chats').add({
      'participants': [currentUserId, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _chatIdCache[cacheKey] = doc.id;
    return doc.id;
  }
}
