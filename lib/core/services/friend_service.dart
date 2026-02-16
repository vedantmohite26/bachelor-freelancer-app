import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendStatus { none, pendingSent, pendingReceived, connected }

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _requests => _firestore.collection('friend_requests');
  CollectionReference get _users => _firestore.collection('users');

  // Send friend request
  Future<void> sendFriendRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    if (currentUserId == targetUserId) return;

    // Check if request already exists
    final existingQuery = await _requests
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: targetUserId)
        .get();

    if (existingQuery.docs.isNotEmpty) return;

    await _requests.add({
      'senderId': currentUserId,
      'receiverId': targetUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancel sent request
  Future<void> cancelFriendRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    final query = await _requests
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: targetUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // Accept incoming request
  Future<void> acceptFriendRequest(String requestId) async {
    final doc = await _requests.doc(requestId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final senderId = data['senderId'];
    final receiverId = data['receiverId'];

    final batch = _firestore.batch();

    // Update request status
    batch.update(doc.reference, {'status': 'accepted'});

    // Add to each other's friend list (sub-collection or array - using sub-collection for scalability)
    final senderFriendRef = _users
        .doc(senderId)
        .collection('friends')
        .doc(receiverId);
    final receiverFriendRef = _users
        .doc(receiverId)
        .collection('friends')
        .doc(senderId);

    batch.set(senderFriendRef, {
      'friendId': receiverId,
      'connectedAt': FieldValue.serverTimestamp(),
    });

    batch.set(receiverFriendRef, {
      'friendId': senderId,
      'connectedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Cleanup request doc after acceptance (optional, or keep for history)
    await doc.reference.delete();
  }

  // Reject incoming request
  Future<void> rejectFriendRequest(String requestId) async {
    await _requests.doc(requestId).delete();
  }

  // Get status stream between two users
  Stream<FriendStatus> getFriendStatusStream(
    String currentUserId,
    String targetUserId,
  ) {
    if (currentUserId.isEmpty || targetUserId.isEmpty) {
      return Stream.value(FriendStatus.none);
    }

    // 1. Check if connected (friends)
    return _users
        .doc(currentUserId)
        .collection('friends')
        .doc(targetUserId)
        .snapshots()
        .asyncMap((friendDoc) async {
          if (friendDoc.exists) return FriendStatus.connected;

          // 2. Check if request sent by current user
          final sentQuery = await _requests
              .where('senderId', isEqualTo: currentUserId)
              .where('receiverId', isEqualTo: targetUserId)
              .where('status', isEqualTo: 'pending')
              .get();

          if (sentQuery.docs.isNotEmpty) return FriendStatus.pendingSent;

          // 3. Check if request received by current user
          final receivedQuery = await _requests
              .where('senderId', isEqualTo: targetUserId)
              .where('receiverId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'pending')
              .get();

          if (receivedQuery.docs.isNotEmpty) {
            return FriendStatus.pendingReceived;
          }

          return FriendStatus.none;
        });
  }

  // Get incoming requests stream for a user
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream(String userId) {
    return _requests
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = <Map<String, dynamic>>[];

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final senderId = data['senderId'];

            // Fetch sender details
            final senderDoc = await _users.doc(senderId).get();
            if (senderDoc.exists) {
              final senderData = senderDoc.data() as Map<String, dynamic>;
              requests.add({
                'requestId': doc.id,
                'senderId': senderId,
                'name': senderData['name'] ?? 'Unknown',
                'role': senderData['role'] ?? 'User', // university or role
                'university':
                    senderData['university'], // specific field if available
                'profilePic': senderData['profilePic'],
                'createdAt': data['createdAt'],
              });
            }
          }
          return requests;
        });
  }

  // Get sent requests stream for a user
  Stream<List<Map<String, dynamic>>> getSentRequestsStream(String userId) {
    return _requests
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = <Map<String, dynamic>>[];

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final receiverId = data['receiverId'];

            // Fetch receiver details
            final receiverDoc = await _users.doc(receiverId).get();
            if (receiverDoc.exists) {
              final receiverData = receiverDoc.data() as Map<String, dynamic>;
              requests.add({
                'requestId': doc.id,
                'receiverId': receiverId,
                'name': receiverData['name'] ?? 'Unknown',
                'role': receiverData['role'] ?? 'User',
                'university': receiverData['university'],
                'profilePic': receiverData['profilePic'],
                'createdAt': data['createdAt'],
              });
            } else {
              // Still show the request, but as "Unknown/Deleted User"
              requests.add({
                'requestId': doc.id,
                'receiverId': receiverId,
                'name': 'Unknown User',
                'role': 'User (Deleted?)',
                'university': null,
                'profilePic': null,
                'createdAt': data['createdAt'],
              });
            }
          }
          return requests;
        });
  }

  // Get friends list stream
  Stream<List<String>> getFriendIdsStream(String userId) {
    return _users.doc(userId).collection('friends').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Get friends with details stream
  Stream<List<Map<String, dynamic>>> getFriendsStream(String userId) {
    return _users.doc(userId).collection('friends').snapshots().asyncMap((
      snapshot,
    ) async {
      final friends = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final friendId = doc.id;
        final friendDoc = await _users.doc(friendId).get();

        if (friendDoc.exists) {
          final data = friendDoc.data() as Map<String, dynamic>;
          friends.add({
            'id': friendId,
            'name': data['name'] ?? 'Unknown',
            'email': data['email'] ?? '',
            'profilePic': data['profilePic'],
            'role': data['role'] ?? 'User',
            'university': data['university'],
          });
        }
      }
      return friends;
    });
  }

  // Check if two users are friends (for chat access control)
  Future<bool> areFriends(String userId1, String userId2) async {
    if (userId1.isEmpty || userId2.isEmpty) return false;

    final doc = await _users
        .doc(userId1)
        .collection('friends')
        .doc(userId2)
        .get();

    return doc.exists;
  }
}
