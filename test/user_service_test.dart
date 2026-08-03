// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides, invalid_use_of_protected_member
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';

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
  final Map<String, dynamic> _dbStore;
  int getCalls = 0;
  int updateCalls = 0;
  bool shouldFail = false;

  FakeDocumentReference(this._id, this._dbStore);

  @override
  String get id => _id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getCalls++;
    if (shouldFail) {
      throw FirebaseException(plugin: 'firestore', message: 'Fake error');
    }
    final exists = _dbStore.containsKey(_id);
    return FakeDocumentSnapshot(_id, exists ? _dbStore[_id] : null, exists);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updateCalls++;
    if (_dbStore.containsKey(_id)) {
      _dbStore[_id]!.addAll(data.cast<String, dynamic>());
    } else {
      _dbStore[_id] = data.cast<String, dynamic>();
    }
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _dbStore[_id] = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final String _name;
  final Map<String, dynamic> _dbStore;
  final Map<String, FakeDocumentReference> _docs = {};

  FakeCollectionReference(this._name, this._dbStore);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? 'dummy';
    return _docs.putIfAbsent(docId, () => FakeDocumentReference(docId, _dbStore));
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final results = <DocumentSnapshot<Map<String, dynamic>>>[];
    _dbStore.forEach((key, val) {
      results.add(FakeDocumentSnapshot(key, val, true));
    });
    return FakeQuerySnapshot(results);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    final id = 'auto_${DateTime.now().microsecondsSinceEpoch}';
    _dbStore[id] = data;
    return doc(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where ||
        invocation.memberName == #orderBy ||
        invocation.memberName == #limit) {
      return this;
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  final List<DocumentSnapshot<Map<String, dynamic>>> _docs;

  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs =>
      _docs.map((d) => FakeQueryDocumentSnapshot(d.id, d.data()!)).toList();
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

class FakeWriteBatch extends Fake implements WriteBatch {
  final List<Function> _operations = [];

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    _operations.add(() => (document as FakeDocumentReference).set(data as Map<String, dynamic>));
  }

  @override
  Future<void> commit() async {
    for (var op in _operations) {
      op();
    }
  }
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _collectionsStore = {};
  final Map<String, FakeCollectionReference> _collections = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    _collectionsStore.putIfAbsent(collectionPath, () => {});
    return _collections.putIfAbsent(
      collectionPath,
      () => FakeCollectionReference(collectionPath, _collectionsStore[collectionPath]!),
    );
  }

  @override
  WriteBatch batch() {
    return FakeWriteBatch();
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserService userService;
  late RatingService ratingService;
  late String testUserId;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userService = UserService(firestore: fakeFirestore);
    ratingService = RatingService(firestore: fakeFirestore);
    testUserId = 'user_123';
    UserService.invalidateCache(testUserId);
  });

  test('UserService caches user profile on first read and reuses Future on subsequent reads', () async {
    final userRef = fakeFirestore.collection('users').doc(testUserId);
    await userRef.set({
      'name': 'Alice',
      'email': 'alice@example.com',
      'role': 'helper',
    });

    final fakeDocRef = userRef as FakeDocumentReference;
    expect(fakeDocRef.getCalls, 0);

    // First read
    final profile1 = await userService.getUserProfile(testUserId);
    expect(profile1, isNotNull);
    expect(profile1!['name'], 'Alice');
    expect(fakeDocRef.getCalls, 1);

    // Second read
    final profile2 = await userService.getUserProfile(testUserId);
    expect(profile2, isNotNull);
    expect(profile2!['name'], 'Alice');
    // Ensure get was not called again on Firestore doc ref
    expect(fakeDocRef.getCalls, 1);
  });

  test('UserService returns deep copies of cached user profile maps to prevent mutation side-effects', () async {
    final userRef = fakeFirestore.collection('users').doc(testUserId);
    await userRef.set({
      'name': 'Alice',
      'email': 'alice@example.com',
      'role': 'helper',
    });

    final profile1 = await userService.getUserProfile(testUserId);
    expect(profile1, isNotNull);

    // Mutate the returned copy
    profile1!['name'] = 'Bob';

    // Retrieve again from cache
    final profile2 = await userService.getUserProfile(testUserId);
    expect(profile2, isNotNull);
    // Ensure the mutation did not affect the cached data
    expect(profile2!['name'], 'Alice');
  });

  test('UserService removes Future from cache on fetch failure, allowing subsequent retries', () async {
    final userRef = fakeFirestore.collection('users').doc(testUserId);
    await userRef.set({
      'name': 'Alice',
      'email': 'alice@example.com',
      'role': 'helper',
    });

    final fakeDocRef = userRef as FakeDocumentReference;
    fakeDocRef.shouldFail = true;

    // First read should fail
    bool failed = false;
    try {
      await userService.getUserProfile(testUserId);
    } on FirebaseException {
      failed = true;
    }
    expect(failed, isTrue);

    // Make it succeed now
    fakeDocRef.shouldFail = false;

    // Next read should retry and succeed
    final profile = await userService.getUserProfile(testUserId);
    expect(profile, isNotNull);
    expect(profile!['name'], 'Alice');
    expect(fakeDocRef.getCalls, 2);
  });

  test('UserService static invalidateCache clears cache for given user ID', () async {
    final userRef = fakeFirestore.collection('users').doc(testUserId);
    await userRef.set({
      'name': 'Alice',
      'email': 'alice@example.com',
      'role': 'helper',
    });

    final fakeDocRef = userRef as FakeDocumentReference;

    await userService.getUserProfile(testUserId);
    expect(fakeDocRef.getCalls, 1);

    // Invalidate
    UserService.invalidateCache(testUserId);

    // Read again
    await userService.getUserProfile(testUserId);
    expect(fakeDocRef.getCalls, 2);
  });

  test('Creating user profile invalidates the cache', () async {
    final userRef = fakeFirestore.collection('users').doc(testUserId);
    await userRef.set({
      'name': 'Alice',
      'email': 'alice@example.com',
      'role': 'helper',
    });

    await userService.getUserProfile(testUserId);

    // Create user profile (updates/overwrites profile)
    await userService.createUserProfile(
      userId: testUserId,
      name: 'Bob',
      email: 'bob@example.com',
      role: 'seeker',
    );

    // Read again, should hit firestore since cache was invalidated
    final profile = await userService.getUserProfile(testUserId);
    expect(profile!['name'], 'Bob');
  });

  test('RatingService._updateHelperRating invalidates cached helper profile', () async {
    final helperId = 'helper_456';
    UserService.invalidateCache(helperId);

    final helperRef = fakeFirestore.collection('users').doc(helperId);
    await helperRef.set({
      'name': 'Alice Helper',
      'email': 'helper@example.com',
      'role': 'helper',
      'rating': 5.0,
      'reviewCount': 1,
    });

    // Populate cache in UserService
    await userService.getUserProfile(helperId);
    final fakeDocRef = helperRef as FakeDocumentReference;
    expect(fakeDocRef.getCalls, 1);

    // Call submitRating which triggers _updateHelperRating internally
    await ratingService.submitRating(
      helperId: helperId,
      seekerId: 'seeker_2',
      jobId: 'job_2',
      overallRating: 5,
      communication: 5.0,
      punctuality: 5.0,
      quality: 5.0,
    );

    // Read helper profile again, should hit Firestore since RatingService invalidated it
    await userService.getUserProfile(helperId);
    expect(fakeDocRef.getCalls, 2);
  });
}
