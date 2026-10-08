// ignore_for_file: subtype_of_sealed_class, must_be_immutable, annotate_overrides
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/home/screens/home_tab.dart';

class FakeQuerySnapshot implements QuerySnapshot {
  final List<QueryDocumentSnapshot> _docs;

  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot> get docs => _docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQueryDocumentSnapshot implements QueryDocumentSnapshot {
  final Map<String, dynamic> _data;

  FakeQueryDocumentSnapshot(this._data);

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('HomeTab renders category options and nearby helpers stream data', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    final controller = StreamController<QuerySnapshot>.broadcast();
    final fakeSnapshot = FakeQuerySnapshot([
      FakeQueryDocumentSnapshot({
        'name': 'Alex Helper',
        'tagline': 'Math & CS Tutor',
        'rating': 4.9,
        'reviews': 12,
      }),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return HomeTab(helpersStream: controller.stream);
          },
        ),
      ),
    );

    expect(find.text('UC Berkeley Campus'), findsOneWidget);
    expect(find.text('What do you need'), findsOneWidget);
    expect(find.text('Cleaning'), findsOneWidget);
    expect(find.text('Tech Support'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('Tutor'), findsOneWidget);

    controller.add(fakeSnapshot);
    await tester.pump();

    expect(find.text('Alex Helper'), findsOneWidget);
    expect(find.text('Math & CS Tutor'), findsOneWidget);

    await controller.close();
  });

  testWidgets('HomeTab retains cached stream instance across rebuilds', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    int listenCount = 0;
    final controller = StreamController<QuerySnapshot>.broadcast(
      onListen: () {
        listenCount++;
      },
    );

    final widget = MaterialApp(
      home: Builder(
        builder: (context) {
          Responsive.init(context);
          return HomeTab(helpersStream: controller.stream);
        },
      ),
    );

    await tester.pumpWidget(widget);
    expect(listenCount, equals(1));

    // Rebuild widget tree
    await tester.pumpWidget(widget);
    await tester.pump();

    // Verify stream subscription was not re-created/re-listened
    expect(listenCount, equals(1));

    await controller.close();
  });
}
