import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/theme/app_theme.dart';
import 'package:mpm_connect/features/customers/models/customer_model.dart';
import 'package:mpm_connect/shared/widgets/searchable_customer_picker.dart';

void main() {
  final List<Customer> testCustomers = [
    Customer(
      id: 'cust-1',
      name: 'Ahmed Supermarket',
      customerCode: 'CUST-001',
      phone: '9876543210',
      address: 'Main Bazaar',
      balance: 15000,
      totalInvoiced: 80000,
      totalPaid: 65000,
      oldestUnpaidDate: DateTime.now().subtract(const Duration(days: 45)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Customer(
      id: 'cust-2',
      name: 'Kerala Provisions',
      customerCode: 'CUST-002',
      phone: '9123456780',
      address: 'Town Road',
      balance: 0,
      totalInvoiced: 40000,
      totalPaid: 40000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  testWidgets('SearchableCustomerPicker displays customers and filters by search text', (WidgetTester tester) async {
    Customer? selectedCustomer;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SearchableCustomerPicker(
            customers: testCustomers,
            onCustomerSelected: (c) => selectedCustomer = c,
          ),
        ),
      ),
    );

    // Both customers initially visible
    expect(find.text('Ahmed Supermarket'), findsOneWidget);
    expect(find.text('Kerala Provisions'), findsOneWidget);

    // Search for "Kerala"
    await tester.enterText(find.byType(TextField), 'Kerala');
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Supermarket'), findsNothing);
    expect(find.text('Kerala Provisions'), findsOneWidget);

    // Tap on the filtered customer
    await tester.tap(find.text('Kerala Provisions'));
    await tester.pumpAndSettle();

    expect(selectedCustomer?.id, equals('cust-2'));
  });
}
