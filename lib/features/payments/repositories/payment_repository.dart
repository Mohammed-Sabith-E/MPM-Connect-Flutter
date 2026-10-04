import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../../customers/models/customer_model.dart';
import '../../../core/utils/ledger_calculator.dart';
import '../../logs/repositories/audit_log_repository.dart';
import '../../organizations/models/organization_model.dart';
import '../../../core/services/tenant_path_resolver.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepo;
  final Organization _org;
  final TenantPathResolver _pathResolver;

  PaymentRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepo,
    Organization? org,
    TenantPathResolver? pathResolver,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _org = org ?? Organization.mpm,
        _pathResolver = pathResolver ?? TenantPathResolver(firestore: firestore),
        _auditLogRepo = auditLogRepo ??
            AuditLogRepository(
              firestore: firestore,
              org: org,
              pathResolver: pathResolver,
            );

  CollectionReference<Map<String, dynamic>> get _collection =>
      _pathResolver.paymentsCollection(_org);

  /// Stream payments by customer, payment method, or date range
  Stream<List<PaymentRecord>> streamPayments({
    String? customerId,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _collection;

    if (customerId != null && customerId.isNotEmpty) {
      query = query.where('customerId', isEqualTo: customerId);
    }

    return query.snapshots().map((snapshot) {
      var payments = snapshot.docs
          .map((doc) => PaymentRecord.fromMap(doc.data(), doc.id))
          .toList();

      if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod.toLowerCase() != 'all') {
        payments = payments
            .where((p) => p.paymentMethod.toLowerCase() == paymentMethod.toLowerCase())
            .toList();
      }

      if (startDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        payments = payments.where((p) => !p.paymentDate.isBefore(start)).toList();
      }
      if (endDate != null) {
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        payments = payments.where((p) => !p.paymentDate.isAfter(end)).toList();
      }

      payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return payments;
    });
  }

  /// CRITICAL FINANCIAL SETTLEMENT: Record Payment Atomically
  ///
  /// Guarantees:
  /// 1. Reads fresh customer balance inside Firestore transaction
  /// 2. Validates amount > 0 (excess payments create negative credit balance)
  /// 3. Computes Remaining Balance = Current Balance - Payment Amount
  /// 4. If remaining <= 0, clears oldestUnpaidDate
  /// 5. Writes PaymentRecord
  /// 6. Updates Customer totalPaid and balance
  /// 7. Updates Salesman collection if customer is assigned
  /// 8. Creates immutable audit log entry
  Future<PaymentRecord> recordSettlement({
    required String customerId,
    String? transactionId,
    required double amount,
    required String paymentMethod,
    required DateTime paymentDate,
    String notes = '',
    required String receivedBy,
    required String receivedByName,
  }) async {
    final paymentDocRef = _collection.doc();
    final customerDocRef = _pathResolver.customersCollection(_org).doc(customerId);

    late PaymentRecord recordedPayment;

    await _firestore.runTransaction((transaction) async {
      // 1. Fetch fresh customer document
      final customerSnapshot = await transaction.get(customerDocRef);
      if (!customerSnapshot.exists || customerSnapshot.data() == null) {
        throw Exception('Customer not found in database.');
      }
      final customer = Customer.fromMap(customerSnapshot.data()!, customerId);

      // 2. Validate payment amount
      final validationError = LedgerCalculator.validatePaymentAmount(
        paymentAmount: amount,
        currentBalance: customer.balance,
      );
      if (validationError != null) {
        throw Exception(validationError);
      }

      // 3. Compute remaining balance
      final remainingBalance = LedgerCalculator.calculateRemainingBalance(
        currentBalance: customer.balance,
        paymentAmount: amount,
      );

      final now = DateTime.now();

      recordedPayment = PaymentRecord(
        id: paymentDocRef.id,
        customerId: customerId,
        customerName: customer.name,
        transactionId: transactionId,
        organizationId: _org.id,
        amount: amount,
        paymentMethod: paymentMethod,
        receivedBy: receivedBy,
        receivedByName: receivedByName,
        paymentDate: paymentDate,
        notes: notes.trim(),
        createdAt: now,
      );

      // 4. Save Payment document
      transaction.set(paymentDocRef, recordedPayment.toMap());

      // 5. Update Customer financial totals
      final Map<String, dynamic> customerUpdates = {
        'totalPaid': customer.totalPaid + amount,
        'balance': remainingBalance,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (remainingBalance <= 0) {
        customerUpdates['oldestUnpaidDate'] = null;
      }

      transaction.update(customerDocRef, customerUpdates);

      // 6. Update Salesman collections if customer has assigned salesman
      if (customer.assignedSalesmanId != null && customer.assignedSalesmanId!.isNotEmpty) {
        final salesmanDocRef = _pathResolver.salesmenCollection(_org).doc(customer.assignedSalesmanId);
        final salesmanSnapshot = await transaction.get(salesmanDocRef);
        if (salesmanSnapshot.exists) {
          final currentCollected = (salesmanSnapshot.data()?['totalCollected'] as num?)?.toDouble() ?? 0.0;
          final currentOutstanding = (salesmanSnapshot.data()?['outstandingBalance'] as num?)?.toDouble() ?? 0.0;

          transaction.update(salesmanDocRef, {
            'totalCollected': currentCollected + amount,
            'outstandingBalance': (currentOutstanding - amount).clamp(0.0, double.infinity),
          });
        }
      }

      // 7. Write immutable audit log
      _auditLogRepo.logActionWithTransaction(
        transaction,
        userId: receivedBy,
        userName: receivedByName,
        action: 'RECORD_PAYMENT',
        module: 'Payments',
        entityId: paymentDocRef.id,
        description: '$receivedByName collected payment of ₹$amount for ${customer.name} via $paymentMethod (Remaining Balance: ₹$remainingBalance)',
        metadata: {
          'customerId': customerId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'remainingBalance': remainingBalance,
        },
      );
    });

    return recordedPayment;
  }
}
