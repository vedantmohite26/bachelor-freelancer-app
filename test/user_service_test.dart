// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';

// Manual Fake Classes to mock Firestore without Mockito boilerplate or dependencies
class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> _collections = {};

  @override
  FakeCollectionReference collection(String path) {
    return _collections.putIfAbsent(path, () => FakeCollectionReference(path, this));
  }

  @override
  FakeWriteBatch batch() {
    return FakeWriteBatch();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final String path;
  final FakeFirebaseFirestore firestore;
  final Map<String, FakeDocumentReference> _documents = {};

  FakeCollectionReference(this.path, this.firestore);

  @override
  FakeDocumentReference doc([String? path]) {
    final docId = path ?? 'generated_id';
    return _documents.putIfAbsent(docId, () => FakeDocumentReference(docId, this));
  }

  @override
  FakeQuery where(
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
    return FakeQuery(this).where(
      field,
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      arrayContains: arrayContains,
      arrayContainsAny: arrayContainsAny,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
      isNull: isNull,
    );
  }

  @override
  FakeQuery limit(int limit) {
    return FakeQuery(this);
  }

  @override
  FakeQuery orderBy(Object field, {bool descending = false}) {
    return FakeQuery(this);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(dynamic data) async {
    final docRef = doc();
    await docRef.set(Map<String, dynamic>.from(data));
    return docRef;
  }

  @override
  Future<FakeQuerySnapshot> get([GetOptions? options]) async {
    final docs = _documents.values
        .map((doc) => FakeQueryDocumentSnapshot(doc.id, doc._data))
        .toList();
    return FakeQuerySnapshot(docs);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final String id;
  final FakeCollectionReference parentCollection;
  Map<String, dynamic> _data = {};
  int getCallsCount = 0;

  FakeDocumentReference(this.id, this.parentCollection);

  @override
  Future<FakeDocumentSnapshot> get([GetOptions? options]) async {
    getCallsCount++;
    return FakeDocumentSnapshot(id, _data);
  }

  @override
  Future<void> update(Map<Object?, Object?> data) async {
    data.forEach((key, value) {
      _data[key.toString()] = value;
    });
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _data = Map<String, dynamic>.from(data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(this.id, this._data);

  @override
  bool get exists => _data != null && _data!.isNotEmpty;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQueryDocumentSnapshot extends FakeDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  FakeQueryDocumentSnapshot(super.id, super.data);

  @override
  Map<String, dynamic> data() => _data ?? {};
}

class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  FakeQuerySnapshot(this.docs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuery implements Query<Map<String, dynamic>> {
  final FakeCollectionReference collectionRef;
  final List<MapEntry<String, dynamic>> _filters = [];

  FakeQuery(this.collectionRef);

  @override
  FakeQuery where(
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
    if (isEqualTo != null) {
      _filters.add(MapEntry(field.toString(), isEqualTo));
    }
    return this;
  }

  @override
  FakeQuery limit(int limit) => this;

  @override
  FakeQuery orderBy(Object field, {bool descending = false}) => this;

  @override
  Future<FakeQuerySnapshot> get([GetOptions? options]) async {
    final docs = collectionRef._documents.values
        .where((doc) {
          for (final filter in _filters) {
            if (doc._data[filter.key] != filter.value) return false;
          }
          return true;
        })
        .map((doc) => FakeQueryDocumentSnapshot(doc.id, doc._data))
        .toList();
    return FakeQuerySnapshot(docs);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWriteBatch implements WriteBatch {
  final List<Future<void> Function()> _operations = [];

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    _operations.add(() async {
      await (document as FakeDocumentReference).set(data as Map<String, dynamic>);
    });
  }

  @override
  Future<void> commit() async {
    for (final op in _operations) {
      await op();
    }
  }

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
      // Clear static cache before each test
      UserService.invalidateCache('user_1');
      UserService.invalidateCache('helper_1');
    });

    test('getUserProfile returns cached data on subsequent calls and avoids redundant Firestore queries', () async {
      // Setup mock user doc
      final userDoc = fakeFirestore.collection('users').doc('user_1');
      await userDoc.set({
        'name': 'Alice Smith',
        'email': 'alice@example.com',
        'role': 'seeker',
      });

      // First call (cache miss, gets from firestore)
      final profile1 = await userService.getUserProfile('user_1');
      expect(profile1, isNotNull);
      expect(profile1!['name'], equals('Alice Smith'));
      expect(userDoc.getCallsCount, equals(1));

      // Second call (cache hit, gets from in-memory cache)
      final profile2 = await userService.getUserProfile('user_1');
      expect(profile2, isNotNull);
      expect(profile2!['name'], equals('Alice Smith'));
      expect(userDoc.getCallsCount, equals(1)); // getCallsCount is still 1!
    });

    test('getUserProfile returns a fresh deep copy to prevent mutating the internal cached object reference', () async {
      final userDoc = fakeFirestore.collection('users').doc('user_1');
      await userDoc.set({
        'name': 'Alice Smith',
        'email': 'alice@example.com',
        'role': 'seeker',
      });

      final profile1 = await userService.getUserProfile('user_1');
      expect(profile1, isNotNull);

      // Mutate profile1
      profile1!['name'] = 'Alice Mutated';

      // Fetch profile2
      final profile2 = await userService.getUserProfile('user_1');
      expect(profile2, isNotNull);
      // Ensure profile2's name is NOT mutated, showing they are deep copies!
      expect(profile2!['name'], equals('Alice Smith'));
    });

    test('error recovery handles a failed future by invalidating the broken cache entry', () async {
      // Let's mock a document reference that throws on get()
      final usersCollection = fakeFirestore.collection('users');
      final brokenDoc = _BrokenDocumentReference('broken_user', usersCollection);
      usersCollection._documents['broken_user'] = brokenDoc;

      // Try fetching should throw
      bool threw = false;
      try {
        await userService.getUserProfile('broken_user');
      } catch (e) {
        threw = true;
      }
      expect(threw, isTrue);

      // Subsequent attempt after fixing the document should succeed (cache was invalidated on error)
      brokenDoc.shouldThrow = false;
      brokenDoc._data = {'name': 'Fixed User'};

      final profile = await userService.getUserProfile('broken_user');
      expect(profile, isNotNull);
      expect(profile!['name'], equals('Fixed User'));
    });

    test('cache invalidation works on all profile-modifying methods in UserService', () async {
      final userDoc = fakeFirestore.collection('users').doc('user_1');
      await userDoc.set({
        'name': 'Bob Barker',
        'email': 'bob@example.com',
        'role': 'helper',
      });

      // Cache the profile
      await userService.getUserProfile('user_1');
      expect(userDoc.getCallsCount, equals(1));

      // 1. Invalidate via updateProfile
      await userService.updateProfile('user_1', {'name': 'Bob Revised'});
      await userService.getUserProfile('user_1');
      expect(userDoc.getCallsCount, equals(2)); // Cache was invalidated, query performed again!

      // 2. Invalidate via updateSkills
      await userService.updateSkills('user_1', ['Plumbing']);
      await userService.getUserProfile('user_1');
      expect(userDoc.getCallsCount, equals(3));

      // 3. Invalidate via updateOnlineStatus
      await userService.updateOnlineStatus('user_1', true);
      await userService.getUserProfile('user_1');
      expect(userDoc.getCallsCount, equals(4));

      // 4. Invalidate via resetDailyEarnings
      await userService.resetDailyEarnings('user_1');
      await userService.getUserProfile('user_1');
      expect(userDoc.getCallsCount, equals(5));

      // 5. Invalidate via updateSafetySettings
      await userService.updateSafetySettings('user_1', {'shareLocation': true});
      await userService.getUserProfile('user_1');
      expect(userDoc.getCallsCount, equals(6));

      // 6. Invalidate via addTrustedContact
      await userService.addTrustedContact('user_1', {'name': 'Mom'});
      await userService.getUserProfile('user_1');
      expect(userDoc.getCallsCount, equals(7));

      // 7. Invalidate via removeTrustedContact
      await userService.removeTrustedContact('user_1', {'name': 'Mom'});
      await userService.getUserProfile('user_1');
      expect(userDoc.getCallsCount, equals(8));
    });

    test('RatingService._updateHelperRating invalidates the cached helper profile in UserService', () async {
      // Setup helper and rating documents
      final helperDoc = fakeFirestore.collection('users').doc('helper_1');
      await helperDoc.set({
        'name': 'Super Helper',
        'email': 'helper@example.com',
        'role': 'helper',
        'rating': 0.0,
        'reviewCount': 0,
      });

      final ratingDoc = fakeFirestore.collection('ratings').doc('rating_1');
      await ratingDoc.set({
        'helperId': 'helper_1',
        'overallRating': 5,
        'seekerId': 'seeker_1',
        'jobId': 'job_1',
      });

      // Cache the helper's profile
      await userService.getUserProfile('helper_1');
      expect(helperDoc.getCallsCount, equals(1));

      // Call submit rating, which triggers _updateHelperRating and invalidates the cache
      await ratingService.submitRating(
        helperId: 'helper_1',
        seekerId: 'seeker_2', // different seeker to avoid duplicate rating error
        jobId: 'job_2', // different job
        overallRating: 5,
        communication: 5.0,
        punctuality: 5.0,
        quality: 5.0,
      );

      // Verify the helper profile in Firestore has been updated
      expect(helperDoc._data['rating'], equals(5.0));
      expect(helperDoc._data['reviewCount'], equals(2)); // total 2 ratings

      // Retrieve helper profile again
      final cachedProfile = await userService.getUserProfile('helper_1');
      expect(cachedProfile!['rating'], equals(5.0));
      expect(helperDoc.getCallsCount, equals(2)); // Cache was invalidated and profile re-fetched from firestore!
    });
  });
}

class _BrokenDocumentReference extends FakeDocumentReference {
  bool shouldThrow = true;

  _BrokenDocumentReference(super.id, super.collection);

  @override
  Future<FakeDocumentSnapshot> get([GetOptions? options]) async {
    if (shouldThrow) {
      throw Exception('Database read error');
    }
    return super.get(options);
  }
}
