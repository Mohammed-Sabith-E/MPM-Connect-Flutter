import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpm_connect/core/utils/app_toast.dart';
import 'package:mpm_connect/features/settings/screens/settings_screen.dart';

void main() {
  group('AppToast Tests', () {
    testWidgets('AppToast displays message properly with messengerKey', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: AppToast.messengerKey,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppToast.success('Saved invoice successfully!');
                  },
                  child: const Text('Show Toast'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Saved invoice successfully!'), findsNothing);

      await tester.tap(find.text('Show Toast'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300)); // Animate in

      expect(find.text('Saved invoice successfully!'), findsOneWidget);
    });

    testWidgets('AppToast works with error and info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: AppToast.messengerKey,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => AppToast.error('Network failure'),
                      child: const Text('Error Toast'),
                    ),
                    ElevatedButton(
                      onPressed: () => AppToast.info('Info message'),
                      child: const Text('Info Toast'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Error Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Network failure'), findsOneWidget);

      await tester.tap(find.text('Info Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Info message'), findsOneWidget);
    });
  });

  group('SettingsScreen Developer Details Tests', () {
    testWidgets('SettingsScreen renders developer card with Zobotic info', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      // Verify developer details section
      await tester.scrollUntilVisible(find.text('DEVELOPED BY'), 200);
      expect(find.text('DEVELOPED BY'), findsOneWidget);
      expect(find.text('Zobotic Innovations'), findsOneWidget);
      expect(find.text('www.zobotic.in'), findsOneWidget);
      expect(find.text('zoboticinnovations@gmail.com'), findsOneWidget);
    });
  });
}
