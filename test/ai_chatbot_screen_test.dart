import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/chat/screens/ai_chatbot_screen.dart';

void main() {
  Widget buildTestableWidget() {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          Responsive.init(context);
          return const AIChatbotScreen();
        },
      ),
    );
  }

  testWidgets('AIChatbotScreen renders initial messages and header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    // Verify header text
    expect(find.text('AI Assistant'), findsOneWidget);
    expect(find.text('Always here to help'), findsOneWidget);

    // Verify initial bot message
    expect(
      find.text('Hello! I am your AI Assistant. How can I help you today?'),
      findsOneWidget,
    );

    // Verify text field
    expect(find.text('Ask me anything...'), findsOneWidget);
  });

  testWidgets('AIChatbotScreen sends user message and displays response', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    // Enter message
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    await tester.enterText(textField, 'Hello AI');

    // Tap send button
    final sendButton = find.byIcon(Icons.arrow_upward);
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);

    // Pump to process setState and scroll timer
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // Verify user message is displayed
    expect(find.text('Hello AI'), findsOneWidget);

    // Advance time for simulated AI response (1 second delay)
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 150));

    // Verify AI response message
    expect(
      find.text(
        "I'm a demo AI. I can't really process 'Hello AI' yet, but I'm here to help!",
      ),
      findsOneWidget,
    );
  });
}
