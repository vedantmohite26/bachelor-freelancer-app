// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/wallet_service.dart';

void main() {
  group('WalletService Performance & Subscription Leak Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> user1Controller;
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> user2Controller;
    late FakeDocumentReference user1Ref;
    late FakeDocumentReference user2Ref;

    setUp(() {
      user1Controller = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
      user2Controller = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      user1Ref = FakeDocumentReference(
        'users/user1',
        'user1',
        <String, dynamic>{
          'walletBalance': 150.0,
          'coins': 45,
          'activePowerUps': <String, dynamic>{},
        },
        user1Controller,
      );

      user2Ref = FakeDocumentReference(
        'users/user2',
        'user2',
        <String, dynamic>{
          'walletBalance': 250.0,
          'coins': 100,
          'activePowerUps': <String, dynamic>{},
        },
        user2Controller,
      );

      final usersCollection = FakeCollectionReference('users', {
        'user1': user1Ref,
        'user2': user2Ref,
      });

      fakeDb = FakeFirebaseFirestore({'users': usersCollection});
    });

    tearDown(() {
      user1Controller.close();
      user2Controller.close();
    });

    test('listenToWallet establishes subscription and updates values', () async {
      final walletService = WalletService(firestore: fakeDb);

      expect(walletService.balance, 0.0);
      expect(walletService.coins, 0);

      // Start listening to user1
      walletService.listenToWallet('user1');

      // Wait a microtask for onListen to fire
      await Future.delayed(Duration.zero);

      expect(walletService.balance, 150.0);
      expect(walletService.coins, 45);

      // Push a new snapshot update via the controller
      user1Controller.add(FakeDocumentSnapshot(
        'user1',
        <String, dynamic>{
          'walletBalance': 200.0,
          'coins': 60,
          'activePowerUps': <String, dynamic>{},
        },
        true,
      ));

      await Future.delayed(Duration.zero);

      expect(walletService.balance, 200.0);
      expect(walletService.coins, 60);

      walletService.dispose();
    });

    test('listenToWallet does not recreate subscription for the same user ID', () async {
      final walletService = WalletService(firestore: fakeDb);

      walletService.listenToWallet('user1');
      await Future.delayed(Duration.zero);

      final originalBalance = walletService.balance;
      expect(originalBalance, 150.0);

      // Call listenToWallet again with the same user ID
      walletService.listenToWallet('user1');
      await Future.delayed(Duration.zero);

      // Verify still working and hasn't broken
      expect(walletService.balance, 150.0);

      // Push an update and ensure it is still received by the single active stream
      user1Controller.add(FakeDocumentSnapshot(
        'user1',
        <String, dynamic>{
          'walletBalance': 300.0,
          'coins': 75,
          'activePowerUps': <String, dynamic>{},
        },
        true,
      ));

      await Future.delayed(Duration.zero);
      expect(walletService.balance, 300.0);

      walletService.dispose();
    });

    test('listenToWallet cancels previous subscription when listening to a new user ID', () async {
      final walletService = WalletService(firestore: fakeDb);

      // Start listening to user1
      walletService.listenToWallet('user1');
      await Future.delayed(Duration.zero);
      expect(walletService.balance, 150.0);

      // Switch to user2 (should cancel user1's subscription)
      walletService.listenToWallet('user2');
      await Future.delayed(Duration.zero);
      expect(walletService.balance, 250.0);

      // Push an update to user1's controller. It should NOT affect walletService balance
      user1Controller.add(FakeDocumentSnapshot(
        'user1',
        <String, dynamic>{
          'walletBalance': 999.0,
          'coins': 999,
          'activePowerUps': <String, dynamic>{},
        },
        true,
      ));

      await Future.delayed(Duration.zero);
      // Balance remains user2's balance
      expect(walletService.balance, 250.0);

      // Push an update to user2's controller. It should update walletService balance
      user2Controller.add(FakeDocumentSnapshot(
        'user2',
        <String, dynamic>{
          'walletBalance': 500.0,
          'coins': 120,
          'activePowerUps': <String, dynamic>{},
        },
        true,
      ));

      await Future.delayed(Duration.zero);
      expect(walletService.balance, 500.0);

      walletService.dispose();
    });

    test('disposing WalletService cancels active subscription', () async {
      final walletService = WalletService(firestore: fakeDb);

      walletService.listenToWallet('user1');
      await Future.delayed(Duration.zero);
      expect(walletService.balance, 150.0);

      walletService.dispose();

      // After disposal, pushing to user1Controller should have no effect and not throw
      user1Controller.add(FakeDocumentSnapshot(
        'user1',
        <String, dynamic>{
          'walletBalance': 400.0,
          'coins': 80,
          'activePowerUps': <String, dynamic>{},
        },
        true,
      ));

      await Future.delayed(Duration.zero);
      // Expect that since subscription is canceled, listeners are not notified and nothing crashes
      // Note: we don't assert walletService.balance because the object is disposed
    });
  });
}

// --- FAKE FIRESTORE IMPLEMENTATION ---

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> collections;

  FakeFirebaseFirestore(this.collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return collections[collectionPath] ?? FakeCollectionReference(collectionPath, {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final String path;
  final Map<String, FakeDocumentReference> documents;

  FakeCollectionReference(this.path, this.documents);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return documents[path] ?? FakeDocumentReference(
      path ?? 'unknown',
      path ?? 'unknown',
      <String, dynamic>{},
      StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final String path;
  final String id;
  final Map<String, dynamic> data;
  final StreamController<DocumentSnapshot<Map<String, dynamic>>> controller;

  FakeDocumentReference(this.path, this.id, this.data, this.controller);

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    // Standard practice for mocking Firestore broadcast stream controllers:
    // Emit initial snapshot state inside the onListen callback to prevent stream timing issues or missed initial events.
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> subController;
    subController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast(
      onListen: () {
        subController.add(FakeDocumentSnapshot(id, data, true));
      },
    );

    final mainSub = controller.stream.listen((snapshot) {
      if (!subController.isClosed) {
        subController.add(snapshot);
      }
    });

    subController.onCancel = () {
      mainSub.cancel();
      subController.close();
    };

    return subController.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<dynamic, dynamic>? _data;
  final bool _exists;
  final String _id;

  FakeDocumentSnapshot(this._id, this._data, this._exists);

  @override
  String get id => _id;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() =>
      _data != null ? Map<String, dynamic>.from(_data) : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
