import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/providers/app_providers.dart';
import 'package:mpm_connect/core/services/permission_service.dart';
import 'package:mpm_connect/features/auth/models/user_model.dart';
import 'package:mpm_connect/features/customers/models/customer_model.dart';
import 'package:mpm_connect/features/customers/repositories/customer_repository.dart';
import 'package:mpm_connect/features/customers/screens/import_preview_screen.dart';
import 'package:mpm_connect/features/customers/services/customer_import_service.dart';

class FakePreviewCustomerRepository extends Fake implements CustomerRepository {
  final List<Customer> activeCustomers;

  FakePreviewCustomerRepository({this.activeCustomers = const []});

  @override
  Future<List<Customer>> getAllActiveCustomersLightweight() async {
    return activeCustomers;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ImportPreviewScreen renders metric cards and categorizes candidates',
      (tester) async {
    final existingCustomer = Customer(
      id: 'cust-1',
      customerCode: 'CUST-0001',
      name: 'Existing Anwar',
      phone: '9847045678',
      normalizedPhone: '919847045678',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final fakeRepo = FakePreviewCustomerRepository(activeCustomers: [existingCustomer]);

    final rawItems = [
      const RawImportItem(name: 'Abdul Rahman', phone: '+91 98765 12345'),
      const RawImportItem(name: 'Anwar', phone: '09847045678'), // Duplicate of CUST-0001
      const RawImportItem(name: 'Invalid No Phone', phone: ''), // Invalid
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerRepositoryProvider.overrideWithValue(fakeRepo),
          customerImportServiceProvider.overrideWithValue(
            CustomerImportService(customerRepository: fakeRepo),
          ),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(AppUser(
                uid: 'user-1',
                name: 'Mohammed Sabith',
                email: 'sabith@example.com',
                phone: '9876543210',
                role: UserRole.admin,
                createdAt: DateTime(2026, 1, 1),
              ))),
        ],
        child: MaterialApp(
          home: ImportPreviewScreen(rawItems: rawItems),
        ),
      ),
    );

    // Pump to complete async analysis
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Import Customers'), findsOneWidget);

    // Verify Metric Counts: Selected 3, New 1, Existing 1, Invalid 1
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('New'), findsWidgets);
    expect(find.text('Existing'), findsWidgets);
    expect(find.text('Invalid'), findsWidgets);

    // Verify Tab Chips
    expect(find.text('New (1)'), findsOneWidget);
    expect(find.text('Existing (1)'), findsOneWidget);
    expect(find.text('Invalid (1)'), findsOneWidget);

    // Verify action button text
    expect(find.text('Import 1 Customer'), findsOneWidget);
  });
}
