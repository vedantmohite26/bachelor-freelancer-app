// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides, avoid_print

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> collections = {};

  @override
  FakeCollectionReference collection(String collectionPath) {
    return collections.putIfAbsent(collectionPath, () => FakeCollectionReference(collectionPath));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final String path;
  final Map<String, FakeDocumentReference> documents = {};

  FakeCollectionReference(this.path);

  @override
  FakeDocumentReference doc([String? path]) {
    final docId = path ?? 'temp_id';
    return documents.putIfAbsent(docId, () => FakeDocumentReference(docId, this));
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    final docId = 'doc_${documents.length + 1}';
    final docRef = documents.putIfAbsent(docId, () => FakeDocumentReference(docId, this));
    docRef.data = data;
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
    return FakeQuery(this, field: field, isEqualTo: isEqualTo);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuery implements Query<Map<String, dynamic>> {
  final FakeCollectionReference collectionRef;
  final Object? field;
  final Object? isEqualTo;
  final int? limitValue;

  FakeQuery(this.collectionRef, {this.field, this.isEqualTo, this.limitValue});

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
    return FakeQuery(collectionRef, field: field, isEqualTo: isEqualTo, limitValue: limitValue);
  }

  @override
  Query<Map<String, dynamic>> limit(int value) {
    return FakeQuery(collectionRef, field: field, isEqualTo: isEqualTo, limitValue: value);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    List<FakeDocumentSnapshot> matches = [];
    for (var doc in collectionRef.documents.values) {
      if (doc.data != null) {
        if (field != null && isEqualTo != null) {
          if (doc.data![field.toString()] == isEqualTo) {
            matches.add(FakeDocumentSnapshot(doc.id, doc.data, doc));
          }
        } else {
          matches.add(FakeDocumentSnapshot(doc.id, doc.data, doc));
        }
      }
    }
    if (limitValue != null && matches.length > limitValue!) {
      matches = matches.sublist(0, limitValue!);
    }
    return FakeQuerySnapshot(matches);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  final List<FakeDocumentSnapshot> _docs;

  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final String id;
  final FakeCollectionReference collectionRef;
  Map<String, dynamic>? data;
  final StreamController<DocumentSnapshot<Map<String, dynamic>>> _controller = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
  int getCalls = 0;
  int updateCalls = 0;

  FakeDocumentReference(this.id, this.collectionRef);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getCalls++;
    if (id == 'fail_me') {
      throw FirebaseException(plugin: 'firestore', message: 'Simulated Firestore failure');
    }
    return FakeDocumentSnapshot(id, data, this);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updateCalls++;
    if (this.data == null) {
      this.data = {};
    }
    this.data!.addAll(data.cast<String, dynamic>());
    _controller.add(FakeDocumentSnapshot(id, this.data, this));
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    final controller = StreamController<DocumentSnapshot<Map<String, dynamic>>>();
    controller.add(FakeDocumentSnapshot(id, data, this));
    final subscription = _controller.stream.listen((snapshot) {
      controller.add(snapshot);
    });
    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };
    return controller.stream;
  }

  void emit(Map<String, dynamic>? data) {
    this.data = data;
    _controller.add(FakeDocumentSnapshot(id, data, this));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>>, QueryDocumentSnapshot<Map<String, dynamic>> {
  final String id;
  final Map<String, dynamic>? _data;
  final DocumentReference<Map<String, dynamic>> reference;

  FakeDocumentSnapshot(this.id, this._data, this.reference);

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic> data() => _data ?? {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UserService Caching Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserService userService;
    late RatingService ratingService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userService = UserService(firestore: fakeFirestore);
      ratingService = RatingService(firestore: fakeFirestore);
      // Ensure cache is completely cleared before each test
      UserService.invalidateCache('user1');
      UserService.invalidateCache('helper1');
      UserService.invalidateCache('fail_me');
    });

    test('Initial get is a cache miss and subsequent calls are cache hits', () async {
      final docRef = fakeFirestore.collection('users').doc('user1');
      docRef.data = {'name': 'Alice', 'role': 'seeker'};

      expect(docRef.getCalls, 0);

      // First fetch: Cache miss (calls Firestore)
      final user1 = await userService.getUserProfile('user1');
      expect(user1, isNotNull);
      expect(user1!['name'], 'Alice');
      expect(docRef.getCalls, 1);

      // Second fetch: Cache hit (uses cached future, does not call Firestore)
      final user2 = await userService.getUserProfile('user1');
      expect(user2, isNotNull);
      expect(user2!['name'], 'Alice');
      expect(docRef.getCalls, 1);
    });

    test('Parallel calls for the same profile share the exact same Future (1 Firestore hit)', () async {
      final docRef = fakeFirestore.collection('users').doc('user1');
      docRef.data = {'name': 'Alice', 'role': 'seeker'};

      // Trigger parallel fetches
      final futures = await Future.wait([
        userService.getUserProfile('user1'),
        userService.getUserProfile('user1'),
        userService.getUserProfile('user1'),
      ]);

      expect(futures[0]!['name'], 'Alice');
      expect(futures[1]!['name'], 'Alice');
      expect(futures[2]!['name'], 'Alice');
      expect(docRef.getCalls, 1); // Only 1 Firestore fetch was executed
    });

    test('Modifying returned user profile map does not mutate internal cache (Deep Copying)', () async {
      final docRef = fakeFirestore.collection('users').doc('user1');
      docRef.data = {'name': 'Alice', 'role': 'seeker'};

      final user1 = await userService.getUserProfile('user1');
      expect(user1!['name'], 'Alice');

      // Mutate the returned map
      user1['name'] = 'Bob';

      // Fetch again
      final user2 = await userService.getUserProfile('user1');
      expect(user2!['name'], 'Alice'); // Cache retains the original Alice map
    });

    test('Profile updates invalidate the cache', () async {
      final docRef = fakeFirestore.collection('users').doc('user1');
      docRef.data = {'name': 'Alice', 'role': 'seeker', 'isOnline': false};

      // Cache it
      await userService.getUserProfile('user1');
      expect(docRef.getCalls, 1);

      // Update online status (profile modifying method)
      await userService.updateOnlineStatus('user1', true);
      expect(docRef.data!['isOnline'], true);

      // Fetch again: should be cache miss and make a new Firestore call
      final user = await userService.getUserProfile('user1');
      expect(user!['isOnline'], true);
      expect(docRef.getCalls, 2);
    });

    test('Failed Firestore fetches are evicted from cache, next fetch retries', () async {
      final docRef = fakeFirestore.collection('users').doc('fail_me');

      // Attempt fetch - should throw error and evict
      try {
        await userService.getUserProfile('fail_me');
        fail('Should have failed');
      } catch (e) {
        expect(e, isA<FirebaseException>());
      }

      expect(docRef.getCalls, 1);

      // Fetch again - since the previous failed future was evicted, it should try again
      try {
        await userService.getUserProfile('fail_me');
        fail('Should have failed again');
      } catch (e) {
        expect(e, isA<FirebaseException>());
      }
      expect(docRef.getCalls, 2); // It did try again!
    });

    test('Rating updates invalidate the helper profile cache', () async {
      final helperRef = fakeFirestore.collection('users').doc('helper1');
      helperRef.data = {'name': 'Helper Bob', 'rating': 0.0, 'reviewCount': 0};

      // Cache the helper profile
      await userService.getUserProfile('helper1');
      expect(helperRef.getCalls, 1);

      // We simulate submitRating rating/review calculations or mock it.
      // RatingService._updateHelperRating relies on fetching from ratings collection,
      // let's put some rating doc in ratings collection.
      final ratingsCol = fakeFirestore.collection('ratings');
      ratingsCol.doc('rating1').data = {
        'helperId': 'helper1',
        'seekerId': 'seeker1',
        'jobId': 'job1',
        'overallRating': 5,
        'createdAt': Timestamp.now(),
      };

      // Submit rating, which will trigger _updateHelperRating and in turn UserService.invalidateCache('helper1')
      await ratingService.submitRating(
        helperId: 'helper1',
        seekerId: 'seeker2', // distinct seeker to avoid duplicate checks in submitRating
        jobId: 'job2',
        overallRating: 5,
        communication: 5,
        punctuality: 5,
        quality: 5,
      );

      // Fetching helper profile again should trigger a new Firestore get (cache miss due to invalidation)
      await userService.getUserProfile('helper1');
      expect(helperRef.getCalls, 2);
    });

    test('StreamBuilder updates cache when real-time snapshot is received', () async {
      final docRef = fakeFirestore.collection('users').doc('user1');
      docRef.data = {'name': 'Alice', 'role': 'seeker'};

      // Fetch from stream to initialize cache with latest state
      final stream = userService.getUserProfileStream('user1');
      final firstEmit = await stream.first;
      expect(firstEmit!['name'], 'Alice');

      // Calling future getUserProfile should hit the stream-populated cache directly (0 docRef.getCalls)
      final cachedProfile = await userService.getUserProfile('user1');
      expect(cachedProfile!['name'], 'Alice');
      expect(docRef.getCalls, 0); // Directly fetched from cache populated by the stream subscription mapping
    });
  });
}
