import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  final String id;
  final String name;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  static const String mpmOrgId = 'mpm';
  static const String testOrgId = 'test';

  const Organization({
    required this.id,
    required this.name,
    this.status = 'active',
    required this.createdAt,
    this.metadata = const {},
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isMpm => id == mpmOrgId;
  bool get isTest => false;
  String get code => (metadata['code'] as String?) ?? name.toUpperCase();

  /// Fallback when no organization is assigned
  static final Organization unassigned = Organization(
    id: 'unassigned',
    name: 'Unassigned',
    status: 'inactive',
    createdAt: DateTime(2024, 1, 1),
  );

  /// Default aliases for backward compatibility with repository constructor signatures
  static final Organization mpm = unassigned;
  static final Organization test = Organization(
    id: 'test',
    name: 'Test Organization',
    status: 'active',
    createdAt: DateTime(2024, 1, 1),
  );

  /// Validates format: org_<12 hexadecimal characters>
  static bool isValidOrgId(String orgId) {
    return RegExp(r'^org_[0-9a-fA-F]{12}$').hasMatch(orgId);
  }

  /// Generates a valid unique organization ID format: org_<12 hexadecimal characters>
  static String generateOrgId() {
    final random = Random.secure();
    final hexChars = List.generate(12, (_) => random.nextInt(16).toRadixString(16)).join();
    return 'org_$hexChars';
  }

  factory Organization.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    final orgId = (map['organizationId'] as String?)?.isNotEmpty == true
        ? map['organizationId'] as String
        : id;

    return Organization(
      id: orgId,
      name: map['name'] as String? ?? orgId,
      status: map['status'] as String? ?? (map['isActive'] == false ? 'inactive' : 'active'),
      createdAt: parseDateTime(map['createdAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizationId': id,
      'name': name,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  Organization copyWith({
    String? name,
    String? status,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
