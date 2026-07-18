// ignore_for_file: subtype_of_sealed_class, must_be_immutable, prefer_const_declarations

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/user_service.dart';

// Manual mocks for Firestore
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
  final Map<String, dynamic>? _data;
  final bool _exists;
  int getCalls = 0;

  FakeDocumentReference(this._id, this._data, this._exists);

  @override
  String get id => _id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getCalls++;
    return FakeDocumentSnapshot(_id, _data, _exists);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final Map<String, FakeDocumentReference> _docs;

  FakeCollectionReference(this._docs);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return _docs[path] ?? FakeDocumentReference(path ?? 'unknown', null, false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> _collections;

  FakeFirebaseFirestore(this._collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _collections[path] ?? FakeCollectionReference({});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UserService In-Memory Cache Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FakeDocumentReference fakeDocRef;
    late UserService userService;
    const String testUserId = 'test_user_123';
    final Map<String, dynamic> testProfileData = {
      'name': 'Test Helper',
      'email': 'helper@test.com',
      'role': 'helper',
      'points': 100,
    };

    setUp(() {
      // Setup fake document and reference
      fakeDocRef = FakeDocumentReference(testUserId, testProfileData, true);

      final fakeCollection = FakeCollectionReference({
        testUserId: fakeDocRef,
      });

      fakeFirestore = FakeFirebaseFirestore({
        'users': fakeCollection,
      });

      userService = UserService(firestore: fakeFirestore);

      // Ensure cache is completely cleared before each test
      UserService.invalidateCache(testUserId);
    });

    test('getUserProfile caches the Future and avoids redundant Firestore gets', () async {
      // First fetch: should trigger a Firestore read
      final profile1 = await userService.getUserProfile(testUserId);
      expect(profile1, isNotNull);
      expect(profile1?['name'], equals('Test Helper'));
      expect(fakeDocRef.getCalls, equals(1));

      // Second fetch: should return from in-memory cache and not call Firestore get
      final profile2 = await userService.getUserProfile(testUserId);
      expect(profile2, isNotNull);
      expect(profile2?['name'], equals('Test Helper'));
      expect(fakeDocRef.getCalls, equals(1)); // Still 1!
    });

    test('getUserProfile returns deep copies of the cached data to prevent accidental UI mutations', () async {
      final profile1 = await userService.getUserProfile(testUserId);
      expect(profile1?['points'], equals(100));

      // Mutate the returned map
      profile1?['points'] = 999;

      // Fetch again
      final profile2 = await userService.getUserProfile(testUserId);

      // The cached map should remain unmutated (value 100)
      expect(profile2?['points'], equals(100));
    });

    test('invalidateCache removes the profile from the cache', () async {
      // First fetch
      await userService.getUserProfile(testUserId);
      expect(fakeDocRef.getCalls, equals(1));

      // Invalidate
      UserService.invalidateCache(testUserId);

      // Second fetch should trigger another get call
      await userService.getUserProfile(testUserId);
      expect(fakeDocRef.getCalls, equals(2));
    });
  });
}
