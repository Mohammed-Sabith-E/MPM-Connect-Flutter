import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String module; // Auth, Customers, Transactions, Payments, Users, Settings
  final String entityId;
  final String description;
  final String organizationId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.module,
    required this.entityId,
    required this.description,
    this.organizationId = 'mpm',
    required this.timestamp,
    this.metadata,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return AuditLog(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'System',
      action: map['action'] ?? '',
      module: map['module'] ?? 'System',
      entityId: map['entityId'] ?? '',
      description: map['description'] ?? '',
      organizationId: (map['organizationId'] as String?)?.isNotEmpty == true
          ? map['organizationId'] as String
          : 'mpm',
      timestamp: parseDateTime(map['timestamp']),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'action': action,
      'module': module,
      'entityId': entityId,
      'description': description,
      'organizationId': organizationId,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}
