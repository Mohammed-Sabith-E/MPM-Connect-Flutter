import 'package:cloud_firestore/cloud_firestore.dart';

typedef TransactionModel = InvoiceTransaction;

class InvoiceTransaction {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String? salesmanId;
  final String? salesmanName;
  final String createdBy;
  final String? createdByName;
  final String organizationId;
  final DateTime invoiceDate;
  final double invoiceAmount;
  final double previousBalance;
  final double paymentReceived;
  final double newBalance;
  final String paymentMethod;
  final String paymentStatus; // paid, partial, credit, overdue
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceTransaction({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    this.salesmanId,
    this.salesmanName,
    required this.createdBy,
    this.createdByName,
    this.organizationId = 'mpm',
    required this.invoiceDate,
    required this.invoiceAmount,
    required this.previousBalance,
    required this.paymentReceived,
    required this.newBalance,
    this.paymentMethod = 'Cash',
    required this.paymentStatus,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvoiceTransaction.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return InvoiceTransaction(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      salesmanId: map['salesmanId'],
      salesmanName: map['salesmanName'],
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'],
      organizationId: (map['organizationId'] as String?)?.isNotEmpty == true
          ? map['organizationId'] as String
          : 'mpm',
      invoiceDate: parseDateTime(map['invoiceDate']),
      invoiceAmount: parseDouble(map['invoiceAmount']),
      previousBalance: parseDouble(map['previousBalance']),
      paymentReceived: parseDouble(map['paymentReceived']),
      newBalance: parseDouble(map['newBalance']),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      paymentStatus: map['paymentStatus'] ?? 'credit',
      notes: map['notes'] ?? '',
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt'] ?? map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'salesmanId': salesmanId,
      'salesmanName': salesmanName,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'organizationId': organizationId,
      'invoiceDate': Timestamp.fromDate(invoiceDate),
      'invoiceAmount': invoiceAmount,
      'previousBalance': previousBalance,
      'paymentReceived': paymentReceived,
      'newBalance': newBalance,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class PaginatedTransactions {
  final List<InvoiceTransaction> transactions;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const PaginatedTransactions({
    required this.transactions,
    this.lastDocument,
    required this.hasMore,
  });
}
