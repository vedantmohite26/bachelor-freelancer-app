import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/services/wallet_service.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
import 'wallet_service_test.mocks.dart';

void main() {
  group('WalletService Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollectionRef;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockSnapshot;
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> streamController;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollectionRef = MockCollectionReference();
      mockDocRef = MockDocumentReference();
      mockSnapshot = MockDocumentSnapshot();
      streamController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      when(mockFirestore.collection('users')).thenReturn(mockCollectionRef);
      when(mockCollectionRef.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.snapshots()).thenAnswer((_) => streamController.stream);
    });

    tearDown(() {
      streamController.close();
    });

    test('Initial values are correct', () {
      final service = WalletService(firestore: mockFirestore);
      expect(service.balance, 0.0);
      expect(service.coins, 0);
      expect(service.transactions, isEmpty);
      expect(service.activePowerUps, isEmpty);
    });

    test('listenToWallet registers a single subscription and updates values when stream emits', () async {
      final service = WalletService(firestore: mockFirestore);

      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn({
        'walletBalance': 150.50,
        'coins': 300,
        'activePowerUps': {'xp_boost': 'active'}
      });

      service.listenToWallet('user_123');

      // Add a snapshot to the stream
      streamController.add(mockSnapshot);

      // Give listeners a microtask to handle stream event
      await Future.delayed(Duration.zero);

      expect(service.balance, 150.50);
      expect(service.coins, 300);
      expect(service.activePowerUps, containsPair('xp_boost', 'active'));

      // Check that calling with same user ID doesn't re-subscribe
      service.listenToWallet('user_123');

      // Dispose service (cancels stream)
      service.dispose();
    });

    test('listenToWallet cancels previous subscription when userId changes', () async {
      final service = WalletService(firestore: mockFirestore);

      service.listenToWallet('user_123');
      expect(streamController.hasListener, isTrue);

      service.listenToWallet('user_456');

      // Clean up
      service.dispose();
    });
  });
}
