import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
            return data;
          }).toList();

          // In-memory sort by lastMessageTime descending
          chats.sort((a, b) {
            final aTime =
                (a['lastMessageTime'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                (b['lastMessageTime'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
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

    // Check if chat exists (This is a simplified check, optimized for cost)
    // In production, might store chatIds in user profile or use a composite ID
    final query = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(otherUserId)) {
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

    return doc.id;
  }
}
