import 'package:intl/intl.dart';

/// Indian Rupee Currency Formatter
/// Implements standard Indian lakh/crore grouping (e.g. ₹1,24,500.00)
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrCompactFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrNoSymbol = NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat _inrNoSymbolClean = NumberFormat('#,##,##0', 'en_IN');

  /// Formats amount with standard 2 decimal places: e.g. ₹1,24,500.00
  static String format(double amount) {
    return _inrFormat.format(amount);
  }

  /// Formats amount without decimals if clean integer, or rounded: e.g. ₹1,24,500
  static String formatClean(double amount) {
    if (amount % 1 == 0) {
      return _inrCompactFormat.format(amount);
    }
    return _inrFormat.format(amount);
  }

  /// Formats amount without ₹ symbol: e.g. 1,24,500
  static String formatWithoutSymbol(double amount) {
    if (amount % 1 == 0) {
      return _inrNoSymbolClean.format(amount);
    }
    return _inrNoSymbol.format(amount);
  }

  /// Format as ledger line item: e.g. + ₹5,000.00 or - ₹20,000.00
  static String formatLedger(double amount, {bool isCredit = false}) {
    final prefix = isCredit ? '+ ' : '- ';
    final absFormatted = _inrFormat.format(amount.abs());
    return '$prefix$absFormatted';
  }

  /// Parses user-entered monetary string back to double
  static double parse(String input) {
    final cleaned = input.replaceAll('₹', '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return 0.0;
    return double.tryParse(cleaned) ?? 0.0;
  }
}
