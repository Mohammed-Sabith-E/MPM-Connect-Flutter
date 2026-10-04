import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/services/pdf_generator_service.dart';
import 'package:mpm_connect/features/customers/models/customer_model.dart';
import 'package:mpm_connect/features/dashboard/models/dashboard_metrics_model.dart';
import 'package:mpm_connect/features/payments/models/payment_model.dart';
import 'package:mpm_connect/features/transactions/models/transaction_model.dart';
import 'package:mpm_connect/shared/widgets/account_notices_sheet.dart';
import 'package:mpm_connect/shared/widgets/mpm_app_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF UI & Malayalam Glyph Support Tests', () {
    test('Customer Statement generates valid PDF with Malayalam name and running balance', () async {
      final customer = Customer(
        id: 'cust-1',
        customerCode: 'CUST-0003',
        name: 'ഷിബിൻ', // Shibin in Malayalam
        phone: '8304884588',
        balance: 5300.0,
        totalInvoiced: 5300.0,
        totalPaid: 0.0,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 16),
      );

      final transactions = <InvoiceTransaction>[
        InvoiceTransaction(
          id: 'tx-1',
          invoiceNumber: 'INV-000005',
          customerId: 'cust-1',
          customerName: 'ഷിബിൻ',
          invoiceDate: DateTime(2026, 9, 16),
          invoiceAmount: 300.0,
          paymentReceived: 0.0,
          previousBalance: 0.0,
          newBalance: 300.0,
          paymentStatus: 'UNPAID',
          salesmanId: 's-1',
          salesmanName: 'Sujith',
          createdBy: 'admin-1',
          createdAt: DateTime(2026, 9, 16),
          updatedAt: DateTime(2026, 9, 16),
        ),
        InvoiceTransaction(
          id: 'tx-2',
          invoiceNumber: 'INV-000006',
          customerId: 'cust-1',
          customerName: 'ഷിബിൻ',
          invoiceDate: DateTime(2026, 9, 16),
          invoiceAmount: 5000.0,
          paymentReceived: 0.0,
          previousBalance: 300.0,
          newBalance: 5300.0,
          paymentStatus: 'UNPAID',
          salesmanId: 's-1',
          salesmanName: 'Sujith',
          createdBy: 'admin-1',
          createdAt: DateTime(2026, 9, 16),
          updatedAt: DateTime(2026, 9, 16),
        ),
      ];

      final payments = <PaymentRecord>[];

      final pdfBytes = await PdfGeneratorService.generateCustomerStatement(
        customer: customer,
        transactions: transactions,
        payments: payments,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Customer Outstanding Report generates valid PDF with Malayalam names', () async {
      final customers = [
        Customer(
          id: 'cust-1',
          customerCode: 'CUST-0003',
          name: 'ഷിബിൻ',
          phone: '8304884588',
          balance: 5300.0,
          totalInvoiced: 5300.0,
          totalPaid: 0.0,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 16),
        ),
        Customer(
          id: 'cust-2',
          customerCode: 'CUST-0002',
          name: 'Sanad',
          phone: '9745942004',
          balance: 780.0,
          totalInvoiced: 7080.0,
          totalPaid: 6300.0,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 16),
        ),
      ];

      final pdfBytes = await PdfGeneratorService.generateOutstandingReport(
        customers: customers,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });

  group('MpmAppHeader & Notification Badge Tests', () {
    testWidgets('Header does not show notification button if onNotificationTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: MpmAppHeader(
              title: 'Test Header',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    });

    testWidgets('Header displays notification button and badge when count > 0', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: MpmAppHeader(
              title: 'Dashboard',
              notificationCount: 5,
              onNotificationTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      expect(tapped, isTrue);
    });
  });

  group('AccountNoticesSheet Tests', () {
    testWidgets('Displays empty state when no overdue notices', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccountNoticesSheet(overdueNotices: []),
          ),
        ),
      );

      expect(find.text('All Accounts In Good Standing'), findsOneWidget);
      expect(find.text('Account Notices'), findsOneWidget);
    });

    testWidgets('Displays list of overdue customer accounts with balance', (tester) async {
      final overdueList = [
        OverdueCustomerItem(
          customer: Customer(
            id: 'c-1',
            customerCode: 'CUST-0003',
            name: 'Shibin Traders',
            phone: '8304884588',
            balance: 5300.0,
            createdAt: DateTime(2026, 9, 1),
            updatedAt: DateTime(2026, 9, 16),
          ),
          daysOverdue: 14,
          oldestUnpaidDate: DateTime(2026, 9, 2),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountNoticesSheet(overdueNotices: overdueList),
          ),
        ),
      );

      expect(find.text('Shibin Traders'), findsOneWidget);
      expect(find.text('CUST-0003'), findsOneWidget);
      expect(find.textContaining('14 days overdue'), findsOneWidget);
      expect(find.text('₹5,300.00'), findsOneWidget);
    });
  });
}
