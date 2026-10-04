import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/phone_normalizer.dart';

class Customer {
  final String id;
  final String customerCode;
  final String name;
  final String phone;
  final String? normalizedPhone;
  final String organizationId;
  final String address;
  final String notes;
  final double totalInvoiced;
  final double totalPaid;
  final double balance;
  final String? assignedSalesmanId;
  final String? assignedSalesmanName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final DateTime? oldestUnpaidDate;

  const Customer({
    required this.id,
    required this.customerCode,
    required this.name,
    required this.phone,
    this.normalizedPhone,
    this.organizationId = 'mpm',
    this.address = '',
    this.notes = '',
    this.totalInvoiced = 0.0,
    this.totalPaid = 0.0,
    this.balance = 0.0,
    this.assignedSalesmanId,
    this.assignedSalesmanName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.oldestUnpaidDate,
  });

  bool get isOverdue {
    if (balance <= 0 || oldestUnpaidDate == null) return false;
    return DateTime.now().difference(oldestUnpaidDate!).inDays >= 7;
  }

  String get phoneNumber => phone;
  String get contactPerson => notes;
  double get creditLimit => 100000.0;

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
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

    final rawPhone = map['phone'] ?? '';
    final normPhone = map['normalizedPhone'] as String? ??
        (rawPhone.isNotEmpty ? PhoneNormalizer.normalize(rawPhone) : null);

    return Customer(
      id: id,
      customerCode: map['customerCode'] ?? '',
      name: map['name'] ?? '',
      phone: rawPhone,
      normalizedPhone: normPhone,
      organizationId: (map['organizationId'] as String?)?.isNotEmpty == true
          ? map['organizationId'] as String
          : 'mpm',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      totalInvoiced: parseDouble(map['totalInvoiced']),
      totalPaid: parseDouble(map['totalPaid']),
      balance: parseDouble(map['balance']),
      assignedSalesmanId: map['assignedSalesmanId'],
      assignedSalesmanName: map['assignedSalesmanName'],
      isActive: map['isActive'] ?? true,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt'] ?? map['createdAt']),
      createdBy: map['createdBy'],
      oldestUnpaidDate: map['oldestUnpaidDate'] != null ? parseDateTime(map['oldestUnpaidDate']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerCode': customerCode,
      'name': name,
      'phone': phone,
      'normalizedPhone': normalizedPhone ?? PhoneNormalizer.normalize(phone),
      'organizationId': organizationId,
      'address': address,
      'notes': notes,
      'totalInvoiced': totalInvoiced,
      'totalPaid': totalPaid,
      'balance': balance,
      'assignedSalesmanId': assignedSalesmanId,
      'assignedSalesmanName': assignedSalesmanName,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'oldestUnpaidDate': oldestUnpaidDate != null ? Timestamp.fromDate(oldestUnpaidDate!) : null,
    };
  }

  Customer copyWith({
    String? name,
    String? phone,
    String? normalizedPhone,
    String? organizationId,
    String? address,
    String? notes,
    double? totalInvoiced,
    double? totalPaid,
    double? balance,
    String? assignedSalesmanId,
    String? assignedSalesmanName,
    bool? isActive,
    DateTime? updatedAt,
    DateTime? oldestUnpaidDate,
  }) {
    return Customer(
      id: id,
      customerCode: customerCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      normalizedPhone: normalizedPhone ?? this.normalizedPhone,
      organizationId: organizationId ?? this.organizationId,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      totalInvoiced: totalInvoiced ?? this.totalInvoiced,
      totalPaid: totalPaid ?? this.totalPaid,
      balance: balance ?? this.balance,
      assignedSalesmanId: assignedSalesmanId ?? this.assignedSalesmanId,
      assignedSalesmanName: assignedSalesmanName ?? this.assignedSalesmanName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      oldestUnpaidDate: oldestUnpaidDate ?? this.oldestUnpaidDate,
    );
  }
}
