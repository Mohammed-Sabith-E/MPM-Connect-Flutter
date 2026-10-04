import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/theme/app_theme.dart';
import 'package:mpm_connect/shared/widgets/status_chip.dart';
import 'package:mpm_connect/shared/widgets/metric_summary_card.dart';

void main() {
  testWidgets('Renders Sovereign Ledger themed MetricSummaryCard', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: MetricSummaryCard(
            label: "Today's Sales",
            amount: 25000.0,
            icon: Icons.point_of_sale_rounded,
          ),
        ),
      ),
    );

    expect(find.text("TODAY'S SALES"), findsOneWidget);
    expect(find.text("₹25,000"), findsOneWidget);
  });

  testWidgets('Renders StatusChip with correct styles', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StatusChip.fromPaymentStatus('paid'),
        ),
      ),
    );

    expect(find.text('PAID'), findsOneWidget);
  });
}
