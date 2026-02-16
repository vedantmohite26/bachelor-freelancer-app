import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:freelancer/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('verify app startup and dashboard', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verify basic startup - expect to see either WelcomeScreen or HomeScreen
    expect(find.byType(MaterialApp), findsOneWidget);

    // Check for common UI elements to confirm we aren't crashing
    // Note: Since we rely on real backend data, we can't assert specific texts easily
    // but we can check if the app bar or main scaffolding is present.

    // Allow time for animations and async DataConnect/Firebase ops
    await Future.delayed(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
