import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/rewards_service.dart';

// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic get(Object field) => _data[field];

  @override
  dynamic operator [](Object field) => _data[field];

  @override
  bool get exists => true;

  @override
  DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
}

class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  FakeQuerySnapshot(this.docs);

  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => [];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  int get size => docs.length;
}

// ignore: subtype_of_sealed_class
class FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final StreamController<QuerySnapshot<Map<String, dynamic>>> _controller;

  FakeQuery(this._controller);

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return _controller.stream;
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) => this;
}

// ignore: subtype_of_sealed_class
class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final Map<String, StreamController<QuerySnapshot<Map<String, dynamic>>>> controllers;

  FakeCollectionReference(this.controllers);

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
    final category = isEqualTo as String;
    controllers.putIfAbsent(category, () => StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast());
    return FakeQuery(controllers[category]!);
  }
}

class FakeFirestore extends Fake implements FirebaseFirestore {
  final controllers = <String, StreamController<QuerySnapshot<Map<String, dynamic>>>>{};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(controllers);
  }
}

void main() {
  group('RewardsService Unit Tests', () {
    late FakeFirestore fakeFirestore;
    late RewardsService rewardsService;

    setUp(() {
      fakeFirestore = FakeFirestore();
      rewardsService = RewardsService(firestore: fakeFirestore);
    });

    test('getRewards emits filtered, mapped, and sorted rewards list', () async {
      final rewardsStream = rewardsService.getRewards('redeem_code');

      final expectFuture = expectLater(
        rewardsStream,
        emits(
          predicate<List<Map<String, dynamic>>>((list) {
            if (list.length != 2) return false;
            if (list[0]['id'] != 'doc_1' || list[0]['title'] != 'Google Play ₹10') return false;
            if (list[1]['id'] != 'doc_2' || list[1]['title'] != 'Amazon ₹50') return false;
            return true;
          }),
        ),
      );

      final controller = fakeFirestore.controllers['redeem_code']!;
      controller.add(FakeQuerySnapshot([
        FakeDocumentSnapshot('doc_1', {
          'title': 'Google Play ₹10',
          'cost': 1000,
          'category': 'redeem_code',
        }),
        FakeDocumentSnapshot('doc_2', {
          'title': 'Amazon ₹50',
          'cost': 4500,
          'category': 'redeem_code',
        }),
      ]));

      await expectFuture;
    });
  });
}
