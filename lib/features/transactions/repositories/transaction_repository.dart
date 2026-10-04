import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../../customers/models/customer_model.dart';
import '../../payments/models/payment_model.dart';
import '../../../core/utils/ledger_calculator.dart';
import '../../../core/utils/invoice_number_generator.dart';
import '../../logs/repositories/audit_log_repository.dart';
import '../../organizations/models/organization_model.dart';
import '../../../core/services/tenant_path_resolver.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepo;
  final Organization _org;
  final TenantPathResolver _pathResolver;

  TransactionRepository({
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
      _pathResolver.transactionsCollection(_org);

  /// Stream transactions with rich search, filters, and sorting
  Stream<List<InvoiceTransaction>> streamTransactions({
    String? customerId,
    String? salesmanId,
    String? paymentStatus,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    String sortBy = 'newest', // newest, oldest, highest_amount, highest_balance
  }) {
    Query<Map<String, dynamic>> query = _collection;

    if (customerId != null && customerId.isNotEmpty) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    if (salesmanId != null && salesmanId.isNotEmpty) {
      query = query.where('salesmanId', isEqualTo: salesmanId);
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus != 'All') {
      query = query.where('paymentStatus', isEqualTo: paymentStatus.toLowerCase());
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod != 'All') {
      query = query.where('paymentMethod', isEqualTo: paymentMethod);
    }

    return query.snapshots().map((snapshot) {
      var transactions = snapshot.docs
          .map((doc) => InvoiceTransaction.fromMap(doc.data(), doc.id))
          .toList();

      // Date Range Filter
      if (startDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        transactions = transactions.where((t) => !t.invoiceDate.isBefore(start)).toList();
      }
      if (endDate != null) {
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        transactions = transactions.where((t) => !t.invoiceDate.isAfter(end)).toList();
      }

      // Search Query (Invoice #, Customer, Salesman)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        transactions = transactions.where((t) {
          return t.invoiceNumber.toLowerCase().contains(q) ||
              t.customerName.toLowerCase().contains(q) ||
              (t.salesmanName?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      // Sorting
      switch (sortBy) {
        case 'oldest':
          transactions.sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
          break;
        case 'highest_amount':
          transactions.sort((a, b) => b.invoiceAmount.compareTo(a.invoiceAmount));
          break;
        case 'highest_balance':
          transactions.sort((a, b) => b.newBalance.compareTo(a.newBalance));
          break;
        case 'newest':
        default:
          transactions.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
          break;
      }

      return transactions;
    });
  }

  /// Fetch transactions using Firestore native cursor-based pagination
  Future<PaginatedTransactions> fetchTransactionsPaginated({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
    String? customerId,
    String? salesmanId,
    String? paymentStatus,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    String sortBy = 'newest',
  }) async {
    Query<Map<String, dynamic>> query = _collection;

    if (customerId != null && customerId.isNotEmpty) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    if (salesmanId != null && salesmanId.isNotEmpty) {
      query = query.where('salesmanId', isEqualTo: salesmanId);
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus.toLowerCase() != 'all') {
      query = query.where('paymentStatus', isEqualTo: paymentStatus.toLowerCase());
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod.toLowerCase() != 'all') {
      query = query.where('paymentMethod', isEqualTo: paymentMethod);
    }

    if (sortBy == 'oldest') {
      query = query.orderBy('invoiceDate', descending: false);
    } else {
      query = query.orderBy('invoiceDate', descending: true);
    }

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final hasSearch = searchQuery != null && searchQuery.trim().isNotEmpty;
    final fetchLimit = hasSearch ? 200 : (limit + 1);

    query = query.limit(fetchLimit);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await query.get();
    } catch (e) {
      // Fallback in case Firestore composite index is not deployed yet
      Query<Map<String, dynamic>> fallbackQuery = _collection.orderBy('invoiceDate', descending: sortBy != 'oldest');
      if (startAfterDoc != null) {
        fallbackQuery = fallbackQuery.startAfterDocument(startAfterDoc);
      }
      snapshot = await fallbackQuery.limit(hasSearch ? 200 : limit * 3).get();
    }

    final docs = snapshot.docs;
    var rawTransactions = docs
        .map((doc) => InvoiceTransaction.fromMap(doc.data(), doc.id))
        .toList();

    // If searching specifically for invoice number, also perform direct lookup
    if (hasSearch) {
      final cleanQuery = searchQuery.trim();
      final qUpper = cleanQuery.toUpperCase();

      if (qUpper.startsWith('INV-')) {
        try {
          final exactSnap = await _collection.where('invoiceNumber', isEqualTo: qUpper).get();
          for (final doc in exactSnap.docs) {
            final tx = InvoiceTransaction.fromMap(doc.data(), doc.id);
            if (!rawTransactions.any((t) => t.id == tx.id)) {
              rawTransactions.insert(0, tx);
            }
          }
        } catch (_) {}
      } else if (RegExp(r'^\d+$').hasMatch(cleanQuery)) {
        try {
          final padded = 'INV-${cleanQuery.padLeft(4, '0')}';
          final exactSnap = await _collection.where('invoiceNumber', isEqualTo: padded).get();
          for (final doc in exactSnap.docs) {
            final tx = InvoiceTransaction.fromMap(doc.data(), doc.id);
            if (!rawTransactions.any((t) => t.id == tx.id)) {
              rawTransactions.insert(0, tx);
            }
          }
        } catch (_) {}
      }
    }

    if (customerId != null && customerId.isNotEmpty) {
      rawTransactions = rawTransactions.where((t) => t.customerId == customerId).toList();
    }
    if (salesmanId != null && salesmanId.isNotEmpty) {
      rawTransactions = rawTransactions.where((t) => t.salesmanId == salesmanId).toList();
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus.toLowerCase() != 'all') {
      rawTransactions = rawTransactions.where((t) => t.paymentStatus.toLowerCase() == paymentStatus.toLowerCase()).toList();
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod.toLowerCase() != 'all') {
      rawTransactions = rawTransactions.where((t) => t.paymentMethod.toLowerCase() == paymentMethod.toLowerCase()).toList();
    }

    // Search query filtering (Invoice #, Customer Name, Salesman Name, Notes)
    if (hasSearch) {
      final q = searchQuery.toLowerCase().trim();
      rawTransactions = rawTransactions.where((t) {
        final invMatch = t.invoiceNumber.toLowerCase().contains(q);
        final custMatch = t.customerName.toLowerCase().contains(q);
        final salesmanMatch = t.salesmanName?.toLowerCase().contains(q) ?? false;
        final notesMatch = t.notes.toLowerCase().contains(q);
        return invMatch || custMatch || salesmanMatch || notesMatch;
      }).toList();
    }

    final bool hasMore = !hasSearch && (rawTransactions.length > limit);
    final transactions = (hasMore && !hasSearch) ? rawTransactions.sublist(0, limit) : rawTransactions;
    final lastDoc = docs.isNotEmpty ? docs.last : null;

    return PaginatedTransactions(
      transactions: transactions,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  /// Get single transaction by ID
  Future<InvoiceTransaction?> getTransactionById(String transactionId) async {
    final doc = await _collection.doc(transactionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return InvoiceTransaction.fromMap(doc.data()!, doc.id);
  }

  /// CRITICAL FINANCIAL OPERATION: Create Invoice / Sale Transaction Atomically
  ///
  /// Guarantees:
  /// 1. Increments sequential invoice number INV-XXXXXX
  /// 2. Fetches latest fresh customer balance from Firestore snapshot
  /// 3. Calculates: New Balance = Previous Balance + Invoice Amount - Payment Received
  /// 4. Writes transaction document
  /// 5. Writes payment document if paymentReceived > 0
  /// 6. Updates customer balance, totalInvoiced, totalPaid, oldestUnpaidDate
  /// 7. Updates salesman totals if assigned
  /// 8. Creates immutable audit log entry
  Future<InvoiceTransaction> createInvoiceTransaction({
    required String customerId,
    required double invoiceAmount,
    required double paymentReceived,
    required String paymentMethod,
    required DateTime invoiceDate,
    String notes = '',
    String? salesmanId,
    String? salesmanName,
    required String createdBy,
    required String createdByName,
  }) async {
    if (invoiceAmount <= 0) {
      throw Exception('Invoice amount must be greater than ₹0');
    }
    if (paymentReceived < 0) {
      throw Exception('Payment received cannot be negative');
    }

    final transactionDocRef = _collection.doc();
    final customerDocRef = _pathResolver.customersCollection(_org).doc(customerId);
    final paymentDocRef = _pathResolver.paymentsCollection(_org).doc();

    late InvoiceTransaction createdTransaction;

    await _firestore.runTransaction((transaction) async {
      // 1. Fetch fresh customer snapshot
      final customerSnapshot = await transaction.get(customerDocRef);
      if (!customerSnapshot.exists || customerSnapshot.data() == null) {
        throw Exception('Customer $customerId does not exist.');
      }
      final customer = Customer.fromMap(customerSnapshot.data()!, customerId);

      // 2. Compute accurate financial balances
      final previousBalance = customer.balance;
      final newBalance = LedgerCalculator.calculateNewBalance(
        previousBalance: previousBalance,
        invoiceAmount: invoiceAmount,
        paymentReceived: paymentReceived,
      );

      final paymentStatus = LedgerCalculator.determinePaymentStatus(
        invoiceAmount: invoiceAmount,
        paymentReceived: paymentReceived,
        invoiceDate: invoiceDate,
      );

      // 3. Generate sequential invoice number atomically
      final invoiceNumber = await InvoiceNumberGenerator.getNextInvoiceNumberWithTransaction(
        _firestore,
        transaction,
        org: _org,
      );

      final now = DateTime.now();

      createdTransaction = InvoiceTransaction(
        id: transactionDocRef.id,
        invoiceNumber: invoiceNumber,
        customerId: customerId,
        customerName: customer.name,
        salesmanId: salesmanId ?? customer.assignedSalesmanId,
        salesmanName: salesmanName ?? customer.assignedSalesmanName,
        createdBy: createdBy,
        createdByName: createdByName,
        organizationId: _org.id,
        invoiceDate: invoiceDate,
        invoiceAmount: invoiceAmount,
        previousBalance: previousBalance,
        paymentReceived: paymentReceived,
        newBalance: newBalance,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        notes: notes.trim(),
        createdAt: now,
        updatedAt: now,
      );

      // 4. Save Invoice Transaction
      transaction.set(transactionDocRef, createdTransaction.toMap());

      // 5. If payment received > 0, write separate PaymentRecord
      if (paymentReceived > 0) {
        final paymentRecord = PaymentRecord(
          id: paymentDocRef.id,
          customerId: customerId,
          customerName: customer.name,
          transactionId: transactionDocRef.id,
          organizationId: _org.id,
          amount: paymentReceived,
          paymentMethod: paymentMethod,
          receivedBy: createdBy,
          receivedByName: createdByName,
          paymentDate: invoiceDate,
          notes: 'Received against invoice $invoiceNumber',
          createdAt: now,
        );
        transaction.set(paymentDocRef, paymentRecord.toMap());
      }

      // 6. Update Customer Ledger Totals
      DateTime? updatedOldestUnpaidDate = customer.oldestUnpaidDate;
      if (newBalance > 0 && updatedOldestUnpaidDate == null) {
        updatedOldestUnpaidDate = invoiceDate;
      } else if (newBalance <= 0) {
        updatedOldestUnpaidDate = null;
      }

      transaction.update(customerDocRef, {
        'totalInvoiced': customer.totalInvoiced + invoiceAmount,
        'totalPaid': customer.totalPaid + paymentReceived,
        'balance': newBalance,
        'oldestUnpaidDate': updatedOldestUnpaidDate != null
            ? Timestamp.fromDate(updatedOldestUnpaidDate)
            : null,
        'updatedAt': Timestamp.fromDate(now),
      });

      // 7. Update Salesman stats if applicable
      final activeSalesmanId = salesmanId ?? customer.assignedSalesmanId;
      if (activeSalesmanId != null && activeSalesmanId.isNotEmpty) {
        final salesmanDocRef = _pathResolver.salesmenCollection(_org).doc(activeSalesmanId);
        final salesmanSnapshot = await transaction.get(salesmanDocRef);
        if (salesmanSnapshot.exists) {
          final currentSales = (salesmanSnapshot.data()?['totalSales'] as num?)?.toDouble() ?? 0.0;
          final currentCollected = (salesmanSnapshot.data()?['totalCollected'] as num?)?.toDouble() ?? 0.0;
          final currentOutstanding = (salesmanSnapshot.data()?['outstandingBalance'] as num?)?.toDouble() ?? 0.0;
          final currentTxCount = (salesmanSnapshot.data()?['transactionCount'] as num?)?.toInt() ?? 0;

          transaction.update(salesmanDocRef, {
            'totalSales': currentSales + invoiceAmount,
            'totalCollected': currentCollected + paymentReceived,
            'outstandingBalance': currentOutstanding + (invoiceAmount - paymentReceived),
            'transactionCount': currentTxCount + 1,
          });
        }
      }

      // 8. Immutable Audit Log Entry
      _auditLogRepo.logActionWithTransaction(
        transaction,
        userId: createdBy,
        userName: createdByName,
        action: 'CREATE_INVOICE',
        module: 'Transactions',
        entityId: transactionDocRef.id,
        description: '$createdByName generated invoice $invoiceNumber for ${customer.name} (Amount: ₹$invoiceAmount, Paid: ₹$paymentReceived, New Balance: ₹$newBalance)',
        metadata: {
          'invoiceNumber': invoiceNumber,
          'customerId': customerId,
          'invoiceAmount': invoiceAmount,
          'paymentReceived': paymentReceived,
          'newBalance': newBalance,
        },
      );
    });

    return createdTransaction;
  }
}
