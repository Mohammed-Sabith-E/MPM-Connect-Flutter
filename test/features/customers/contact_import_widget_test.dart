import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/services/permission_service.dart';
import 'package:mpm_connect/features/customers/widgets/add_customer_options_sheet.dart';
import 'package:mpm_connect/features/customers/widgets/contacts_permission_dialog.dart';
import 'package:mpm_connect/features/customers/widgets/select_phone_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionService Bulk Import Access Tests', () {
    test('Admin, Manager, and Salesman can bulk import; Cashier cannot', () {
      expect(PermissionService.canBulkImportCustomers(UserRole.admin), isTrue);
      expect(PermissionService.canBulkImportCustomers(UserRole.manager), isTrue);
      expect(PermissionService.canBulkImportCustomers(UserRole.salesman), isTrue);
      expect(PermissionService.canBulkImportCustomers(UserRole.cashier), isFalse);
    });
  });

  group('AddCustomerOptionsSheet Widget Tests', () {
    testWidgets('Renders Add Manually, From Phone Contacts, and Import Multiple Contacts',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddCustomerOptionsSheet(),
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('Add Customer'), findsOneWidget);
      expect(find.text('Choose how you want to add customer records'), findsOneWidget);

      // Verify Option 1: Add Manually
      expect(find.text('Add Manually'), findsOneWidget);

      // Verify Option 2: From Phone Contacts
      expect(find.text('From Phone Contacts'), findsOneWidget);

      // Verify Option 3: Import Multiple Contacts
      expect(find.text('Import Multiple Contacts'), findsOneWidget);

      // Verify CSV / Excel is removed
      expect(find.text('Import CSV / Excel'), findsNothing);
    });
  });

  group('SelectPhoneDialog Widget Tests', () {
    testWidgets('Displays phone numbers and allows user selection', (tester) async {
      String? chosenNumber;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  chosenNumber = await SelectPhoneDialog.show(
                    context,
                    contactName: 'Abdul Rahman',
                    phoneNumbers: ['9876512345', '9847045678'],
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Select Phone Number'), findsOneWidget);
      expect(find.textContaining('Abdul Rahman'), findsOneWidget);

      // Verify formatted numbers
      expect(find.text('+91 98765 12345'), findsOneWidget);
      expect(find.text('+91 98470 45678'), findsOneWidget);

      // Select second number
      await tester.tap(find.text('+91 98470 45678'));
      await tester.pumpAndSettle();

      // Tap Select button
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      expect(chosenNumber, '9847045678');
    });
  });

  group('ContactsPermissionDialog Widget Tests', () {
    testWidgets('Renders explanation and action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContactsPermissionDialog(),
          ),
        ),
      );

      expect(find.text('Contacts Permission Required'), findsOneWidget);
      expect(find.textContaining('MPM Connect needs access to your contacts'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });
  });
}
