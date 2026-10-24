// ignore_for_file: subtype_of_sealed_class, must_be_immutable

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/user_service.dart';

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final String _id;
  final bool _exists;

  FakeDocumentSnapshot(this._id, this._data, this._exists);

  @override
  String get id => _id;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final String _id;
  final Map<String, Map<String, dynamic>> _storage;
  int getCount = 0;

  FakeDocumentReference(this._id, this._storage);

  @override
  String get id => _id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getCount++;
    final data = _storage[_id];
    return FakeDocumentSnapshot(_id, data, data != null);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (_storage.containsKey(_id)) {
      _storage[_id]!.addAll(data.cast<String, dynamic>());
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _storage;
  final Map<String, FakeDocumentReference> docRefs = {};

  FakeCollectionReference(this._storage);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? 'generated_id';
    return docRefs.putIfAbsent(
      docId,
      () => FakeDocumentReference(docId, _storage),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWriteBatch implements WriteBatch {
  @override
  Future<void> commit() async {}

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> usersStorage = {};
  late final FakeCollectionReference usersCollection;

  FakeFirebaseFirestore() {
    usersCollection = FakeCollectionReference(usersStorage);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    if (collectionPath == 'users') {
      return usersCollection;
    }
    return FakeCollectionReference({});
  }

  @override
  WriteBatch batch() => FakeWriteBatch();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UserService Caching & Functionality Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserService userService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userService = UserService(firestore: fakeFirestore);

      fakeFirestore.usersStorage['user_1'] = {
        'name': 'Alice Smith',
        'email': 'alice@example.com',
        'role': 'helper',
        'skills': ['Flutter', 'Dart'],
      };
    });

    test('getUserProfile caches subsequent profile fetches', () async {
      final docRef = fakeFirestore.usersCollection.doc('user_1') as FakeDocumentReference;
      expect(docRef.getCount, 0);

      final profile1 = await userService.getUserProfile('user_1');
      expect(profile1, isNotNull);
      expect(profile1!['name'], 'Alice Smith');
      expect(docRef.getCount, 1);

      final profile2 = await userService.getUserProfile('user_1');
      expect(profile2, isNotNull);
      expect(profile2!['name'], 'Alice Smith');
      // getCount must still be 1 because the second request was served from cache
      expect(docRef.getCount, 1);
    });

    test('getUserProfile returns deep copies isolating cached state from mutation', () async {
      final profile1 = await userService.getUserProfile('user_1');
      expect(profile1, isNotNull);

      // Mutate returned map
      profile1!['name'] = 'Mutated Name';
      (profile1['skills'] as List).add('Hacking');

      // Fetch again from cache
      final profile2 = await userService.getUserProfile('user_1');
      expect(profile2, isNotNull);
      expect(profile2!['name'], 'Alice Smith');
      expect(profile2['skills'], ['Flutter', 'Dart']);
    });

    test('updateProfile invalidates cache and fetches fresh data on subsequent calls', () async {
      final docRef = fakeFirestore.usersCollection.doc('user_1') as FakeDocumentReference;

      final profile1 = await userService.getUserProfile('user_1');
      expect(profile1!['name'], 'Alice Smith');
      expect(docRef.getCount, 1);

      // Update profile
      await userService.updateProfile('user_1', {'name': 'Alice Johnson'});

      // Next call should fetch from Firestore
      final profile2 = await userService.getUserProfile('user_1');
      expect(docRef.getCount, 2);
      expect(profile2!['name'], 'Alice Johnson');
    });

    test('invalidateCache and clearCache remove cached entries', () async {
      final docRef = fakeFirestore.usersCollection.doc('user_1') as FakeDocumentReference;

      await userService.getUserProfile('user_1');
      expect(docRef.getCount, 1);

      userService.invalidateCache('user_1');

      await userService.getUserProfile('user_1');
      expect(docRef.getCount, 2);

      userService.clearCache();

      await userService.getUserProfile('user_1');
      expect(docRef.getCount, 3);
    });

    test('getUserProfile with empty userId returns null without Firestore call', () async {
      final profile = await userService.getUserProfile('');
      expect(profile, isNull);
    });
  });
}
