import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter - Indian Rupee (₹) Formatting', () {
    test('Formats standard amount with Indian numbering system', () {
      final formatted = CurrencyFormatter.format(100000.0);
      expect(formatted, contains('₹'));
      expect(formatted, contains('1,00,000'));
    });

    test('Formats lakh and crore values correctly', () {
      final formatted = CurrencyFormatter.format(124500.0);
      expect(formatted, contains('1,24,500'));
    });

    test('Parses formatted string back to numerical double', () {
      final parsed = CurrencyFormatter.parse('₹1,24,500.00');
      expect(parsed, equals(124500.0));
    });

    test('Formats ledger line item with + or - symbol', () {
      final credit = CurrencyFormatter.formatLedger(5000.0, isCredit: true);
      expect(credit, startsWith('+ '));
      expect(credit, contains('5,000'));

      final debit = CurrencyFormatter.formatLedger(20000.0, isCredit: false);
      expect(debit, startsWith('- '));
      expect(debit, contains('20,000'));
    });

    test('Formats negative amount correctly', () {
      final formatted = CurrencyFormatter.format(-500.0);
      expect(formatted, equals('-₹500.00'));
    });
  });
}
