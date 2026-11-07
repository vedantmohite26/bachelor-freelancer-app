// ignore_for_file: subtype_of_sealed_class, annotate_overrides
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/notification_service.dart';

// Fake implementations for Firestore classes to test ChatService in isolation

class FakeQueryDocumentSnapshot<T> implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> _data;

  FakeQueryDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic> data() => Map<String, dynamic>.from(_data);

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

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;
  @override
  final bool exists;

  FakeDocumentSnapshot(this.id, this._data, {this.exists = true});

  @override
  Map<String, dynamic>? data() => _data != null ? Map<String, dynamic>.from(_data) : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  @override
  final String id;
  final FakeFirebaseFirestore firestore;
  final String path;

  FakeDocumentReference(this.id, this.firestore, this.path);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return firestore.collection('$path/$collectionPath');
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final docData = firestore.documents[path];
    if (docData == null) {
      return FakeDocumentSnapshot(id, null, exists: false);
    }
    return FakeDocumentSnapshot(id, docData, exists: true);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    final existing = firestore.documents[path] ?? <String, dynamic>{};
    for (final entry in data.entries) {
      existing[entry.key.toString()] = entry.value;
    }
    firestore.documents[path] = existing;
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    firestore.documents[path] = Map<String, dynamic>.from(data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuery implements Query<Map<String, dynamic>> {
  final FakeFirebaseFirestore firestore;
  final String collectionPath;
  final String? arrayContainsField;
  final dynamic arrayContainsValue;

  FakeQuery(
    this.firestore,
    this.collectionPath, {
    this.arrayContainsField,
    this.arrayContainsValue,
  });

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
    return FakeQuery(
      firestore,
      collectionPath,
      arrayContainsField: field.toString(),
      arrayContainsValue: arrayContains,
    );
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    firestore.queryGetCallCount++;
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    final prefix = '$collectionPath/';
    for (final entry in firestore.documents.entries) {
      if (entry.key.startsWith(prefix) && !entry.key.substring(prefix.length).contains('/')) {
        final docId = entry.key.substring(prefix.length);
        final data = entry.value;
        if (arrayContainsField != null && arrayContainsValue != null) {
          final list = data[arrayContainsField];
          if (list is List && list.contains(arrayContainsValue)) {
            docs.add(FakeQueryDocumentSnapshot(docId, data));
          }
        } else {
          docs.add(FakeQueryDocumentSnapshot(docId, data));
        }
      }
    }

    return FakeQuerySnapshot(docs);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    get().then((snapshot) {
      controller.add(snapshot);
    });
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference extends FakeQuery implements CollectionReference<Map<String, dynamic>> {
  FakeCollectionReference(super.firestore, super.collectionPath);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? 'doc_${firestore.documents.length + 1}';
    return FakeDocumentReference(docId, firestore, '$collectionPath/$docId');
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    firestore.docAddCallCount++;
    final docRef = doc();
    firestore.documents['$collectionPath/${docRef.id}'] = Map<String, dynamic>.from(data);
    return docRef;
  }
}

class FakeWriteBatch implements WriteBatch {
  final FakeFirebaseFirestore firestore;

  FakeWriteBatch(this.firestore);

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    final fakeDoc = document as FakeDocumentReference;
    fakeDoc.set(data as Map<String, dynamic>, options);
  }

  @override
  void update(DocumentReference<Object?> document, Map<String, dynamic> data) {
    final fakeDoc = document as FakeDocumentReference;
    fakeDoc.update(data);
  }

  @override
  Future<void> commit() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> documents = {};
  int queryGetCallCount = 0;
  int docAddCallCount = 0;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(this, collectionPath);
  }

  @override
  WriteBatch batch() => FakeWriteBatch(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationService implements NotificationService {
  final List<Map<String, dynamic>> notifications = [];

  @override
  Future<void> createNotification({
    required String userId,
    required String title,
    required String subtitle,
    required String type,
    String? relatedId,
  }) async {
    notifications.add({
      'userId': userId,
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'relatedId': relatedId,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ChatService Performance & Caching Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FakeNotificationService fakeNotificationService;
    late ChatService chatService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fakeNotificationService = FakeNotificationService();
      chatService = ChatService(
        firestore: fakeFirestore,
        notificationService: fakeNotificationService,
      );
    });

    test('constructor supports optional dependency injection and initializes properly', () {
      final injectedService = ChatService(
        firestore: fakeFirestore,
        notificationService: fakeNotificationService,
      );
      expect(injectedService, isNotNull);
    });

    test('createChat caches chatId on lookup and avoids redundant Firestore queries', () async {
      // Setup existing chat in Firestore
      fakeFirestore.documents['chats/chat_123'] = {
        'participants': ['user_a', 'user_b'],
        'lastMessage': 'Hello',
        'lastMessageTime': Timestamp.fromMillisecondsSinceEpoch(1000),
      };

      expect(fakeFirestore.queryGetCallCount, 0);

      // First call (without friendship check for simplicity)
      final chatId1 = await chatService.createChat(
        'user_b',
        'user_a',
        checkFriendship: false,
      );
      expect(chatId1, 'chat_123');
      expect(fakeFirestore.queryGetCallCount, 1);

      // Second call with same order should hit cache without querying Firestore
      final chatId2 = await chatService.createChat(
        'user_b',
        'user_a',
        checkFriendship: false,
      );
      expect(chatId2, 'chat_123');
      expect(fakeFirestore.queryGetCallCount, 1); // Still 1! 0 Firestore reads

      // Third call with inverted arguments should also hit cache
      final chatId3 = await chatService.createChat(
        'user_a',
        'user_b',
        checkFriendship: false,
      );
      expect(chatId3, 'chat_123');
      expect(fakeFirestore.queryGetCallCount, 1); // Still 1! Cache hit
    });

    test('createChat caches new chat ID upon creation', () async {
      final newChatId = await chatService.createChat(
        'user_x',
        'user_y',
        checkFriendship: false,
      );
      expect(newChatId, isNotEmpty);
      expect(fakeFirestore.docAddCallCount, 1);
      expect(fakeFirestore.queryGetCallCount, 1);

      // Subsequent createChat calls return cached ID without querying Firestore again
      final cachedId = await chatService.createChat(
        'user_y',
        'user_x',
        checkFriendship: false,
      );
      expect(cachedId, newChatId);
      expect(fakeFirestore.queryGetCallCount, 1);
      expect(fakeFirestore.docAddCallCount, 1);
    });

    test('clearCache resets the in-memory cache', () async {
      fakeFirestore.documents['chats/chat_456'] = {
        'participants': ['alice', 'bob'],
      };

      final id1 = await chatService.createChat('bob', 'alice', checkFriendship: false);
      expect(id1, 'chat_456');
      expect(fakeFirestore.queryGetCallCount, 1);

      // Clear cache
      chatService.clearCache();

      // Next call re-queries Firestore
      final id2 = await chatService.createChat('bob', 'alice', checkFriendship: false);
      expect(id2, 'chat_456');
      expect(fakeFirestore.queryGetCallCount, 2);
    });

    test('createChat throws exception when users are not friends and checkFriendship is true', () async {
      expect(
        () => chatService.createChat('stranger', 'me', checkFriendship: true),
        throwsA(isA<Exception>()),
      );
    });

    test('createChat succeeds when users are friends and checkFriendship is true', () async {
      fakeFirestore.documents['users/me/friends/friend_1'] = {'isFriend': true};
      fakeFirestore.documents['chats/chat_friend'] = {
        'participants': ['me', 'friend_1'],
      };

      final chatId = await chatService.createChat('friend_1', 'me', checkFriendship: true);
      expect(chatId, 'chat_friend');
    });

    test('getUserChats populates cache and sorts chats by lastMessageTime descending using Timestamps', () async {
      final ts1 = Timestamp.fromMillisecondsSinceEpoch(1000);
      final ts2 = Timestamp.fromMillisecondsSinceEpoch(5000);
      final ts3 = Timestamp.fromMillisecondsSinceEpoch(3000);

      fakeFirestore.documents['chats/c1'] = {
        'participants': ['user_1', 'user_2'],
        'lastMessage': 'Oldest',
        'lastMessageTime': ts1,
      };
      fakeFirestore.documents['chats/c2'] = {
        'participants': ['user_1', 'user_3'],
        'lastMessage': 'Newest',
        'lastMessageTime': ts2,
      };
      fakeFirestore.documents['chats/c3'] = {
        'participants': ['user_1', 'user_4'],
        'lastMessage': 'Middle',
        'lastMessageTime': ts3,
      };

      final stream = chatService.getUserChats('user_1');
      final result = await stream.first;

      // Sorted descending: c2 (5000), c3 (3000), c1 (1000)
      expect(result.length, 3);
      expect(result[0]['id'], 'c2');
      expect(result[1]['id'], 'c3');
      expect(result[2]['id'], 'c1');

      final queriesBefore = fakeFirestore.queryGetCallCount;
      // Check that cache was populated from stream
      final cachedId = await chatService.createChat(
        'user_3',
        'user_1',
        checkFriendship: false,
      );
      expect(cachedId, 'c2');
      // No queries made by createChat because it was primed by getUserChats
      expect(fakeFirestore.queryGetCallCount, queriesBefore);
    });
  });
}
