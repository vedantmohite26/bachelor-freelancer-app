// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/category_service.dart';

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  int getCount = 0;
  final List<FakeQueryDocumentSnapshot> docsToReturn;
  final StreamController<QuerySnapshot<Map<String, dynamic>>> _controller =
      StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();

  FakeCollectionReference({required this.docsToReturn});

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool? descending}) {
    return this;
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return this;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getCount++;
    return FakeQuerySnapshot(docsToReturn);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return _controller.stream;
  }

  void emitSnapshot(List<FakeQueryDocumentSnapshot> docs) {
    _controller.add(FakeQuerySnapshot(docs));
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    return FakeDocumentReference();
  }

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

class FakeQueryDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  FakeQueryDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final FakeCollectionReference collectionRef;

  FakeFirebaseFirestore(this.collectionRef);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return collectionRef;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CategoryService Tests', () {
    late FakeCollectionReference fakeCollection;
    late FakeFirebaseFirestore fakeFirestore;
    late CategoryService categoryService;

    setUp(() {
      fakeCollection = FakeCollectionReference(docsToReturn: []);
      fakeFirestore = FakeFirebaseFirestore(fakeCollection);
      categoryService = CategoryService(firestore: fakeFirestore);
    });

    test('getCategories fetches default categories when collection is empty', () async {
      final categories = await categoryService.getCategories();
      expect(categories.length, equals(6));
      expect(categories.first['title'], equals('Cleaning'));
      expect(fakeCollection.getCount, equals(1));
    });

    test('getCategories uses in-memory cache on subsequent calls', () async {
      final firstFetch = await categoryService.getCategories();
      expect(fakeCollection.getCount, equals(1));

      final secondFetch = await categoryService.getCategories();
      expect(secondFetch.length, equals(firstFetch.length));
      // Should NOT increment getCount on second call due to cache hit
      expect(fakeCollection.getCount, equals(1));
    });

    test('returned categories are deep copies and cannot mutate internal cache', () async {
      final categories = await categoryService.getCategories();
      categories.first['title'] = 'Mutated Title';

      final freshFetch = await categoryService.getCategories();
      expect(freshFetch.first['title'], equals('Cleaning'));
    });

    test('clearCache resets the cache and forces a new Firestore call', () async {
      await categoryService.getCategories();
      expect(fakeCollection.getCount, equals(1));

      categoryService.clearCache();

      await categoryService.getCategories();
      expect(fakeCollection.getCount, equals(2));
    });

    test('getCategoriesStream updates cache when snapshot arrives', () async {
      final docSnapshot = FakeQueryDocumentSnapshot('cat_1', {
        'title': 'Custom Category',
        'icon': 'computer',
        'color': '#123456',
        'bgColor': '#654321',
      });

      final stream = categoryService.getCategoriesStream();
      final streamFuture = stream.first;

      fakeCollection.emitSnapshot([docSnapshot]);

      final streamResult = await streamFuture;
      expect(streamResult.length, equals(1));
      expect(streamResult.first['title'], equals('Custom Category'));

      // Subsequent getCategories() call should return the stream-cached value without additional network calls
      final cachedResult = await categoryService.getCategories();
      expect(cachedResult.length, equals(1));
      expect(cachedResult.first['title'], equals('Custom Category'));
      expect(fakeCollection.getCount, equals(0));
    });

    test('seedCategories clears the cache after adding documents', () async {
      await categoryService.getCategories(); // Fills cache
      expect(fakeCollection.getCount, equals(1));

      await categoryService.seedCategories(); // Adds documents and calls clearCache()

      await categoryService.getCategories(); // Calls Firestore again due to cleared cache
      expect(fakeCollection.getCount, equals(3)); // 1 from initial get, 1 from seed limit(1).get(), 1 from post-seed get
    });
  });
}
