// ignore_for_file: subtype_of_sealed_class, must_be_immutable, overridden_fields, annotate_overrides, use_super_parameters, unnecessary_no_such_method

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';

// Fake DocumentSnapshot for testing
class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final String _id;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake DocumentReference for testing
class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final String _id;
  final Map<String, Map<String, dynamic>> _db;
  int getCalls = 0;
  int updateCalls = 0;
  bool shouldThrowError = false;

  FakeDocumentReference(this._id, this._db);

  @override
  String get id => _id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getCalls++;
    if (shouldThrowError) {
      throw FirebaseException(plugin: 'cloud_firestore', message: 'Simulated Firestore Error');
    }
    return FakeDocumentSnapshot(_id, _db[_id]);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updateCalls++;
    final castedData = Map<String, dynamic>.from(data);
    if (_db.containsKey(_id)) {
      _db[_id]!.addAll(castedData);
    } else {
      _db[_id] = castedData;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake QueryDocumentSnapshot for testing
class FakeQueryDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final String _id;

  FakeQueryDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake QuerySnapshot for testing
class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake Query for testing
class FakeQuery implements Query<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _db;
  final String _collectionPath;
  final String? _helperId;
  final String? _seekerId;
  final String? _jobId;

  FakeQuery(this._db, this._collectionPath, [this._helperId, this._seekerId, this._jobId]);

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
    if (field == 'helperId' && isEqualTo is String) {
      return FakeQuery(_db, _collectionPath, isEqualTo, _seekerId, _jobId);
    }
    if (field == 'seekerId' && isEqualTo is String) {
      return FakeQuery(_db, _collectionPath, _helperId, isEqualTo, _jobId);
    }
    if (field == 'jobId' && isEqualTo is String) {
      return FakeQuery(_db, _collectionPath, _helperId, _seekerId, isEqualTo);
    }
    return this;
  }

  @override
  Query<Map<String, dynamic>> limit(int limitValue) {
    return this;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];
    if (_collectionPath == 'ratings') {
      _db.forEach((key, value) {
        if (key.startsWith('ratings_')) {
          final hId = value['helperId'];
          final sId = value['seekerId'];
          final jId = value['jobId'];
          if ((_helperId == null || hId == _helperId) &&
              (_seekerId == null || sId == _seekerId) &&
              (_jobId == null || jId == _jobId)) {
            docs.add(FakeQueryDocumentSnapshot(key, value));
          }
        }
      });
    }
    return FakeQuerySnapshot(docs);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake CollectionReference for testing
class FakeCollectionReference extends FakeQuery implements CollectionReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _db;
  final Map<String, FakeDocumentReference> _docs = {};

  FakeCollectionReference(Map<String, Map<String, dynamic>> db, String path) : _db = db, super(db, path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? 'temp_id';
    return _docs.putIfAbsent(docId, () => FakeDocumentReference(docId, _db));
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    final docId = 'ratings_${_db.length + 1}';
    _db[docId] = Map<String, dynamic>.from(data);
    return FakeDocumentReference(docId, _db);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake FirebaseFirestore for testing
class FakeFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> db = {};
  final Map<String, FakeCollectionReference> _collections = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _collections.putIfAbsent(collectionPath, () => FakeCollectionReference(db, collectionPath));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UserService Caching and Invalidation Tests', () {
    late FakeFirestore fakeFirestore;
    late UserService userService;

    setUp(() {
      fakeFirestore = FakeFirestore();
      userService = UserService(firestore: fakeFirestore);
      // Ensure we clear the static cache before each test
      UserService.invalidateCache('user_1');
      UserService.invalidateCache('helper_1');
    });

    test('getUserProfile caches Firestore results and returns deep copies', () async {
      // Set up database data
      fakeFirestore.db['user_1'] = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'helper',
      };

      final docRef = fakeFirestore.collection('users').doc('user_1') as FakeDocumentReference;

      // 1. First call to getUserProfile
      final profile1 = await userService.getUserProfile('user_1');
      expect(profile1, isNotNull);
      expect(profile1!['name'], 'John Doe');
      expect(docRef.getCalls, 1);

      // 2. Second call should return cached value and NOT query Firestore again
      final profile2 = await userService.getUserProfile('user_1');
      expect(profile2, isNotNull);
      expect(profile2!['name'], 'John Doe');
      expect(docRef.getCalls, 1); // Remains 1, meaning it was cached!

      // 3. Modifying returned profile map must not affect internal cache (deep copy check)
      profile1['name'] = 'Modified Name';
      final profile3 = await userService.getUserProfile('user_1');
      expect(profile3!['name'], 'John Doe'); // Still John Doe, not Modified Name
    });

    test('static invalidateCache invalidates cache successfully', () async {
      fakeFirestore.db['user_1'] = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'helper',
      };

      final docRef = fakeFirestore.collection('users').doc('user_1') as FakeDocumentReference;

      await userService.getUserProfile('user_1');
      expect(docRef.getCalls, 1);

      // Invalidate the cache
      UserService.invalidateCache('user_1');

      // Next call should query Firestore again
      await userService.getUserProfile('user_1');
      expect(docRef.getCalls, 2); // Increased to 2, cache was invalidated!
    });

    test('profile-modifying methods in UserService invalidate the cache', () async {
      fakeFirestore.db['user_1'] = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'helper',
        'isOnline': false,
      };

      final docRef = fakeFirestore.collection('users').doc('user_1') as FakeDocumentReference;

      // Cache it
      await userService.getUserProfile('user_1');
      expect(docRef.getCalls, 1);

      // Update online status (this should trigger cache invalidation)
      await userService.updateOnlineStatus('user_1', true);
      expect(docRef.updateCalls, 1);

      // Next read should query Firestore because cache is invalidated
      await userService.getUserProfile('user_1');
      expect(docRef.getCalls, 2);
    });

    test('RatingService _updateHelperRating invalidates UserService cache', () async {
      fakeFirestore.db['helper_1'] = {
        'name': 'Bob Helper',
        'email': 'bob@example.com',
        'role': 'helper',
        'rating': 0.0,
        'reviewCount': 0,
      };

      // Set up simple ratings to trigger _updateHelperRating without throwing Empty error
      fakeFirestore.db['ratings_1'] = {
        'helperId': 'helper_1',
        'overallRating': 5,
        'seekerId': 'seeker_1',
        'jobId': 'job_1',
      };

      final docRef = fakeFirestore.collection('users').doc('helper_1') as FakeDocumentReference;

      // Cache the helper profile
      await userService.getUserProfile('helper_1');
      expect(docRef.getCalls, 1);

      // We need a RatingService referencing our fakeFirestore to perform the rating update
      final ratingService = RatingService(firestore: fakeFirestore);

      // Submit rating / update rating
      // Under the hood, submitRating or _updateHelperRating will query "ratings" and update "users"
      await ratingService.submitRating(
        helperId: 'helper_1',
        seekerId: 'seeker_12', // Different seeker ID to avoid duplicate exception
        jobId: 'job_12',       // Different job ID to avoid duplicate exception
        overallRating: 5,
        communication: 5,
        punctuality: 5,
        quality: 5,
      );

      // Since update online status or rating update happened, the cache for helper_1 must be invalidated.
      // Let's verify by checking getCalls increase on the helper_1 user document:
      await userService.getUserProfile('helper_1');
      expect(docRef.getCalls, 2); // Cache was invalidated and queried Firestore again!
    });

    test('getUserProfile removes failed future from cache on Firestore error', () async {
      fakeFirestore.db['user_1'] = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'helper',
      };

      final docRef = fakeFirestore.collection('users').doc('user_1') as FakeDocumentReference;
      docRef.shouldThrowError = true;

      // Attempt to get user profile (should throw and be handled cleanly in expectation)
      await expectLater(
        userService.getUserProfile('user_1'),
        throwsA(isA<FirebaseException>()),
      );

      // Reset the error flag
      docRef.shouldThrowError = false;

      // Call again. Since the failed future was removed from cache, it should succeed
      final profile = await userService.getUserProfile('user_1');
      expect(profile, isNotNull);
      expect(profile!['name'], 'John Doe');
      expect(docRef.getCalls, 2); // Initial failed call + new successful call
    });
  });
}
