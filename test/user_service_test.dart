// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';

// Manual Mock/Fake classes for Firestore to test services without real Firebase initialization
class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> collections = {};
  final List<FakeWriteBatch> batches = [];

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return collections.putIfAbsent(path, () => FakeCollectionReference(path, this)) as CollectionReference<Map<String, dynamic>>;
  }

  @override
  WriteBatch batch() {
    final b = FakeWriteBatch(this);
    batches.add(b);
    return b;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWriteBatch implements WriteBatch {
  final FakeFirebaseFirestore firestore;
  final List<Function()> operations = [];

  FakeWriteBatch(this.firestore);

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    operations.add(() => (document as FakeDocumentReference).setData(data as Map<String, dynamic>));
  }

  @override
  Future<void> commit() async {
    for (var op in operations) {
      op();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final String path;
  final FakeFirebaseFirestore firestore;
  final Map<String, FakeDocumentReference> documents = {};
  final List<StreamController<QuerySnapshot<Map<String, dynamic>>>> queryControllers = [];

  FakeCollectionReference(this.path, this.firestore);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final id = path ?? 'doc_${documents.length}';
    return documents.putIfAbsent(id, () => FakeDocumentReference(id, this)) as DocumentReference<Map<String, dynamic>>;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final docs = documents.values
        .where((d) => d.data != null)
        .map((d) => FakeQueryDocumentSnapshot(d.id, d.data!, d) as QueryDocumentSnapshot<Map<String, dynamic>>)
        .toList();
    return FakeQuerySnapshot(docs);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    final id = 'doc_${documents.length}';
    final docRef = FakeDocumentReference(id, this);
    docRef.setData(data);
    documents[id] = docRef;
    return docRef;
  }

  void _notifyCollectionChanged() {
    final docs = documents.values
        .where((d) => d.data != null)
        .map((d) => FakeQueryDocumentSnapshot(d.id, d.data!, d) as QueryDocumentSnapshot<Map<String, dynamic>>)
        .toList();
    for (var controller in queryControllers) {
      if (!controller.isClosed) {
        controller.add(FakeQuerySnapshot(docs));
      }
    }
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({bool includeMetadataChanges = false, ListenSource source = ListenSource.defaultSource}) {
    late StreamController<QuerySnapshot<Map<String, dynamic>>> controller;
    controller = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast(
      onListen: () {
        final docs = documents.values
            .where((d) => d.data != null)
            .map((d) => FakeQueryDocumentSnapshot(d.id, d.data!, d) as QueryDocumentSnapshot<Map<String, dynamic>>)
            .toList();
        controller.add(FakeQuerySnapshot(docs));
      },
    );
    queryControllers.add(controller);
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains("where") || name.contains("orderBy") || name.contains("limit")) {
      return this;
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final String id;
  final FakeCollectionReference parent;
  Map<String, dynamic>? data;
  final List<StreamController<DocumentSnapshot<Map<String, dynamic>>>> controllers = [];
  int fetchCount = 0;

  FakeDocumentReference(this.id, this.parent);

  void setData(Map<String, dynamic> newData) {
    data = Map<String, dynamic>.from(newData);
    for (var controller in controllers) {
      if (!controller.isClosed) {
        controller.add(toSnapshot());
      }
    }
    parent._notifyCollectionChanged();
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    setData(data);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (this.data == null) {
      this.data = {};
    }
    data.forEach((key, value) {
      this.data![key.toString()] = value;
    });
    for (var controller in controllers) {
      if (!controller.isClosed) {
        controller.add(toSnapshot());
      }
    }
    parent._notifyCollectionChanged();
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    fetchCount++;
    return toSnapshot();
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({bool includeMetadataChanges = false, ListenSource source = ListenSource.defaultSource}) {
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> controller;
    controller = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast(
      onListen: () {
        controller.add(toSnapshot());
      },
    );
    controllers.add(controller);
    return controller.stream;
  }

  FakeDocumentSnapshot toSnapshot() {
    return FakeDocumentSnapshot(id, data, this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic>? _data;
  final DocumentReference<Map<String, dynamic>> _reference;

  FakeDocumentSnapshot(this._id, this._data, this._reference);

  @override
  String get id => _id;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  DocumentReference<Map<String, dynamic>> get reference => _reference;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQueryDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic>? _data;
  final DocumentReference<Map<String, dynamic>> _reference;

  FakeQueryDocumentSnapshot(this._id, this._data, this._reference);

  @override
  String get id => _id;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic> data() => _data ?? {};

  @override
  DocumentReference<Map<String, dynamic>> get reference => _reference;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UserService Caching and Consistency Tests', () {
    late FakeFirebaseFirestore mockFirestore;
    late UserService userService;
    late RatingService ratingService;

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
      userService = UserService(firestore: mockFirestore);
      ratingService = RatingService(firestore: mockFirestore);

      // Ensure the cache starts empty for each test
      UserService.invalidateCache('user_1');
      UserService.invalidateCache('helper_1');
    });

    test('getUserProfile caches results and minimizes Firestore fetches', () async {
      final docRef = mockFirestore.collection('users').doc('user_1') as FakeDocumentReference;
      docRef.setData({
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'seeker',
        'skills': ['Dart', 'Flutter'],
      });

      expect(docRef.fetchCount, 0);

      // First call: fetches from Firestore
      final profile1 = await userService.getUserProfile('user_1');
      expect(profile1, isNotNull);
      expect(profile1!['name'], 'John Doe');
      expect(docRef.fetchCount, 1);

      // Second call: should hit the in-memory cache and not increment fetchCount
      final profile2 = await userService.getUserProfile('user_1');
      expect(profile2, isNotNull);
      expect(profile2!['name'], 'John Doe');
      expect(docRef.fetchCount, 1); // Remains 1, proving it was cached!
    });

    test('getUserProfile returns deep copies to prevent reference mutation', () async {
      final docRef = mockFirestore.collection('users').doc('user_1') as FakeDocumentReference;
      docRef.setData({
        'name': 'John Doe',
        'skills': ['Dart', 'Flutter'],
      });

      final profile1 = await userService.getUserProfile('user_1');
      expect(profile1, isNotNull);

      // Mutate the returned profile nested collection
      final skills1 = profile1!['skills'] as List;
      skills1.add('Firebase');

      // Fetch again from cache
      final profile2 = await userService.getUserProfile('user_1');
      expect(profile2, isNotNull);

      final skills2 = profile2!['skills'] as List;
      // The cached copy must NOT be mutated!
      expect(skills2.contains('Firebase'), isFalse);
      expect(skills2.length, 2);
    });

    test('Cache is automatically invalidated when profiles are updated via UserService', () async {
      final docRef = mockFirestore.collection('users').doc('user_1') as FakeDocumentReference;
      docRef.setData({
        'name': 'John Doe',
        'isOnline': false,
      });

      // Warm up the cache
      await userService.getUserProfile('user_1');
      expect(docRef.fetchCount, 1);

      // This should invalidate the cache
      await userService.updateOnlineStatus('user_1', true);

      // Fetch again: should perform a new Firestore get
      final profile = await userService.getUserProfile('user_1');
      expect(profile!['isOnline'], true);
      expect(docRef.fetchCount, 2); // Increased to 2, proving invalidation worked!
    });

    test('getUserProfileStream updates in-memory cache with real-time data', () async {
      final docRef = mockFirestore.collection('users').doc('user_1') as FakeDocumentReference;
      docRef.setData({
        'name': 'John Doe',
        'isOnline': false,
      });

      // Keep the stream subscription active to trigger real-time cache updates
      final subscription = userService.getUserProfileStream('user_1').listen((_) {});

      // Wait brief duration for first event to propagate and fill the cache
      await Future.delayed(Duration.zero);

      // Verify first cache state
      var cachedProfile = await userService.getUserProfile('user_1');
      expect(cachedProfile!['isOnline'], false);

      // Changing data on DocumentReference directly (simulating real-time server-side update)
      docRef.setData({
        'name': 'John Doe',
        'isOnline': true,
      });

      // Wait brief duration for stream map callbacks to propagate
      await Future.delayed(Duration.zero);

      // Future fetch should retrieve the real-time updated online status without executing extra Firestore gets
      final profile = await userService.getUserProfile('user_1');
      expect(profile!['isOnline'], true);
      expect(docRef.fetchCount, 0); // Proof: No explicit futures/get calls made, cache fully fed by real-time stream!

      await subscription.cancel();
    });

    test('RatingService updates correctly invalidate helper cache cross-service', () async {
      final helperDoc = mockFirestore.collection('users').doc('helper_1') as FakeDocumentReference;
      helperDoc.setData({
        'name': 'Expert Helper',
        'role': 'helper',
        'rating': 0.0,
        'reviewCount': 0,
      });

      // Warm up helper's profile cache
      await userService.getUserProfile('helper_1');
      expect(helperDoc.fetchCount, 1);

      // Submit rating via RatingService (which invokes _updateHelperRating)
      await ratingService.submitRating(
        helperId: 'helper_1',
        seekerId: 'seeker_1',
        jobId: 'job_123',
        overallRating: 5,
        communication: 5.0,
        punctuality: 5.0,
        quality: 5.0,
        feedback: 'Superb work!',
      );

      // Fetch helper's profile again: should make a new database call due to cross-service cache invalidation
      final updatedProfile = await userService.getUserProfile('helper_1');
      expect(updatedProfile!['rating'], 5.0);
      expect(updatedProfile['reviewCount'], 1);
      expect(helperDoc.fetchCount, 2); // Cache successfully invalidated!
    });
  });
}
