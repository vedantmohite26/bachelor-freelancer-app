import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';

// Fake implementations to avoid complex Mockito code generation

class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final bool _exists;
  final String _id;

  FakeDocumentSnapshot(this._id, this._data, this._exists);

  @override
  String get id => _id;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}

class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _store;
  int getCount = 0;
  int updateCount = 0;
  bool shouldFail = false;

  FakeDocumentReference(this._id, this._store);

  @override
  String get id => _id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getCount++;
    if (shouldFail) {
      throw FirebaseException(plugin: 'cloud_firestore', message: 'Simulated failure');
    }
    final exists = _store.containsKey(_id);
    return FakeDocumentSnapshot(_id, exists ? _store[_id] : null, exists);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updateCount++;
    final map = Map<String, dynamic>.from(data);
    if (_store.containsKey(_id)) {
      _store[_id]!.addAll(map);
    } else {
      _store[_id] = map;
    }
  }
}

class FakeQueryDocumentSnapshot extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  FakeQueryDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;
}

class FakeQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;
}

class FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final List<Map<String, dynamic>> _filteredData;

  FakeQuery(this._filteredData);

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
    final filtered = _filteredData.where((value) => value[field] == isEqualTo).toList();
    return FakeQuery(filtered);
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return FakeQuery(_filteredData.take(limit).toList());
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final docs = _filteredData.map((data) => FakeQueryDocumentSnapshot(data['id'] ?? 'id', data)).toList();
    return FakeQuerySnapshot(docs);
  }
}

class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final Map<String, dynamic> _store;
  final Map<String, FakeDocumentReference> _docRefs = {};

  FakeCollectionReference(this._store);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? 'temp_id';
    return _docRefs.putIfAbsent(docId, () => FakeDocumentReference(docId, _store));
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    final id = 'rating_${DateTime.now().millisecondsSinceEpoch}';
    _store[id] = data;
    final docRef = FakeDocumentReference(id, _store);
    _docRefs[id] = docRef;
    return docRef;
  }

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
    final filtered = <Map<String, dynamic>>[];
    _store.forEach((key, value) {
      if (value is Map<String, dynamic> && value[field] == isEqualTo) {
        filtered.add({'id': key, ...value});
      }
    });
    return FakeQuery(filtered);
  }
}

class FakeWriteBatch extends Fake implements WriteBatch {
  final Map<String, dynamic> _store;
  final List<Function> _operations = [];

  FakeWriteBatch(this._store);

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    _operations.add(() {
      final docRef = document as FakeDocumentReference;
      _store[docRef.id] = data as Map<String, dynamic>;
    });
  }

  @override
  Future<void> commit() async {
    for (final op in _operations) {
      op();
    }
  }
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _databases = {
    'users': {},
    'ratings': {},
    'email_lookup': {},
  };

  final Map<String, FakeCollectionReference> _collections = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _collections.putIfAbsent(
      collectionPath,
      () => FakeCollectionReference(_databases.putIfAbsent(collectionPath, () => {})),
    );
  }

  @override
  WriteBatch batch() {
    return FakeWriteBatch(_databases['users']!);
  }
}

void main() {
  group('UserService In-Memory Cache Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserService userService;
    late RatingService ratingService;

    const testUserId = 'user_123';
    const testUserData = {
      'name': 'John Doe',
      'email': 'john@example.com',
      'role': 'helper',
      'isOnline': false,
      'rating': 4.5,
      'reviewCount': 2,
    };

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userService = UserService(firestore: fakeFirestore);
      ratingService = RatingService(firestore: fakeFirestore);

      // Invalidate cache before each test to ensure a clean slate
      UserService.invalidateCache(testUserId);

      // Seed database with a user
      fakeFirestore.collection('users').doc(testUserId).update(testUserData);
    });

    test('Verification: Cache Hit avoids redundant Firestore reads', () async {
      final userCol = fakeFirestore.collection('users') as FakeCollectionReference;
      final docRef = userCol.doc(testUserId) as FakeDocumentReference;

      // First fetch: should read from Firestore
      final profile1 = await userService.getUserProfile(testUserId);
      expect(profile1, isNotNull);
      expect(profile1!['name'], equals('John Doe'));
      expect(docRef.getCount, equals(1));

      // Second fetch: should hit the in-memory cache and NOT trigger get() again
      final profile2 = await userService.getUserProfile(testUserId);
      expect(profile2, isNotNull);
      expect(profile2!['name'], equals('John Doe'));
      expect(docRef.getCount, equals(1)); // get() count is still 1!
    });

    test('Verification: Deep copies are returned from cache to prevent mutations', () async {
      final profile1 = await userService.getUserProfile(testUserId);
      expect(profile1, isNotNull);

      // Mutate local object
      profile1!['name'] = 'Jane Doe';

      // Fetch again from cache
      final profile2 = await userService.getUserProfile(testUserId);
      expect(profile2, isNotNull);
      // The cached value remains intact
      expect(profile2!['name'], equals('John Doe'));
    });

    test('Verification: Cache is invalidated upon profile updates', () async {
      final userCol = fakeFirestore.collection('users') as FakeCollectionReference;
      final docRef = userCol.doc(testUserId) as FakeDocumentReference;

      // Prime the cache
      await userService.getUserProfile(testUserId);
      expect(docRef.getCount, equals(1));

      // Modify profile -> triggers invalidation
      await userService.updateOnlineStatus(testUserId, true);

      // Next fetch should retrieve from Firestore again
      await userService.getUserProfile(testUserId);
      expect(docRef.getCount, equals(2)); // get() triggered again!
    });

    test('Verification: Cache invalidation from RatingService', () async {
      final userCol = fakeFirestore.collection('users') as FakeCollectionReference;
      final docRef = userCol.doc(testUserId) as FakeDocumentReference;

      // Prime the cache
      await userService.getUserProfile(testUserId);
      expect(docRef.getCount, equals(1));

      // Seed a rating
      await fakeFirestore.collection('ratings').add({
        'helperId': testUserId,
        'seekerId': 'seeker_99',
        'overallRating': 5,
        'communication': 5.0,
        'punctuality': 5.0,
        'quality': 5.0,
        'createdAt': Timestamp.now(),
      });

      // Submit/Update rating -> should trigger UserService cache invalidation for helper
      // Normally, RatingService.submitRating calls _updateHelperRating, but since we want to test _updateHelperRating's logic:
      // RatingService.submitRating will call _updateHelperRating which updates the helper profile in Firestore and invalidates the cache.
      await ratingService.submitRating(
        helperId: testUserId,
        seekerId: 'seeker_100',
        jobId: 'job_456',
        overallRating: 5,
        communication: 5.0,
        punctuality: 5.0,
        quality: 5.0,
      );

      // Fetch helper profile again
      await userService.getUserProfile(testUserId);
      expect(docRef.getCount, equals(2)); // get() triggered again because RatingService invalidated the cache!
    });

    test('Verification: Error recovery removes broken Future from cache', () async {
      final userCol = fakeFirestore.collection('users') as FakeCollectionReference;
      final docRef = userCol.doc(testUserId) as FakeDocumentReference;

      // Configure document reference to fail on next get
      docRef.shouldFail = true;

      // Attempt to fetch should throw error
      try {
        await userService.getUserProfile(testUserId);
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<FirebaseException>());
      }

      // Reset failure flag
      docRef.shouldFail = false;

      // Subsequent fetch should try again successfully and read from Firestore
      final profile = await userService.getUserProfile(testUserId);
      expect(profile, isNotNull);
      expect(profile!['name'], equals('John Doe'));
      expect(docRef.getCount, equals(2)); // Attempted twice
    });
  });
}
