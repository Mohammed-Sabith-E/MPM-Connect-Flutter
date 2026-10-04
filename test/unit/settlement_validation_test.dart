import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/utils/ledger_calculator.dart';

void main() {
  group('LedgerCalculator - Settlement & Payment Validation', () {
    test('Calculates remaining balance after partial settlement', () {
      final remaining = LedgerCalculator.calculateRemainingBalance(
        currentBalance: 30000.0,
        paymentAmount: 10000.0,
      );

      expect(remaining, equals(20000.0));
    });

    test('Calculates remaining balance as exactly 0.0 on full settlement', () {
      final remaining = LedgerCalculator.calculateRemainingBalance(
        currentBalance: 30000.0,
        paymentAmount: 30000.0,
      );

      expect(remaining, equals(0.0));
    });

    test('Validates payment amount > 0', () {
      final errorZero = LedgerCalculator.validatePaymentAmount(
        paymentAmount: 0.0,
        currentBalance: 5000.0,
      );
      expect(errorZero, isNotNull);
      expect(errorZero, contains('greater than ₹0'));

      final errorNegative = LedgerCalculator.validatePaymentAmount(
        paymentAmount: -500.0,
        currentBalance: 5000.0,
      );
      expect(errorNegative, isNotNull);
    });

    test('Accepts payment amount exceeding current outstanding balance (advance/credit)', () {
      final errorExcess = LedgerCalculator.validatePaymentAmount(
        paymentAmount: 5500.0,
        currentBalance: 5000.0,
      );
      expect(errorExcess, isNull);

      final remaining = LedgerCalculator.calculateRemainingBalance(
        currentBalance: 5000.0,
        paymentAmount: 5500.0,
      );
      expect(remaining, equals(-500.0));
    });

    test('Accepts valid partial payment', () {
      final error = LedgerCalculator.validatePaymentAmount(
        paymentAmount: 2500.0,
        currentBalance: 5000.0,
      );
      expect(error, isNull);
    });

    test('Accepts valid exact full settlement', () {
      final error = LedgerCalculator.validatePaymentAmount(
        paymentAmount: 5000.0,
        currentBalance: 5000.0,
      );
      expect(error, isNull);
    });
  });
}
