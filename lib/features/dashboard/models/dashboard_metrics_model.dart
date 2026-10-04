import '../../customers/models/customer_model.dart';
import '../../transactions/models/transaction_model.dart';

class OverdueCustomerItem {
  final Customer customer;
  final int daysOverdue;
  final DateTime oldestUnpaidDate;

  const OverdueCustomerItem({
    required this.customer,
    required this.daysOverdue,
    required this.oldestUnpaidDate,
  });
}

class DashboardMetrics {
  final double todaySales;
  final double amountReceivedToday;
  final double creditAmountToday;
  final double totalAmountToGet;
  final List<OverdueCustomerItem> overdueCustomers;
  final List<InvoiceTransaction> recentTransactions;

  const DashboardMetrics({
    this.todaySales = 0.0,
    this.amountReceivedToday = 0.0,
    this.creditAmountToday = 0.0,
    this.totalAmountToGet = 0.0,
    this.overdueCustomers = const [],
    this.recentTransactions = const [],
  });
}
