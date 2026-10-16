// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/friend_service.dart';

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(this.id, this._data);

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQueryDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> _data;

  FakeQueryDocumentSnapshot(this.id, this._data);

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => _data;

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      FakeDocumentReference(id, {}, {});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  FakeQuerySnapshot(this.docs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFriendDocumentReference implements DocumentReference<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, Map<String, dynamic>> friendsData;

  FakeFriendDocumentReference(this.id, this.friendsData);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    final data = friendsData[id];
    return FakeDocumentSnapshot(id, data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, Map<String, dynamic>> usersData;
  final Map<String, Map<String, dynamic>> friendsData;

  FakeDocumentReference(this.id, this.usersData, this.friendsData);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    final data = usersData[id];
    return FakeDocumentSnapshot(id, data);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'friends') {
      return FakeFriendsCollectionReference(id, friendsData, usersData);
    }
    return FakeCollectionReference('dummy', {}, usersData, {});
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    final isFriend = friendsData.containsKey(id);
    return Stream.value(
      FakeDocumentSnapshot(id, isFriend ? {'friendId': id} : null),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFriendsCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final String userId;
  final Map<String, Map<String, dynamic>> friendsData;
  final Map<String, Map<String, dynamic>> usersData;

  FakeFriendsCollectionReference(this.userId, this.friendsData, this.usersData);

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    final docs = friendsData.entries.map((e) {
      return FakeQueryDocumentSnapshot(e.key, e.value);
    }).toList();
    return Stream.value(FakeQuerySnapshot(docs));
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return FakeFriendDocumentReference(path ?? 'doc', friendsData);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final String collectionName;
  final Map<String, Map<String, dynamic>> requestsData;
  final Map<String, Map<String, dynamic>> usersData;
  final Map<String, Map<String, dynamic>> friendsData;
  final List<String> whereFilters;

  FakeCollectionReference(
    this.collectionName,
    this.requestsData,
    this.usersData,
    this.friendsData, [
    List<String>? filters,
  ]) : whereFilters = filters ?? [];

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    final filterKey = '$field=$isEqualTo';
    final newRef = FakeCollectionReference(
      collectionName,
      requestsData,
      usersData,
      friendsData,
      [...whereFilters, filterKey],
    );
    return newRef;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    final matchingDocs = _getMatchingDocs();
    return Stream.value(FakeQuerySnapshot(matchingDocs));
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    final matchingDocs = _getMatchingDocs();
    return FakeQuerySnapshot(matchingDocs);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _getMatchingDocs() {
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (var entry in requestsData.entries) {
      final data = entry.value;
      bool matches = true;

      for (var filter in whereFilters) {
        final parts = filter.split('=');
        final field = parts[0];
        final val = parts[1];
        if (data[field]?.toString() != val) {
          matches = false;
          break;
        }
      }

      if (matches) {
        docs.add(FakeQueryDocumentSnapshot(entry.key, data));
      }
    }
    return docs;
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return FakeDocumentReference(path ?? 'doc', usersData, friendsData);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      return this;
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeWriteBatch implements WriteBatch {
  final List<DocumentReference> deletedRefs = [];

  @override
  void delete(DocumentReference document) {
    deletedRefs.add(document);
  }

  @override
  Future<void> commit() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> requestsData;
  final Map<String, Map<String, dynamic>> usersData;
  final Map<String, Map<String, dynamic>> friendsData;
  late final FakeWriteBatch fakeBatch;

  FakeFirebaseFirestore({
    required this.requestsData,
    required this.usersData,
    required this.friendsData,
  }) {
    fakeBatch = FakeWriteBatch();
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    if (collectionPath == 'friend_requests') {
      return FakeCollectionReference(
        collectionPath,
        requestsData,
        usersData,
        friendsData,
      );
    } else if (collectionPath == 'users') {
      return FakeCollectionReference(
        collectionPath,
        requestsData,
        usersData,
        friendsData,
      );
    }
    return FakeCollectionReference(collectionPath, {}, {}, {});
  }

  @override
  WriteBatch batch() => fakeBatch;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FriendService Optimization & Concurrency Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FriendService friendService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore(
        requestsData: {
          'req_1': {
            'senderId': 'user_a',
            'receiverId': 'user_b',
            'status': 'pending',
            'createdAt': '2026-01-01',
          },
          'req_2': {
            'senderId': 'user_c',
            'receiverId': 'user_b',
            'status': 'pending',
            'createdAt': '2026-01-02',
          },
        },
        usersData: {
          'user_a': {
            'name': 'Alice',
            'role': 'Student',
            'university': 'MIT',
            'profilePic': 'alice.png',
          },
          'user_b': {
            'name': 'Bob',
            'role': 'Developer',
            'university': 'Stanford',
            'profilePic': 'bob.png',
          },
          'user_c': {
            'name': 'Charlie',
            'role': 'Designer',
            'university': 'Harvard',
            'profilePic': 'charlie.png',
          },
          'friend_1': {
            'name': 'Alice',
            'email': 'alice@example.com',
            'profilePic': 'alice.png',
            'role': 'Student',
            'university': 'MIT',
          },
        },
        friendsData: {
          'friend_1': {
            'friendId': 'friend_1',
            'connectedAt': '2026-01-01',
          },
        },
      );

      friendService = FriendService(firestore: fakeFirestore);
    });

    test('getIncomingRequestsStream maps sender details concurrently', () async {
      final stream = friendService.getIncomingRequestsStream('user_b');
      final requests = await stream.first;

      expect(requests.length, equals(2));
      expect(requests[0]['senderId'], equals('user_a'));
      expect(requests[0]['name'], equals('Alice'));
      expect(requests[0]['university'], equals('MIT'));

      expect(requests[1]['senderId'], equals('user_c'));
      expect(requests[1]['name'], equals('Charlie'));
    });

    test('getSentRequestsStream maps receiver details concurrently', () async {
      final stream = friendService.getSentRequestsStream('user_a');
      final requests = await stream.first;

      expect(requests.length, equals(1));
      expect(requests[0]['receiverId'], equals('user_b'));
      expect(requests[0]['name'], equals('Bob'));
    });

    test('getFriendsStream maps friend profiles concurrently', () async {
      final stream = friendService.getFriendsStream('user_b');
      final friends = await stream.first;

      expect(friends.length, equals(1));
      expect(friends[0]['id'], equals('friend_1'));
      expect(friends[0]['name'], equals('Alice'));
    });

    test('cancelFriendRequest uses batch delete', () async {
      await friendService.cancelFriendRequest('user_a', 'user_b');
      expect(fakeFirestore.fakeBatch.deletedRefs.length, equals(1));
    });

    test('areFriends checks friendship status correctly', () async {
      final areFriends = await friendService.areFriends('user_b', 'friend_1');
      expect(areFriends, isTrue);

      final notFriends = await friendService.areFriends('user_b', 'non_friend');
      expect(notFriends, isFalse);
    });
  });
}
