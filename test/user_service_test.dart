import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';

// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> collections = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return collections.putIfAbsent(
      collectionPath,
      () => FakeCollectionReference(collectionPath),
    );
  }

  @override
  WriteBatch batch() {
    return FakeWriteBatch(this);
  }
}

class FakeWriteBatch extends Fake implements WriteBatch {
  final FakeFirebaseFirestore firestore;
  final List<Future<void> Function()> operations = [];

  FakeWriteBatch(this.firestore);

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    operations.add(() async {
      await document.set(data, options);
    });
  }

  @override
  Future<void> commit() async {
    for (final op in operations) {
      await op();
    }
  }
}

class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final String path;
  final Map<String, FakeDocumentReference> documents = {};

  FakeCollectionReference(this.path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? 'doc_${DateTime.now().millisecondsSinceEpoch}';
    return documents.putIfAbsent(
      docId,
      () => FakeDocumentReference(this, docId),
    );
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final docs = documents.values
        .where((doc) => doc.exists)
        .map((doc) => FakeQueryDocumentSnapshot(doc))
        .toList();
    return FakeQuerySnapshot(docs);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    final docRef = doc();
    await docRef.set(data);
    return docRef;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final methodName = invocation.memberName.toString();
    if (methodName.contains('where') || methodName.contains('orderBy') || methodName.contains('limit')) {
      return this;
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  final FakeCollectionReference collectionRef;
  final String docId;
  Map<String, dynamic>? data;
  bool exists = false;
  final StreamController<DocumentSnapshot<Map<String, dynamic>>> _controller = StreamController.broadcast();
  bool throwOnGet = false;

  FakeDocumentReference(this.collectionRef, this.docId);

  @override
  String get id => docId;

  @override
  Future<void> set(Map<String, dynamic> docData, [SetOptions? options]) async {
    data = docData;
    exists = true;
    _controller.add(FakeDocumentSnapshot(this));
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    if (throwOnGet) {
      throw FirebaseException(plugin: 'cloud_firestore', message: 'Simulated network error');
    }
    return FakeDocumentSnapshot(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #update) {
      if (!exists) {
        throw FirebaseException(plugin: 'cloud_firestore', message: 'Document not found');
      }
      final updateData = invocation.positionalArguments[0] as Map;
      data!.addAll(Map<String, dynamic>.from(updateData));
      _controller.add(FakeDocumentSnapshot(this));
      return Future<void>.value();
    }
    if (invocation.memberName == #snapshots) {
      Timer.run(() {
        if (exists) {
          _controller.add(FakeDocumentSnapshot(this));
        }
      });
      return _controller.stream;
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final FakeDocumentReference docRef;

  FakeDocumentSnapshot(this.docRef);

  @override
  String get id => docRef.docId;

  @override
  bool get exists => docRef.exists;

  @override
  Map<String, dynamic>? data() => docRef.data;
}

class FakeQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;
}

class FakeQueryDocumentSnapshot extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final FakeDocumentReference docRef;

  FakeQueryDocumentSnapshot(this.docRef);

  @override
  String get id => docRef.docId;

  @override
  bool get exists => docRef.exists;

  @override
  Map<String, dynamic> data() => docRef.data ?? {};
}

void main() {
  group('UserService Caching & Invalidation Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserService userService;
    late RatingService ratingService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userService = UserService(firestore: fakeFirestore);
      ratingService = RatingService(firestore: fakeFirestore);

      // Clean the static cache before each test
      UserService.invalidateCache('test_user');
      UserService.invalidateCache('helper_1');
    });

    test('Cache Hit and Miss', () async {
      // 1. Setup a user document
      final userDoc = fakeFirestore.collection('users').doc('test_user');
      await userDoc.set({'name': 'John Doe', 'skills': ['flutter', 'dart']});

      // 2. First call (Cache Miss - hits DB)
      final profile1 = await userService.getUserProfile('test_user');
      expect(profile1, isNotNull);
      expect(profile1!['name'], 'John Doe');

      // Modify the DB underlying document to verify that the next call gets cached data, not DB data
      await userDoc.update({'name': 'Jane Doe'});

      // 3. Second call (Cache Hit - hits in-memory cache)
      final profile2 = await userService.getUserProfile('test_user');
      expect(profile2, isNotNull);
      expect(profile2!['name'], 'John Doe'); // Returns the cached 'John Doe', not 'Jane Doe'
    });

    test('Deep Copy Isolation', () async {
      // 1. Setup a user document
      final userDoc = fakeFirestore.collection('users').doc('test_user');
      await userDoc.set({'name': 'John Doe', 'skills': ['flutter', 'dart']});

      // 2. Fetch the profile
      final profile1 = await userService.getUserProfile('test_user');
      expect(profile1, isNotNull);

      // 3. Mutate the returned profile (including nested list)
      profile1!['name'] = 'Mutated';
      (profile1['skills'] as List).add('python');

      // 4. Fetch the profile again - it should be unaffected because it was deep copied
      final profile2 = await userService.getUserProfile('test_user');
      expect(profile2, isNotNull);
      expect(profile2!['name'], 'John Doe');
      expect(profile2['skills'], ['flutter', 'dart']);
    });

    test('Error Recovery', () async {
      // 1. Setup doc and make it throw on fetch
      final userDoc = fakeFirestore.collection('users').doc('test_user') as FakeDocumentReference;
      await userDoc.set({'name': 'John Doe'});
      userDoc.throwOnGet = true;

      // 2. Fetch profile - should throw/fail
      try {
        await userService.getUserProfile('test_user');
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<FirebaseException>());
      }

      // 3. Turn off error and retry - should succeed and not be permanently broken
      userDoc.throwOnGet = false;
      final profile = await userService.getUserProfile('test_user');
      expect(profile, isNotNull);
      expect(profile!['name'], 'John Doe');
    });

    test('Stream Synchronization', () async {
      // 1. Setup user document
      final userDoc = fakeFirestore.collection('users').doc('test_user');
      await userDoc.set({'name': 'John Doe'});

      // 2. Subscribe to stream and wait for first event
      final stream = userService.getUserProfileStream('test_user');
      final completer = Completer<Map<String, dynamic>?>();
      final subscription = stream.listen((data) {
        if (!completer.isCompleted) {
          completer.complete(data);
        }
      });

      final streamData = await completer.future;
      expect(streamData, isNotNull);
      expect(streamData!['name'], 'John Doe');

      // 3. Modifying underlying doc to trigger stream update
      await userDoc.update({'name': 'Jane Doe'});

      // Give stream a microtask to propagate and update cache
      await Future.delayed(Duration.zero);

      // 4. Future call should now hit cache containing 'Jane Doe' from stream update
      final profile = await userService.getUserProfile('test_user');
      expect(profile, isNotNull);
      expect(profile!['name'], 'Jane Doe');

      await subscription.cancel();
    });

    test('Static Invalidation on Profile-Modifying Methods', () async {
      // 1. Create a user profile (invalidates cache)
      await userService.createUserProfile(
        userId: 'test_user',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'helper',
        skills: ['flutter'],
      );

      // 2. Fetch and cache profile
      final profile1 = await userService.getUserProfile('test_user');
      expect(profile1, isNotNull);
      expect(profile1!['skills'], ['flutter']);

      // 3. Modify skills (invalidates cache)
      await userService.updateSkills('test_user', ['flutter', 'dart']);

      // 4. Fetch - should get updated value immediately
      final profile2 = await userService.getUserProfile('test_user');
      expect(profile2, isNotNull);
      expect(profile2!['skills'], ['flutter', 'dart']);
    });

    test('Cross-Service Invalidation via RatingService', () async {
      // 1. Create helper user document
      final helperDoc = fakeFirestore.collection('users').doc('helper_1');
      await helperDoc.set({
        'name': 'Helper One',
        'role': 'helper',
        'rating': 0.0,
        'reviewCount': 0,
      });

      // 2. Fetch and cache helper profile
      final profile1 = await userService.getUserProfile('helper_1');
      expect(profile1, isNotNull);
      expect(profile1!['rating'], 0.0);

      // 3. Submit a rating (updates average rating on the user document in Firestore and calls invalidateCache)
      await ratingService.submitRating(
        helperId: 'helper_1',
        seekerId: 'seeker_1',
        jobId: 'job_123',
        overallRating: 5,
        communication: 5.0,
        punctuality: 5.0,
        quality: 5.0,
      );

      // 4. Fetch helper profile - should get the updated rating immediately because the cache was invalidated
      final profile2 = await userService.getUserProfile('helper_1');
      expect(profile2, isNotNull);
      expect(profile2!['rating'], 5.0);
      expect(profile2['reviewCount'], 1);
    });
  });
}
