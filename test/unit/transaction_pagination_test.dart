import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/features/transactions/models/transaction_model.dart';
import 'package:mpm_connect/features/transactions/providers/transaction_pagination_provider.dart';

void main() {
  group('Transaction Pagination Tests', () {
    test('PaginatedTransactions model holds transactions and hasMore flag', () {
      final now = DateTime(2025, 5, 1);
      final tx = InvoiceTransaction(
        id: 'tx-001',
        invoiceNumber: 'INV-000001',
        customerId: 'cust-1',
        customerName: 'Al-Madina Traders',
        createdBy: 'user-admin',
        invoiceDate: now,
        invoiceAmount: 50000.0,
        previousBalance: 10000.0,
        paymentReceived: 20000.0,
        newBalance: 40000.0,
        paymentStatus: 'partial',
        createdAt: now,
        updatedAt: now,
      );

      final paginated = PaginatedTransactions(
        transactions: [tx],
        lastDocument: null,
        hasMore: true,
      );

      expect(paginated.transactions.length, equals(1));
      expect(paginated.transactions.first.invoiceNumber, equals('INV-000001'));
      expect(paginated.hasMore, isTrue);
      expect(paginated.lastDocument, isNull);
    });

    test('TransactionPaginationState copyWith works properly', () {
      const state = TransactionPaginationState(
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        searchQuery: '',
        paymentStatus: 'All',
      );

      final updated = state.copyWith(
        isLoadingMore: true,
        hasMore: false,
        searchQuery: 'INV-100',
        paymentStatus: 'credit',
      );

      expect(updated.isLoadingMore, isTrue);
      expect(updated.hasMore, isFalse);
      expect(updated.searchQuery, equals('INV-100'));
      expect(updated.paymentStatus, equals('credit'));
    });
  });
}
