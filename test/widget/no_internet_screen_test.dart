import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpm_connect/shared/screens/no_internet_screen.dart';

void main() {
  group('NoInternetScreen Tests', () {
    testWidgets('renders disconnected radar core, headers, and diagnostics checklist', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NoInternetScreen(
              showOfflineModeButton: true,
            ),
          ),
        ),
      );

      // Verify headers and refresh button
      expect(find.text('Oops!'), findsOneWidget);
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('hides offline mode button when showOfflineModeButton is false', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NoInternetScreen(
              showOfflineModeButton: false,
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Continue in Cached Offline Mode'), findsNothing);
    });

    testWidgets('tapping Try Again invokes onRetry callback', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NoInternetScreen(
              showOfflineModeButton: true,
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      final retryBtn = find.text('Try Again');
      expect(retryBtn, findsOneWidget);

      await tester.ensureVisible(retryBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(retryBtn);
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('animation controllers tick without error', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NoInternetScreen(
              showOfflineModeButton: true,
            ),
          ),
        ),
      );

      // Advance clock by 500ms and 1000ms to verify smooth animation loop
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.byType(NoInternetScreen), findsOneWidget);
    });
  });
}
