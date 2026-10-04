import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/utils/ledger_calculator.dart';

void main() {
  group('LedgerCalculator - Balance Calculations', () {
    test('Calculates new balance accurately when invoice has down payment', () {
      // Example from specification:
      // Previous Balance = ₹15,000
      // New Invoice = ₹20,000
      // Payment = ₹5,000
      // New Balance = ₹30,000
      final newBalance = LedgerCalculator.calculateNewBalance(
        previousBalance: 15000.0,
        invoiceAmount: 20000.0,
        paymentReceived: 5000.0,
      );

      expect(newBalance, equals(30000.0));
    });

    test('Calculates new balance when customer had zero previous balance', () {
      final newBalance = LedgerCalculator.calculateNewBalance(
        previousBalance: 0.0,
        invoiceAmount: 10000.0,
        paymentReceived: 2000.0,
      );

      expect(newBalance, equals(8000.0));
    });

    test('Calculates new balance when invoice is fully paid on the spot', () {
      final newBalance = LedgerCalculator.calculateNewBalance(
        previousBalance: 0.0,
        invoiceAmount: 10000.0,
        paymentReceived: 10000.0,
      );

      expect(newBalance, equals(0.0));
    });

    test('Calculates new balance for pure credit sale (₹0 down payment)', () {
      final newBalance = LedgerCalculator.calculateNewBalance(
        previousBalance: 5000.0,
        invoiceAmount: 12000.0,
        paymentReceived: 0.0,
      );

      expect(newBalance, equals(17000.0));
    });

    test('Maintains decimal precision without floating-point drift', () {
      final newBalance = LedgerCalculator.calculateNewBalance(
        previousBalance: 100.10,
        invoiceAmount: 200.25,
        paymentReceived: 50.35,
      );

      expect(newBalance, equals(250.00));
    });

    test('Offsets correctly when customer has previous negative (advance/credit) balance', () {
      // E.g. Previous balance = -₹500, New Invoice = ₹2000, Payment = ₹0 -> New balance = ₹1500
      final newBalance = LedgerCalculator.calculateNewBalance(
        previousBalance: -500.0,
        invoiceAmount: 2000.0,
        paymentReceived: 0.0,
      );

      expect(newBalance, equals(1500.0));
    });
  });
}
