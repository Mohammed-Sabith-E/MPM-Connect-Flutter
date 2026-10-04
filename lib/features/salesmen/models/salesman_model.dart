import 'package:cloud_firestore/cloud_firestore.dart';

class Salesman {
  final String id;
  final String? userId;
  final String name;
  final String phone;
  final String email;
  final String organizationId;
  final bool isActive;
  final DateTime createdAt;
  final double totalSales;
  final double totalCollected;
  final double outstandingBalance;
  final int customerCount;
  final int transactionCount;

  const Salesman({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    this.email = '',
    this.organizationId = 'mpm',
    this.isActive = true,
    required this.createdAt,
    this.totalSales = 0.0,
    this.totalCollected = 0.0,
    this.outstandingBalance = 0.0,
    this.customerCount = 0,
    this.transactionCount = 0,
  });

  factory Salesman.fromMap(Map<String, dynamic> map, String id) {
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

    return Salesman(
      id: id,
      userId: map['userId'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      organizationId: (map['organizationId'] as String?)?.isNotEmpty == true
          ? map['organizationId'] as String
          : 'mpm',
      isActive: map['isActive'] ?? true,
      createdAt: parseDateTime(map['createdAt']),
      totalSales: parseDouble(map['totalSales']),
      totalCollected: parseDouble(map['totalCollected']),
      outstandingBalance: parseDouble(map['outstandingBalance']),
      customerCount: map['customerCount'] ?? 0,
      transactionCount: map['transactionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'organizationId': organizationId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalSales': totalSales,
      'totalCollected': totalCollected,
      'outstandingBalance': outstandingBalance,
      'customerCount': customerCount,
      'transactionCount': transactionCount,
    };
  }

  Salesman copyWith({
    String? name,
    String? phone,
    String? email,
    String? organizationId,
    bool? isActive,
    double? totalSales,
    double? totalCollected,
    double? outstandingBalance,
    int? customerCount,
    int? transactionCount,
  }) {
    return Salesman(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      organizationId: organizationId ?? this.organizationId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      totalSales: totalSales ?? this.totalSales,
      totalCollected: totalCollected ?? this.totalCollected,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      customerCount: customerCount ?? this.customerCount,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }
}
