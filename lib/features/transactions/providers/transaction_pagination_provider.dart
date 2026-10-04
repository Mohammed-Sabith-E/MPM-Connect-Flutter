import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../../../core/providers/app_providers.dart';
import '../../customers/models/customer_model.dart';

class TransactionPaginationState {
  final List<InvoiceTransaction> transactions;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String searchQuery;
  final String paymentStatus;
  final Customer? selectedCustomer;
  final String sortBy;

  const TransactionPaginationState({
    this.transactions = const [],
    this.lastDocument,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.searchQuery = '',
    this.paymentStatus = 'All',
    this.selectedCustomer,
    this.sortBy = 'newest',
  });

  TransactionPaginationState copyWith({
    List<InvoiceTransaction>? transactions,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
    String? paymentStatus,
    Customer? selectedCustomer,
    bool clearCustomer = false,
    String? sortBy,
  }) {
    return TransactionPaginationState(
      transactions: transactions ?? this.transactions,
      lastDocument: lastDocument ?? this.lastDocument,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class TransactionPaginationNotifier extends StateNotifier<TransactionPaginationState> {
  final TransactionRepository _repository;
  static const int pageSize = 20;
  Timer? _debounceTimer;

  TransactionPaginationNotifier(this._repository) : super(const TransactionPaginationState()) {
    loadInitial();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Initial load or filter change reload
  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastDocument: null,
      hasMore: true,
    );

    try {
      final result = await _repository.fetchTransactionsPaginated(
        limit: pageSize,
        startAfterDoc: null,
        customerId: state.selectedCustomer?.id,
        paymentStatus: state.paymentStatus == 'All' ? null : state.paymentStatus.toLowerCase(),
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
      );

      state = state.copyWith(
        transactions: result.transactions,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load transactions: $e',
      );
    }
  }

  /// Cursor-based load more for infinite scroll
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final result = await _repository.fetchTransactionsPaginated(
        limit: pageSize,
        startAfterDoc: state.lastDocument,
        customerId: state.selectedCustomer?.id,
        paymentStatus: state.paymentStatus == 'All' ? null : state.paymentStatus.toLowerCase(),
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
      );

      state = state.copyWith(
        transactions: [...state.transactions, ...result.transactions],
        lastDocument: result.lastDocument ?? state.lastDocument,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more transactions: $e',
      );
    }
  }

  /// Refresh transactions without blanking screen
  Future<void> refresh() async {
    try {
      final result = await _repository.fetchTransactionsPaginated(
        limit: pageSize,
        startAfterDoc: null,
        customerId: state.selectedCustomer?.id,
        paymentStatus: state.paymentStatus == 'All' ? null : state.paymentStatus.toLowerCase(),
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
      );

      state = state.copyWith(
        transactions: result.transactions,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to refresh transactions: $e',
      );
    }
  }

  /// Update search query with debounce
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      state = state.copyWith(searchQuery: query);
      loadInitial();
    });
  }

  /// Update payment status filter
  void setPaymentStatus(String status) {
    if (state.paymentStatus == status) return;
    state = state.copyWith(paymentStatus: status);
    loadInitial();
  }

  /// Filter by specific customer
  void setCustomer(Customer? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(selectedCustomer: customer);
    }
    loadInitial();
  }
}

final transactionPaginationProvider =
    StateNotifierProvider.autoDispose<TransactionPaginationNotifier, TransactionPaginationState>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return TransactionPaginationNotifier(repo);
});
