import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/services/permission_service.dart';
import 'package:mpm_connect/features/auth/models/user_model.dart';
import 'package:mpm_connect/features/auth/repositories/auth_repository.dart';

void main() {
  group('Firestore-Only Auth & 3-Tier User Role Tests', () {
    test('UserRole enum correctly includes superAdmin and parses string variants', () {
      expect(UserRole.superAdmin.label, 'Super Admin');
      expect(UserRole.fromString('superadmin'), UserRole.superAdmin);
      expect(UserRole.fromString('super_admin'), UserRole.superAdmin);
      expect(UserRole.fromString('super admin'), UserRole.superAdmin);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('salesman'), UserRole.salesman);
    });

    test('AppUser.superAdmin factory generates valid super admin user object', () {
      final superUser = AppUser.superAdmin();
      expect(superUser.uid, 'super_admin_id');
      expect(superUser.email, 'superadmin@gmail.com');
      expect(superUser.role, UserRole.superAdmin);
      expect(superUser.isSuperAdmin, isTrue);
      expect(superUser.isAdmin, isFalse);
      expect(superUser.isSalesman, isFalse);
      expect(superUser.isActive, isTrue);
    });

    test('AppUser handles password field serialization and deserialization', () {
      final adminUser = AppUser(
        uid: 'user_123',
        name: 'Admin MPM',
        email: 'admin@mpm.com',
        phone: '9876543210',
        password: 'admin_secret_123',
        organizationId: 'org_a8f93c10b72e',
        role: UserRole.admin,
        status: 'active',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final map = adminUser.toMap();
      expect(map['password'], 'admin_secret_123');
      expect(map['role'], 'admin');
      expect(map['organizationId'], 'org_a8f93c10b72e');

      final reconstructed = AppUser.fromMap(map, 'user_123');
      expect(reconstructed.uid, 'user_123');
      expect(reconstructed.password, 'admin_secret_123');
      expect(reconstructed.isAdmin, isTrue);
      expect(reconstructed.organizationId, 'org_a8f93c10b72e');
    });

    test('Super Admin default credentials match user specification', () {
      expect(AuthRepository.superAdminEmail, 'superadmin@gmail.com');
      expect(AuthRepository.superAdminPassword, 'super123');
    });

    test('Salesman role user flags behave correctly', () {
      final salesman = AppUser(
        uid: 'sales_001',
        name: 'Sales Rep 1',
        email: 'sales@mpm.com',
        phone: '9123456780',
        password: 'sales_pass_123',
        organizationId: 'org_a8f93c10b72e',
        role: UserRole.salesman,
        createdAt: DateTime.now(),
      );

      expect(salesman.isSalesman, isTrue);
      expect(salesman.isAdmin, isFalse);
      expect(salesman.isSuperAdmin, isFalse);
    });
  });
}
