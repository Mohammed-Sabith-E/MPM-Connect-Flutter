import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/features/transactions/models/transaction_model.dart';

void main() {
  group('Transaction Search Filtering Logic Tests', () {
    final t1 = InvoiceTransaction(
      id: 'tx1',
      invoiceNumber: 'INV-000104',
      customerId: 'c1',
      customerName: 'Abdul Rahman Stores',
      salesmanId: 's1',
      salesmanName: 'Suresh Kumar',
      createdBy: 'u1',
      invoiceDate: DateTime(2026, 9, 10),
      invoiceAmount: 15400.0,
      previousBalance: 0.0,
      paymentReceived: 5000.0,
      newBalance: 10400.0,
      paymentStatus: 'partial',
      notes: 'Delivered spices batch A',
      createdAt: DateTime(2026, 9, 10),
      updatedAt: DateTime(2026, 9, 10),
    );

    final t2 = InvoiceTransaction(
      id: 'tx2',
      invoiceNumber: 'INV-000215',
      customerId: 'c2',
      customerName: 'Mohammed Sabith Traders',
      salesmanId: 's2',
      salesmanName: 'Anand V',
      createdBy: 'u1',
      invoiceDate: DateTime(2026, 9, 12),
      invoiceAmount: 8500.0,
      previousBalance: 2000.0,
      paymentReceived: 10500.0,
      newBalance: 0.0,
      paymentStatus: 'paid',
      notes: 'Rice bags order',
      createdAt: DateTime(2026, 9, 12),
      updatedAt: DateTime(2026, 9, 12),
    );

    final transactions = [t1, t2];

    bool matchesQuery(InvoiceTransaction t, String query) {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return true;
      final digits = q.replaceAll(RegExp(r'[^0-9]'), '');
      final matchesInvoice = t.invoiceNumber.toLowerCase().contains(q) ||
          (digits.isNotEmpty && t.invoiceNumber.replaceAll(RegExp(r'[^0-9]'), '').contains(digits));
      final matchesCustomer = t.customerName.toLowerCase().contains(q);
      final matchesSalesman = t.salesmanName?.toLowerCase().contains(q) ?? false;
      final matchesNotes = t.notes.toLowerCase().contains(q);
      return matchesInvoice || matchesCustomer || matchesSalesman || matchesNotes;
    }

    test('Searches customer name case-insensitively and partially', () {
      final abdulResults = transactions.where((t) => matchesQuery(t, 'abdul')).toList();
      expect(abdulResults.length, 1);
      expect(abdulResults.first.customerName, 'Abdul Rahman Stores');

      final sabithResults = transactions.where((t) => matchesQuery(t, 'SABITH')).toList();
      expect(sabithResults.length, 1);
      expect(sabithResults.first.customerName, 'Mohammed Sabith Traders');

      final mohammedResults = transactions.where((t) => matchesQuery(t, 'mohammed')).toList();
      expect(mohammedResults.length, 1);
      expect(mohammedResults.first.customerName, 'Mohammed Sabith Traders');
    });

    test('Searches invoice number with and without INV prefix and partial digits', () {
      // Full invoice string
      final fullInv = transactions.where((t) => matchesQuery(t, 'INV-000104')).toList();
      expect(fullInv.length, 1);
      expect(fullInv.first.id, 'tx1');

      // Lowercase invoice string
      final lowerInv = transactions.where((t) => matchesQuery(t, 'inv-000215')).toList();
      expect(lowerInv.length, 1);
      expect(lowerInv.first.id, 'tx2');

      // Only digits without prefix (e.g., '104' or '000104')
      final digitsInv = transactions.where((t) => matchesQuery(t, '104')).toList();
      expect(digitsInv.length, 1);
      expect(digitsInv.first.id, 'tx1');

      final digitsInv2 = transactions.where((t) => matchesQuery(t, '215')).toList();
      expect(digitsInv2.length, 1);
      expect(digitsInv2.first.id, 'tx2');
    });

    test('Searches salesman name and notes', () {
      final salesmanResults = transactions.where((t) => matchesQuery(t, 'suresh')).toList();
      expect(salesmanResults.length, 1);
      expect(salesmanResults.first.id, 'tx1');

      final notesResults = transactions.where((t) => matchesQuery(t, 'spices')).toList();
      expect(notesResults.length, 1);
      expect(notesResults.first.id, 'tx1');
    });

    test('Returns nothing for non-matching query', () {
      final noResults = transactions.where((t) => matchesQuery(t, 'nonexistent query 9999')).toList();
      expect(noResults, isEmpty);
    });
  });
}
