import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_metrics_model.dart';
import '../../customers/models/customer_model.dart';
import '../../transactions/models/transaction_model.dart';
import '../../organizations/models/organization_model.dart';
import '../../../core/services/tenant_path_resolver.dart';

class DashboardRepository {
  final Organization _org;
  final TenantPathResolver _pathResolver;

  DashboardRepository({
    FirebaseFirestore? firestore,
    Organization? org,
    TenantPathResolver? pathResolver,
  })  : _org = org ?? Organization.mpm,
        _pathResolver = pathResolver ?? TenantPathResolver(firestore: firestore);

  /// Fetches real-time dashboard business metrics
  Stream<DashboardMetrics> streamDashboardMetrics() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final customersCollection = _pathResolver.customersCollection(_org);
    final transactionsCollection = _pathResolver.transactionsCollection(_org);
    final paymentsCollection = _pathResolver.paymentsCollection(_org);

    // Combine transactions, payments, and customers streams
    return customersCollection.where('isActive', isEqualTo: true).snapshots().asyncMap((customerSnap) async {
      final customers = customerSnap.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .toList();

      // Total Outstanding Amount to Get
      final double amountToGet = customers.fold(0.0, (acc, c) => acc + (c.balance > 0 ? c.balance : 0.0));

      // Overdue Customers (> 7 days)
      final List<OverdueCustomerItem> overdueList = [];
      for (final c in customers) {
        if (c.balance > 0 && c.oldestUnpaidDate != null) {
          final daysOverdue = now.difference(c.oldestUnpaidDate!).inDays;
          if (daysOverdue > 7) {
            overdueList.add(OverdueCustomerItem(
              customer: c,
              daysOverdue: daysOverdue,
              oldestUnpaidDate: c.oldestUnpaidDate!,
            ));
          }
        }
      }
      // Sort overdue by longest overdue first
      overdueList.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));

      // Fetch Today's Transactions, Today's Payments, and Recent Transactions in parallel
      // using serverAndCache to maximize offline capability and minimize query latency
      final queryResults = await Future.wait([
        transactionsCollection
            .where('invoiceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
            .where('invoiceDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
            .get(const GetOptions(source: Source.serverAndCache)),
        paymentsCollection
            .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
            .where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
            .get(const GetOptions(source: Source.serverAndCache)),
        transactionsCollection
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get(const GetOptions(source: Source.serverAndCache)),
      ]);

      final todayTxSnap = queryResults[0];
      final todayPaymentSnap = queryResults[1];
      final recentTxSnap = queryResults[2];

      double todaySales = 0.0;
      double todayCredit = 0.0;
      for (final doc in todayTxSnap.docs) {
        final amount = (doc.data()['invoiceAmount'] as num?)?.toDouble() ?? 0.0;
        final paid = (doc.data()['paymentReceived'] as num?)?.toDouble() ?? 0.0;
        todaySales += amount;
        todayCredit += (amount - paid).clamp(0.0, double.infinity);
      }

      double todayReceived = 0.0;
      for (final doc in todayPaymentSnap.docs) {
        final amt = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        todayReceived += amt;
      }

      final recentTransactions = recentTxSnap.docs
          .map((doc) => InvoiceTransaction.fromMap(doc.data(), doc.id))
          .toList();

      return DashboardMetrics(
        todaySales: todaySales,
        amountReceivedToday: todayReceived,
        creditAmountToday: todayCredit,
        totalAmountToGet: amountToGet,
        overdueCustomers: overdueList,
        recentTransactions: recentTransactions,
      );
    });
  }
}
