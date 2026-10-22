import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/rating_service.dart';

class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  int queryCount = 0;
  final List<Map<String, dynamic>> ratings = [
    {'overallRating': 5, 'helperId': 'helper_1', 'seekerId': 'seeker_1', 'jobId': 'job_1'},
    {'overallRating': 5, 'helperId': 'helper_1', 'seekerId': 'seeker_2', 'jobId': 'job_2'},
    {'overallRating': 4, 'helperId': 'helper_1', 'seekerId': 'seeker_3', 'jobId': 'job_3'},
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      final namedArgs = invocation.namedArguments;
      final isEqualTo = namedArgs[#isEqualTo];
      return FakeQuery(this, isEqualTo);
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final FakeCollectionReference parentCollection;
  final Object? helperIdValue;

  FakeQuery(this.parentCollection, this.helperIdValue);

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    parentCollection.queryCount++;
    final filtered = parentCollection.ratings
        .where((r) => r['helperId'] == helperIdValue)
        .toList();
    return FakeQuerySnapshot(filtered);
  }
}

class FakeQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  final List<Map<String, dynamic>> _docs;

  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs =>
      _docs.map((d) => FakeQueryDocumentSnapshot(d)).toList();
}

class FakeQueryDocumentSnapshot extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;

  FakeQueryDocumentSnapshot(this._data);

  @override
  Map<String, dynamic> data() => _data;
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final FakeCollectionReference collectionRef = FakeCollectionReference();

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return collectionRef;
  }
}

void main() {
  group('RatingService Unit Tests', () {
    late RatingService ratingService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      ratingService = RatingService(firestore: fakeFirestore);
    });

    test('getRatingDistribution uses in-memory cache on repeated calls', () async {
      expect(fakeFirestore.collectionRef.queryCount, 0);

      final dist1 = await ratingService.getRatingDistribution('helper_1');
      expect(dist1[5], 2);
      expect(dist1[4], 1);
      expect(fakeFirestore.collectionRef.queryCount, 1);

      // Second call should return cached result without hitting Firestore again
      final dist2 = await ratingService.getRatingDistribution('helper_1');
      expect(dist2[5], 2);
      expect(dist2[4], 1);
      expect(fakeFirestore.collectionRef.queryCount, 1);
    });
  });
}
