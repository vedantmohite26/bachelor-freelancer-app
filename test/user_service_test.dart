// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic operator [](Object field) => _data?[field];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final String _id;
  final FakeFirebaseFirestore _db;

  FakeDocumentReference(this._id, this._db);

  @override
  String get id => _id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    if (_db.throwOnGet) {
      throw FirebaseException(plugin: 'cloud_firestore', message: 'Simulated Firestore failure');
    }
    _db.getCallsCount++;
    final data = _db.data[_id];
    return FakeDocumentSnapshot(_id, data);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    _db.updateCallsCount++;
    if (!_db.data.containsKey(_id)) {
      _db.data[_id] = {};
    }
    data.forEach((key, value) {
      _db.data[_id]![key.toString()] = value;
    });
    _db.notifySnapshots(_id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #snapshots) {
      _db.streamControllerMap.putIfAbsent(_id, () => StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast());

      final currentData = _db.data[_id];
      final controller = _db.streamControllerMap[_id]!;

      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(FakeDocumentSnapshot(_id, currentData));
        }
      });

      return controller.stream;
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final FakeFirebaseFirestore _db;
  final String _path;

  FakeCollectionReference(this._db, this._path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return FakeDocumentReference(path ?? 'auto_id', _db);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(dynamic data) async {
    final docId = 'rating_${_db.data.length + 1}';
    final stringKeyedMap = <String, dynamic>{};
    (data as Map).forEach((k, v) {
      stringKeyedMap[k.toString()] = v;
    });
    _db.data[docId] = stringKeyedMap;
    return FakeDocumentReference(docId, _db);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where || invocation.memberName == #orderBy || invocation.memberName == #limit) {
      final query = FakeQuery(_db, _path);
      return query.noSuchMethod(invocation);
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeQuery implements Query<Map<String, dynamic>> {
  final FakeFirebaseFirestore _db;
  final String _path;
  final String? _seekerIdFilter;
  final String? _jobIdFilter;

  FakeQuery(this._db, this._path, {String? seekerIdFilter, String? jobIdFilter})
      : _seekerIdFilter = seekerIdFilter,
        _jobIdFilter = jobIdFilter;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      final field = invocation.positionalArguments[0];
      final isEqualTo = invocation.namedArguments[#isEqualTo];
      if (field == 'seekerId' && isEqualTo is String) {
        return FakeQuery(_db, _path, seekerIdFilter: isEqualTo, jobIdFilter: _jobIdFilter);
      }
      if (field == 'jobId' && isEqualTo is String) {
        return FakeQuery(_db, _path, seekerIdFilter: _seekerIdFilter, jobIdFilter: isEqualTo);
      }
      return this;
    }
    if (invocation.memberName == #orderBy || invocation.memberName == #limit) {
      return this;
    }
    if (invocation.memberName == #get) {
      if (_path == 'ratings') {
        var docs = _db.data.entries
            .where((e) => e.value.containsKey('overallRating'));

        if (_seekerIdFilter != null) {
          docs = docs.where((e) => e.value['seekerId'] == _seekerIdFilter);
        }
        if (_jobIdFilter != null) {
          docs = docs.where((e) => e.value['jobId'] == _jobIdFilter);
        }

        final queryDocs = docs
            .map((e) => FakeQueryDocumentSnapshot(e.key, e.value))
            .toList();
        return Future.value(FakeQuerySnapshot(queryDocs));
      }
      return Future.value(FakeQuerySnapshot([]));
    }
    return super.noSuchMethod(invocation);
  }
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
  bool get exists => true;

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

class FakeWriteBatch implements WriteBatch {
  final FakeFirebaseFirestore _db;
  final Map<String, Map<String, dynamic>> _operations = {};

  FakeWriteBatch(this._db);

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    final docRef = document as FakeDocumentReference;
    _operations[docRef._id] = data as Map<String, dynamic>;
  }

  @override
  Future<void> commit() async {
    _operations.forEach((id, data) {
      _db.data[id] = Map<String, dynamic>.from(data);
      _db.notifySnapshots(id);
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> data = {};
  final Map<String, StreamController<DocumentSnapshot<Map<String, dynamic>>>> streamControllerMap = {};
  int getCallsCount = 0;
  int updateCallsCount = 0;
  bool throwOnGet = false;

  void notifySnapshots(String id) {
    if (streamControllerMap.containsKey(id)) {
      final currentData = data[id];
      streamControllerMap[id]!.add(FakeDocumentSnapshot(id, currentData));
    }
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(this, collectionPath);
  }

  @override
  WriteBatch batch() {
    return FakeWriteBatch(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRatingService extends RatingService {
  FakeRatingService(FirebaseFirestore db) : super(firestore: db);
}

void main() {
  late FakeFirebaseFirestore db;
  late UserService userService;

  setUp(() {
    db = FakeFirebaseFirestore();
    userService = UserService(firestore: db);
    // Clear static cache before each test
    UserService.invalidateCache('user_1');
    UserService.invalidateCache('helper_1');
  });

  group('UserService Caching and Performance Optimization Tests', () {
    test('getUserProfile fetches from firestore on first call and caches the result for future calls', () async {
      db.data['user_1'] = {'name': 'Alice', 'role': 'seeker'};

      // First call (cache miss)
      final profile1 = await userService.getUserProfile('user_1');
      expect(profile1, isNotNull);
      expect(profile1!['name'], 'Alice');
      expect(db.getCallsCount, 1);

      // Second call (cache hit)
      final profile2 = await userService.getUserProfile('user_1');
      expect(profile2, isNotNull);
      expect(profile2!['name'], 'Alice');
      expect(db.getCallsCount, 1); // getCallsCount should still be 1!
    });

    test('getUserProfile deep copies the returned profile data to avoid internal cache mutation', () async {
      db.data['user_1'] = {'name': 'Alice', 'role': 'seeker', 'skills': ['typing']};

      final profile1 = await userService.getUserProfile('user_1');
      expect(profile1, isNotNull);

      // Mutate the returned profile
      profile1!['name'] = 'Bob';
      (profile1['skills'] as List).add('writing');

      // Fetch again from cache
      final profile2 = await userService.getUserProfile('user_1');
      expect(profile2, isNotNull);
      // Ensure the cache is unmutated!
      expect(profile2!['name'], 'Alice');
      expect((profile2['skills'] as List), contains('typing'));
      expect((profile2['skills'] as List), isNot(contains('writing')));
    });

    test('invalidateCache correctly forces a refetch from Firestore', () async {
      db.data['user_1'] = {'name': 'Alice', 'role': 'seeker'};

      // Cache it
      await userService.getUserProfile('user_1');
      expect(db.getCallsCount, 1);

      // Invalidate
      UserService.invalidateCache('user_1');

      // Fetch again
      final profile = await userService.getUserProfile('user_1');
      expect(profile!['name'], 'Alice');
      expect(db.getCallsCount, 2); // Should trigger a second Firestore get
    });

    test('profile-altering methods invalidate the cache after successful update', () async {
      db.data['user_1'] = {'name': 'Alice', 'role': 'seeker', 'isOnline': false};

      // Cache the initial profile
      final initial = await userService.getUserProfile('user_1');
      expect(initial!['isOnline'], false);
      expect(db.getCallsCount, 1);

      // Update online status
      await userService.updateOnlineStatus('user_1', true);
      expect(db.updateCallsCount, 1);

      // Fetch profile again
      final updated = await userService.getUserProfile('user_1');
      expect(updated!['isOnline'], true);
      expect(db.getCallsCount, 2); // getCallsCount incremented, meaning cache was invalidated and refetched!
    });

    test('failed profile futures are successfully evicted from cache to allow recovery', () async {
      db.throwOnGet = true;

      // This should throw error
      await expectLater(userService.getUserProfile('user_1'), throwsA(isA<FirebaseException>()));

      // Set throw to false
      db.throwOnGet = false;
      db.data['user_1'] = {'name': 'Charlie', 'role': 'helper'};

      // Should recover and successfully fetch rather than returning a failed future
      final profile = await userService.getUserProfile('user_1');
      expect(profile, isNotNull);
      expect(profile!['name'], 'Charlie');
      expect(db.getCallsCount, 1);
    });

    test('getUserProfileStream automatically populates and keeps the static cache in sync', () async {
      db.data['user_1'] = {'name': 'Initial', 'role': 'helper'};

      final completer1 = Completer<Map<String, dynamic>?>();
      final completer2 = Completer<Map<String, dynamic>?>();
      int emitCount = 0;

      final subscription = userService.getUserProfileStream('user_1').listen((data) {
        emitCount++;
        if (emitCount == 1) {
          completer1.complete(data);
        } else if (emitCount == 2) {
          completer2.complete(data);
        }
      });

      // Wait for initial value
      final snapshot1 = await completer1.future;
      expect(snapshot1!['name'], 'Initial');

      // Fetch via future - should hit the cache pre-populated by stream
      final profile = await userService.getUserProfile('user_1');
      expect(profile!['name'], 'Initial');
      expect(db.getCallsCount, 0); // No direct get() call! Stream populated the cache!

      // Update stream data
      db.data['user_1'] = {'name': 'UpdatedStream', 'role': 'helper'};
      db.notifySnapshots('user_1');

      // Wait for stream to emit new value
      final snapshot2 = await completer2.future;
      expect(snapshot2!['name'], 'UpdatedStream');

      // Fetch via future - should return new stream data without Firestore get call
      final profileUpdated = await userService.getUserProfile('user_1');
      expect(profileUpdated!['name'], 'UpdatedStream');
      expect(db.getCallsCount, 0); // Still 0! Cache stayed in perfect sync!

      await subscription.cancel();
    });

    test('RatingService submitRating invalidates cached helper profile after updating helper ratings', () async {
      db.data['helper_1'] = {'name': 'Skilled Helper', 'role': 'helper', 'rating': 0.0, 'reviewCount': 0};

      // Cache helper profile
      final helperProfile = await userService.getUserProfile('helper_1');
      expect(helperProfile!['rating'], 0.0);
      expect(db.getCallsCount, 1);

      // Create a fake RatingService
      final ratingService = FakeRatingService(db);

      // Add a rating record in DB
      db.data['rating_doc_1'] = {
        'helperId': 'helper_1',
        'seekerId': 'seeker_1',
        'jobId': 'job_1',
        'overallRating': 5,
        'communication': 5.0,
        'punctuality': 5.0,
        'quality': 5.0,
        'createdAt': Timestamp.now(),
      };

      // Update average helper rating (submitting rating triggers this internally)
      await ratingService.submitRating(
        helperId: 'helper_1',
        seekerId: 'seeker_2', // different seeker for the new rating
        jobId: 'job_2',
        overallRating: 5,
        communication: 5.0,
        punctuality: 5.0,
        quality: 5.0,
      );

      // Fetch helper profile again
      final updatedHelper = await userService.getUserProfile('helper_1');
      expect(updatedHelper!['rating'], 5.0);
      expect(updatedHelper['reviewCount'], 2); // 1 pre-existing, 1 added
      expect(db.getCallsCount, 2); // getCallsCount incremented, proving the rating submit successfully invalidated the cache!
    });
  });
}
