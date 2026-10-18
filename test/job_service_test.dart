// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/notification_service.dart';

class MockDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final String _id;
  final bool _exists;

  MockDocumentSnapshot(this._id, this._data, [this._exists = true]);

  @override
  String get id => _id;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDocumentReference implements DocumentReference<Map<String, dynamic>> {
  int getCalls = 0;
  int updateCalls = 0;
  Map<String, dynamic> docData;
  final String docId;

  MockDocumentReference(this.docId, this.docData);

  @override
  String get id => docId;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getCalls++;
    return MockDocumentSnapshot(docId, docData);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updateCalls++;
    docData.addAll(data.cast<String, dynamic>());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final Map<String, MockDocumentReference> docs = {};

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final key = path ?? 'generated_id';
    if (!docs.containsKey(key)) {
      docs[key] = MockDocumentReference(key, {});
    }
    return docs[key]!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFirebaseFirestore implements FirebaseFirestore {
  final Map<String, MockCollectionReference> collections = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    if (!collections.containsKey(collectionPath)) {
      collections[collectionPath] = MockCollectionReference();
    }
    return collections[collectionPath]!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late JobService jobService;
  late MockDocumentReference mockJobDoc;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    jobService = JobService(
      firestore: mockFirestore,
      notificationService: NotificationService(firestore: mockFirestore),
    );

    final jobsCollection = mockFirestore.collection('jobs') as MockCollectionReference;
    mockJobDoc = MockDocumentReference('job123', {
      'title': 'Tutoring Math',
      'status': 'open',
      'price': 25.0,
      'posterId': 'user_1',
    });
    jobsCollection.docs['job123'] = mockJobDoc;
  });

  test('getJobById fetches from Firestore on first call and uses cache on subsequent calls', () async {
    expect(mockJobDoc.getCalls, 0);

    final job1 = await jobService.getJobById('job123');
    expect(job1, isNotNull);
    expect(job1!['title'], 'Tutoring Math');
    expect(mockJobDoc.getCalls, 1);

    // Second call should return cached data without extra get()
    final job2 = await jobService.getJobById('job123');
    expect(job2, isNotNull);
    expect(job2!['title'], 'Tutoring Math');
    expect(mockJobDoc.getCalls, 1);
  });

  test('cached job data is isolated from caller mutation (deep copy)', () async {
    final job1 = await jobService.getJobById('job123');
    job1!['title'] = 'Mutated Title';

    final job2 = await jobService.getJobById('job123');
    expect(job2!['title'], 'Tutoring Math');
  });

  test('updateJobStatus invalidates job cache', () async {
    await jobService.getJobById('job123');
    expect(mockJobDoc.getCalls, 1);

    await jobService.updateJobStatus('job123', 'in_progress');
    expect(mockJobDoc.updateCalls, 1);

    // Next getJobById must re-fetch from Firestore
    await jobService.getJobById('job123');
    expect(mockJobDoc.getCalls, 2);
  });

  test('clearJobCache clears all cached jobs', () async {
    await jobService.getJobById('job123');
    expect(mockJobDoc.getCalls, 1);

    jobService.clearJobCache();

    await jobService.getJobById('job123');
    expect(mockJobDoc.getCalls, 2);
  });
}
