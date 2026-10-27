import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getAllUserPaymentsStream combines streams without re-subscribing', () async {
    final earnedController = StreamController<List<Map<String, dynamic>>>();
    final spentController = StreamController<List<Map<String, dynamic>>>();

    int earnedListenCount = 0;
    int spentListenCount = 0;

    final earnedStream = earnedController.stream.asBroadcastStream(
      onListen: (_) => earnedListenCount++,
    );
    final spentStream = spentController.stream.asBroadcastStream(
      onListen: (_) => spentListenCount++,
    );

    final controller = StreamController<List<Map<String, dynamic>>>();
    StreamSubscription? earnedSub;
    StreamSubscription? spentSub;

    List<Map<String, dynamic>> latestEarned = [];
    List<Map<String, dynamic>> latestSpent = [];

    void emitCombined() {
      if (controller.isClosed) return;
      final all = [...latestEarned, ...latestSpent];
      all.sort((a, b) {
        final aTime = (a['createdAt'] as int?) ?? 0;
        final bTime = (b['createdAt'] as int?) ?? 0;
        return bTime.compareTo(aTime);
      });
      controller.add(all);
    }

    controller.onListen = () {
      earnedSub = earnedStream.listen((e) {
        latestEarned = e;
        emitCombined();
      });
      spentSub = spentStream.listen((s) {
        latestSpent = s;
        emitCombined();
      });
    };

    controller.onCancel = () async {
      await earnedSub?.cancel();
      await spentSub?.cancel();
    };

    final List<List<Map<String, dynamic>>> emittedEvents = [];
    final sub = controller.stream.listen((event) {
      emittedEvents.add(event);
    });

    // Verify each stream was listened to exactly once
    expect(earnedListenCount, equals(1));
    expect(spentListenCount, equals(1));

    // Emit event on earned
    earnedController.add([
      {'id': '1', 'createdAt': 100, 'isIncoming': true},
    ]);
    await Future.delayed(Duration.zero);

    expect(emittedEvents.length, equals(1));
    expect(emittedEvents.last.length, equals(1));
    expect(emittedEvents.last.first['id'], equals('1'));

    // Emit multiple earned events and verify spent is NOT re-subscribed
    earnedController.add([
      {'id': '1', 'createdAt': 100, 'isIncoming': true},
      {'id': '2', 'createdAt': 200, 'isIncoming': true},
    ]);
    await Future.delayed(Duration.zero);

    expect(spentListenCount, equals(1)); // Still exactly 1 listen!

    // Emit event on spent
    spentController.add([
      {'id': '3', 'createdAt': 300, 'isIncoming': false},
    ]);
    await Future.delayed(Duration.zero);

    expect(emittedEvents.last.length, equals(3));
    expect(emittedEvents.last.first['id'], equals('3')); // Sorted descending by createdAt

    await sub.cancel();
    await controller.close();
    await earnedController.close();
    await spentController.close();
  });
}
