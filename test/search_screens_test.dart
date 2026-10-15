import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/features/search/screens/seeker_finding_helpers_screen.dart';
import 'package:freelancer/features/search/screens/helper_scanning_gigs_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MediaQuery(
      data: const MediaQueryData(size: Size(800, 1200)),
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return child;
          },
        ),
      ),
    );
  }

  group('Search Screens Tests', () {
    testWidgets('SeekerFindingHelpersScreen renders properly and handles animation', (WidgetTester tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exception.toString().contains('NetworkImage') ||
            details.exception.toString().contains('HTTP request failed')) {
          return;
        }
        oldOnError?.call(details);
      };

      await tester.pumpWidget(buildTestableWidget(const SeekerFindingHelpersScreen()));
      await tester.pump();

      expect(find.text("Search in progress"), findsOneWidget);
      expect(find.text("Finding local helpers near you..."), findsOneWidget);
      expect(find.text("Searching..."), findsOneWidget);
      expect(find.text("45%"), findsOneWidget);
      expect(find.text("WHILE YOU WAIT"), findsOneWidget);
      expect(find.text("Coffee Run"), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SeekerFindingHelpersScreen), findsOneWidget);

      FlutterError.onError = oldOnError;
    });

    testWidgets('HelperScanningGigsScreen renders properly and handles animation', (WidgetTester tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exception.toString().contains('NetworkImage') ||
            details.exception.toString().contains('HTTP request failed')) {
          return;
        }
        oldOnError?.call(details);
      };

      await tester.pumpWidget(buildTestableWidget(const HelperScanningGigsScreen()));
      await tester.pump();

      expect(find.text("Scanning nearby campus gigs..."), findsOneWidget);
      expect(find.text("Searching area"), findsOneWidget);
      expect(find.text("45%"), findsOneWidget);
      expect(find.text("S"), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(HelperScanningGigsScreen), findsOneWidget);

      FlutterError.onError = oldOnError;
    });
  });
}
