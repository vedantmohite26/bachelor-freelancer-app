// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';

// Manual Mock Classes using fallback noSuchMethod
class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> collections = {};

  FakeCollectionReference collection(String path) {
    return collections.putIfAbsent(path, () => FakeCollectionReference(this));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final FakeFirebaseFirestore firestore;
  final Map<String, FakeDocumentReference> documents = {};

  FakeCollectionReference(this.firestore);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? 'temp_id';
    return documents.putIfAbsent(docId, () => FakeDocumentReference(this, docId));
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final docs = documents.values.map((doc) => FakeDocumentSnapshot(doc, doc.data)).toList();
    return FakeQuerySnapshot(docs);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    final docId = 'auto_id_${documents.length}';
    final docRef = FakeDocumentReference(this, docId);
    docRef.data = Map<String, dynamic>.from(data);
    documents[docId] = docRef;
    return docRef;
  }

  @override
  noSuchMethod(Invocation invocation) {
    // Return this for chained queries (where, orderBy, limit, etc.)
    if (invocation.memberName == #where ||
        invocation.memberName == #orderBy ||
        invocation.memberName == #limit) {
      return this;
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final FakeCollectionReference collectionRef;
  final String docId;
  Map<String, dynamic>? data;
  StreamController<DocumentSnapshot<Map<String, dynamic>>>? _controller;

  FakeDocumentReference(this.collectionRef, this.docId);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return FakeDocumentSnapshot(this, data);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    this.data = Map<String, dynamic>.from(data);
    _emitUpdate();
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (this.data == null) {
      this.data = {};
    }
    data.forEach((key, value) {
      this.data![key.toString()] = value;
    });
    _emitUpdate();
  }

  void _emitUpdate() {
    if (_controller != null && _controller!.hasListener) {
      _controller!.add(FakeDocumentSnapshot(this, data));
    }
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    _controller ??= StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast(
      onListen: () {
        _controller!.add(FakeDocumentSnapshot(this, data));
      },
    );
    return _controller!.stream;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final FakeDocumentReference docRef;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(this.docRef, this._data);

  @override
  String get id => docRef.docId;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic> data([SnapshotOptions? options]) => _data ?? {};

  @override
  DocumentReference<Map<String, dynamic>> get reference => docRef;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UserService Caching and Invalidation Tests', () {
    late FakeFirebaseFirestore mockFirestore;
    late UserService userService;
    late RatingService ratingService;

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
      userService = UserService(firestore: mockFirestore);
      ratingService = RatingService(firestore: mockFirestore);

      // Ensure cache is completely clear before each test
      UserService.invalidateCache('user123');
      UserService.invalidateCache('helper123');
    });

    test('Fetching user profile caches the future', () async {
      final docRef = mockFirestore.collection('users').doc('user123') as FakeDocumentReference;
      docRef.data = {
        'name': 'Alice Smith',
        'email': 'alice@university.edu',
        'role': 'seeker',
        'skills': ['flutter', 'dart'],
      };

      // First fetch gets from Firestore
      final profile1 = await userService.getUserProfile('user123');
      expect(profile1, isNotNull);
      expect(profile1!['name'], equals('Alice Smith'));

      // Modify Firestore underlying data directly (without going through service)
      docRef.data!['name'] = 'Alice Modified';

      // Second fetch should return cached data (not modified Firestore data)
      final profile2 = await userService.getUserProfile('user123');
      expect(profile2, isNotNull);
      expect(profile2!['name'], equals('Alice Smith')); // still original cached name
    });

    test('Deep copying prevents reference modification by parallel callers', () async {
      final docRef = mockFirestore.collection('users').doc('user123') as FakeDocumentReference;
      docRef.data = {
        'name': 'Bob Jones',
        'skills': ['python', 'react'],
      };

      final profile1 = await userService.getUserProfile('user123');
      expect(profile1, isNotNull);

      // Mutate the list in the returned map
      final skillsList = profile1!['skills'] as List;
      skillsList.add('flutter');

      // Fetch profile again
      final profile2 = await userService.getUserProfile('user123');
      expect(profile2, isNotNull);

      // The cached profile should NOT have been mutated!
      final originalSkills = profile2!['skills'] as List;
      expect(originalSkills.length, equals(2));
      expect(originalSkills.contains('flutter'), isFalse);
    });

    test('Modifying methods invalidate the cache', () async {
      final docRef = mockFirestore.collection('users').doc('user123') as FakeDocumentReference;
      docRef.data = {
        'name': 'Charlie',
        'isOnline': false,
      };

      // Fetch and cache
      final profile1 = await userService.getUserProfile('user123');
      expect(profile1!['isOnline'], isFalse);

      // Call profile modifying method (e.g. updateOnlineStatus)
      await userService.updateOnlineStatus('user123', true);

      // Fetch profile again - should get updated value because cache was invalidated
      final profile2 = await userService.getUserProfile('user123');
      expect(profile2!['isOnline'], isTrue);
    });

    test('Stream listener updates cache with new snapshot data automatically', () async {
      final docRef = mockFirestore.collection('users').doc('user123') as FakeDocumentReference;
      docRef.data = {
        'name': 'Delta',
        'points': 100,
      };

      // Start listening to the stream
      final stream = userService.getUserProfileStream('user123');
      final completer = Completer<Map<String, dynamic>?>();
      final subscription = stream.listen((profile) {
        if (!completer.isCompleted) {
          completer.complete(profile);
        }
      });

      // Wait for initial value
      final initialProfile = await completer.future;
      expect(initialProfile!['points'], equals(100));

      // Fetch via future - should hit the stream-updated cache
      // We directly update Firestore data to simulate another client change
      docRef.data!['points'] = 200;
      docRef.update({'points': 200}); // Triggers stream controller event

      // Allow event to propagate
      await Future.delayed(Duration.zero);

      final cachedProfile = await userService.getUserProfile('user123');
      expect(cachedProfile!['points'], equals(200));

      await subscription.cancel();
    });

    test('Cross-service rating update invalidates cache of the helper', () async {
      final helperRef = mockFirestore.collection('users').doc('helper123') as FakeDocumentReference;
      helperRef.data = {
        'name': 'Helper Hero',
        'rating': 4.5,
        'reviewCount': 5,
      };

      // Cache the helper profile
      final cachedHelper1 = await userService.getUserProfile('helper123');
      expect(cachedHelper1!['rating'], equals(4.5));

      // Call RatingService submitRating to rate helper
      await ratingService.submitRating(
        helperId: 'helper123',
        seekerId: 'seeker123',
        jobId: 'job_xyz_999',
        overallRating: 5,
        communication: 5.0,
        punctuality: 5.0,
        quality: 5.0,
        feedback: 'Excellent work!',
      );

      // Since the average rating updated to 5.0, we check if the future gets the fresh profile
      final cachedHelper2 = await userService.getUserProfile('helper123');
      expect(cachedHelper2!['rating'], equals(5.0));
      expect(cachedHelper2['reviewCount'], equals(1));
    });
  });
}
