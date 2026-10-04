import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/utils/ledger_calculator.dart';

void main() {
  group('LedgerCalculator - Overdue Calculations & Status', () {
    final now = DateTime(2026, 9, 14, 12, 0);

    test('Marks customer as overdue if unpaid transaction is older than 7 days', () {
      final invoiceDate = DateTime(2026, 9, 1); // 13 days ago
      final isOverdue = LedgerCalculator.isOverdue(
        customerBalance: 15000.0,
        oldestUnpaidDate: invoiceDate,
        currentDate: now,
      );

      expect(isOverdue, isTrue);
    });

    test('Customer is NOT overdue if transaction is within 7 days', () {
      final invoiceDate = DateTime(2026, 9, 10); // 4 days ago
      final isOverdue = LedgerCalculator.isOverdue(
        customerBalance: 15000.0,
        oldestUnpaidDate: invoiceDate,
        currentDate: now,
      );

      expect(isOverdue, isFalse);
    });

    test('Customer is NOT overdue if outstanding balance is 0', () {
      final invoiceDate = DateTime(2026, 8, 1); // 44 days ago, but settled
      final isOverdue = LedgerCalculator.isOverdue(
        customerBalance: 0.0,
        oldestUnpaidDate: invoiceDate,
        currentDate: now,
      );

      expect(isOverdue, isFalse);
    });

    test('Determines status correctly for paid, partial, credit, overdue', () {
      // Full Payment
      expect(
        LedgerCalculator.determinePaymentStatus(
          invoiceAmount: 10000.0,
          paymentReceived: 10000.0,
          invoiceDate: DateTime(2026, 9, 1),
          currentDate: now,
        ),
        equals('paid'),
      );

      // Overdue (> 7 days without full payment)
      expect(
        LedgerCalculator.determinePaymentStatus(
          invoiceAmount: 10000.0,
          paymentReceived: 2000.0,
          invoiceDate: DateTime(2026, 9, 1), // 13 days ago
          currentDate: now,
        ),
        equals('overdue'),
      );

      // Partial (Within 7 days)
      expect(
        LedgerCalculator.determinePaymentStatus(
          invoiceAmount: 10000.0,
          paymentReceived: 2000.0,
          invoiceDate: DateTime(2026, 9, 12), // 2 days ago
          currentDate: now,
        ),
        equals('partial'),
      );

      // Pure Credit (Within 7 days)
      expect(
        LedgerCalculator.determinePaymentStatus(
          invoiceAmount: 10000.0,
          paymentReceived: 0.0,
          invoiceDate: DateTime(2026, 9, 12),
          currentDate: now,
        ),
        equals('credit'),
      );
    });
  });
}
