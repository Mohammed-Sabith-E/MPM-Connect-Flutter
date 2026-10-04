import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRecord {
  final String id;
  final String customerId;
  final String customerName;
  final String? transactionId;
  final String organizationId;
  final double amount;
  final String paymentMethod; // Cash, Bank, UPI, Other
  final String receivedBy;
  final String? receivedByName;
  final DateTime paymentDate;
  final String notes;
  final DateTime createdAt;

  const PaymentRecord({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.transactionId,
    this.organizationId = 'mpm',
    required this.amount,
    this.paymentMethod = 'Cash',
    required this.receivedBy,
    this.receivedByName,
    required this.paymentDate,
    this.notes = '',
    required this.createdAt,
  });

  double get amountPaid => amount;
  String get receiptNumber => id.length >= 6 ? id.substring(0, 6).toUpperCase() : id;

  factory PaymentRecord.fromMap(Map<String, dynamic> map, String id) {
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

    return PaymentRecord(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      transactionId: map['transactionId'],
      organizationId: (map['organizationId'] as String?)?.isNotEmpty == true
          ? map['organizationId'] as String
          : 'mpm',
      amount: parseDouble(map['amount']),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      receivedBy: map['receivedBy'] ?? '',
      receivedByName: map['receivedByName'],
      paymentDate: parseDateTime(map['paymentDate']),
      notes: map['notes'] ?? '',
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'transactionId': transactionId,
      'organizationId': organizationId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'receivedBy': receivedBy,
      'receivedByName': receivedByName,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
