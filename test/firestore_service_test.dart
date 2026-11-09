// ignore_for_file: subtype_of_sealed_class, unnecessary_no_such_method

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/firestore_service.dart';

// Manual Fake / Mock implementations for FirebaseFirestore and its query components

class FakeQueryDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> _data;

  FakeQueryDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic> data() => Map<String, dynamic>.from(_data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  FakeQuerySnapshot(this.docs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;
  final bool _exists;

  FakeDocumentSnapshot(this.id, this._data, {bool exists = true})
      : _exists = exists;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data != null ? Map<String, dynamic>.from(_data) : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  @override
  final String id;
  @override
  final FakeFirebaseFirestore firestore;
  final String collectionPath;

  FakeDocumentReference(this.id, this.firestore, this.collectionPath);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    final existing = firestore.store[collectionPath]?[id] ?? <String, dynamic>{};
    if (options?.merge == true) {
      existing.addAll(data);
      firestore.store.putIfAbsent(collectionPath, () => {})[id] = existing;
    } else {
      firestore.store.putIfAbsent(collectionPath, () => {})[id] = Map<String, dynamic>.from(data);
    }
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final data = firestore.store[collectionPath]?[id];
    return FakeDocumentSnapshot(id, data, exists: data != null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuery implements Query<Map<String, dynamic>> {
  @override
  final FakeFirebaseFirestore firestore;
  final String collectionPath;
  final List<QueryFilter> filters;
  final String? orderByField;
  final bool descending;
  final int? limitCount;

  FakeQuery(
    this.firestore,
    this.collectionPath, {
    this.filters = const [],
    this.orderByField,
    this.descending = false,
    this.limitCount,
  });

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
    final newFilters = List<QueryFilter>.from(filters)
      ..add(QueryFilter(field.toString(), isEqualTo: isEqualTo));
    return FakeQuery(
      firestore,
      collectionPath,
      filters: newFilters,
      orderByField: orderByField,
      descending: descending,
      limitCount: limitCount,
    );
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return FakeQuery(
      firestore,
      collectionPath,
      filters: filters,
      orderByField: field.toString(),
      descending: descending,
      limitCount: limitCount,
    );
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return FakeQuery(
      firestore,
      collectionPath,
      filters: filters,
      orderByField: orderByField,
      descending: descending,
      limitCount: limit,
    );
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>();

    void emit() {
      final collectionData = firestore.store[collectionPath] ?? {};
      List<FakeQueryDocumentSnapshot> docs = [];

      for (final entry in collectionData.entries) {
        final data = entry.value;
        bool matches = true;
        for (final filter in filters) {
          if (filter.isEqualTo != null && data[filter.field] != filter.isEqualTo) {
            matches = false;
            break;
          }
        }
        if (matches) {
          docs.add(FakeQueryDocumentSnapshot(entry.key, data));
        }
      }

      if (limitCount != null && docs.length > limitCount!) {
        docs = docs.sublist(0, limitCount!);
      }

      controller.add(FakeQuerySnapshot(docs));
    }

    emit();
    final sub = firestore.changeStream.listen((_) => emit());
    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class QueryFilter {
  final String field;
  final dynamic isEqualTo;

  QueryFilter(this.field, {this.isEqualTo});
}

class FakeCollectionReference extends FakeQuery
    implements CollectionReference<Map<String, dynamic>> {
  FakeCollectionReference(super.firestore, super.collectionPath);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? 'doc_${DateTime.now().microsecondsSinceEpoch}';
    return FakeDocumentReference(docId, firestore, collectionPath);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    final docId = 'doc_${DateTime.now().microsecondsSinceEpoch}';
    firestore.store.putIfAbsent(collectionPath, () => {})[docId] = Map<String, dynamic>.from(data);
    firestore.notify();
    return FakeDocumentReference(docId, firestore, collectionPath);
  }
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, Map<String, Map<String, dynamic>>> store = {};
  final StreamController<void> _changeController = StreamController<void>.broadcast();

  Stream<void> get changeStream => _changeController.stream;

  void notify() {
    _changeController.add(null);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(this, collectionPath);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FirestoreService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = FirestoreService(firestore: fakeFirestore);
    });

    test('saveUserProfile and getUserProfile works correctly', () async {
      await service.saveUserProfile('user_123', {
        'name': 'Alice Smith',
        'role': 'seeker',
      });

      final profile = await service.getUserProfile('user_123');
      expect(profile, isNotNull);
      expect(profile!['name'], 'Alice Smith');
      expect(profile['role'], 'seeker');

      // Test merging updates
      await service.saveUserProfile('user_123', {
        'rating': 4.8,
      });

      final updatedProfile = await service.getUserProfile('user_123');
      expect(updatedProfile!['name'], 'Alice Smith');
      expect(updatedProfile['rating'], 4.8);
    });

    test('createJob adds job with open status and server timestamp', () async {
      await service.createJob({
        'title': 'Need physics tutoring',
        'posterId': 'user_123',
        'budget': 500,
      });

      final jobsCollection = fakeFirestore.store['jobs'];
      expect(jobsCollection, isNotNull);
      expect(jobsCollection!.length, 1);

      final job = jobsCollection.values.first;
      expect(job['title'], 'Need physics tutoring');
      expect(job['status'], 'open');
      expect(job['posterId'], 'user_123');
    });

    test('getJobsStream returns open jobs and includes document id', () async {
      fakeFirestore.store['jobs'] = {
        'job_1': {
          'title': 'Job 1',
          'status': 'open',
          'posterId': 'user_A',
        },
        'job_2': {
          'title': 'Job 2',
          'status': 'closed',
          'posterId': 'user_B',
        },
        'job_3': {
          'title': 'Job 3',
          'status': 'open',
          'posterId': 'user_C',
        },
      };

      final stream = service.getJobsStream();
      final jobs = await stream.first;

      expect(jobs.length, 2);
      expect(jobs.map((j) => j['id']).toList(), containsAll(['job_1', 'job_3']));
      expect(jobs.map((j) => j['id']).toList(), isNot(contains('job_2')));
    });

    test('getJobsStream filters out jobs posted by currentUserId', () async {
      fakeFirestore.store['jobs'] = {
        'job_1': {
          'title': 'Job 1',
          'status': 'open',
          'posterId': 'user_A',
        },
        'job_2': {
          'title': 'Job 2',
          'status': 'open',
          'posterId': 'user_B',
        },
      };

      final stream = service.getJobsStream(currentUserId: 'user_A');
      final jobs = await stream.first;

      expect(jobs.length, 1);
      expect(jobs.first['id'], 'job_2');
      expect(jobs.first['posterId'], 'user_B');
    });
  });
}
