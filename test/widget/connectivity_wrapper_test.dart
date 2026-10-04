import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpm_connect/core/providers/connectivity_provider.dart';
import 'package:mpm_connect/shared/widgets/connectivity_wrapper.dart';
import 'package:mpm_connect/shared/screens/no_internet_screen.dart';

void main() {
  group('ConnectivityWrapper Tests', () {
    testWidgets('renders child normally when online', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ConnectivityWrapper(
              child: Scaffold(
                body: Text('Main Screen Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Main Screen Content'), findsOneWidget);
      expect(find.byType(NoInternetScreen), findsNothing);
    });

    testWidgets('renders NoInternetScreen when offline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: ConnectivityWrapper(
              child: Scaffold(
                body: Text('Main Screen Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NoInternetScreen), findsOneWidget);
      expect(find.text('Oops!'), findsOneWidget);
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Main Screen Content'), findsNothing);
    });
  });
}
