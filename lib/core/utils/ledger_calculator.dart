/// Atomic Ledger & Financial Calculator for MPM Connect
/// Encapsulates all business rules for transaction balances, payments, and overdue checks
class LedgerCalculator {
  LedgerCalculator._();

  /// Core Balance Formula:
  /// New Balance = Previous Balance + New Invoice Amount - Payment Received
  static double calculateNewBalance({
    required double previousBalance,
    required double invoiceAmount,
    required double paymentReceived,
  }) {
    final balance = previousBalance + invoiceAmount - paymentReceived;
    // Round to 2 decimal places to prevent floating point inaccuracies
    return double.parse(balance.toStringAsFixed(2));
  }

  /// Calculates customer's overall balance:
  /// Outstanding Balance = Total Invoiced - Total Paid
  static double calculateCustomerBalance({
    required double totalInvoiced,
    required double totalPaid,
  }) {
    final balance = totalInvoiced - totalPaid;
    return double.parse(balance.toStringAsFixed(2));
  }

  /// Calculates remaining balance after a settlement payment
  /// Remaining Balance = Current Balance - Payment Amount
  static double calculateRemainingBalance({
    required double currentBalance,
    required double paymentAmount,
  }) {
    final remaining = currentBalance - paymentAmount;
    return double.parse(remaining.toStringAsFixed(2));
  }

  /// Validates whether a payment amount is legally acceptable:
  /// Must be > 0.
  /// Note: Payment amounts greater than current balance are accepted as advance/excess payments,
  /// resulting in a negative customer balance (credit balance).
  static String? validatePaymentAmount({
    required double paymentAmount,
    double? currentBalance,
  }) {
    if (paymentAmount <= 0) {
      return 'Payment amount must be greater than ₹0';
    }
    return null;
  }

  /// Determines the transaction payment status:
  /// - 'paid': if paid in full (paymentReceived >= invoiceAmount)
  /// - 'partial': if partial payment received (paymentReceived > 0 && paymentReceived < invoiceAmount)
  /// - 'credit': if no payment received (paymentReceived == 0)
  /// - 'overdue': if unpaid and older than 7 days
  static String determinePaymentStatus({
    required double invoiceAmount,
    required double paymentReceived,
    required DateTime invoiceDate,
    DateTime? currentDate,
  }) {
    if (paymentReceived >= invoiceAmount) {
      return 'paid';
    }

    final now = currentDate ?? DateTime.now();
    final daysDifference = now.difference(invoiceDate).inDays;

    if (daysDifference > 7) {
      return 'overdue';
    }

    if (paymentReceived > 0) {
      return 'partial';
    }

    return 'credit';
  }

  /// Determines if a customer is overdue (has outstanding balance and unpaid transaction > 7 days)
  static bool isOverdue({
    required double customerBalance,
    required DateTime? oldestUnpaidDate,
    DateTime? currentDate,
    int thresholdDays = 7,
  }) {
    if (customerBalance <= 0 || oldestUnpaidDate == null) {
      return false;
    }
    final now = currentDate ?? DateTime.now();
    return now.difference(oldestUnpaidDate).inDays > thresholdDays;
  }
}
