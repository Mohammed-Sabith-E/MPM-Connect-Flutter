import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/permission_service.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? password;
  final String organizationId;
  final UserRole role;
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.password,
    this.organizationId = '',
    required this.role,
    this.status = 'active',
    this.isActive = true,
    required this.createdAt,
    this.createdBy,
    this.lastLoginAt,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdmin => role == UserRole.admin;
  bool get isSalesman => role == UserRole.salesman;

  factory AppUser.superAdmin({
    String email = 'superadmin@gmail.com',
  }) {
    return AppUser(
      uid: 'super_admin_id',
      name: 'Super Admin',
      email: email,
      phone: '',
      organizationId: 'system',
      role: UserRole.superAdmin,
      status: 'active',
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    final statusVal = (map['status'] as String?)?.toLowerCase();
    final isActiveVal = map['isActive'] as bool? ?? (statusVal == null || statusVal == 'active');

    return AppUser(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      password: map['password'] as String?,
      organizationId: map['organizationId'] as String? ?? '',
      role: UserRole.fromString(map['role']),
      status: statusVal ?? (isActiveVal ? 'active' : 'inactive'),
      isActive: isActiveVal,
      createdAt: parseDateTime(map['createdAt']),
      createdBy: map['createdBy'],
      lastLoginAt: map['lastLoginAt'] != null ? parseDateTime(map['lastLoginAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      if (password != null) 'password': password,
      'organizationId': organizationId,
      'role': role.label.toLowerCase(),
      'status': isActive ? 'active' : 'inactive',
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? password,
    String? organizationId,
    UserRole? role,
    String? status,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      organizationId: organizationId ?? this.organizationId,
      role: role ?? this.role,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      createdBy: createdBy,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
