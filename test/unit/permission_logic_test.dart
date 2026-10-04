import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/services/permission_service.dart';

void main() {
  group('PermissionService - Role-Based Permission Matrix', () {
    test('Admin role has full access across all modules', () {
      const role = UserRole.admin;
      expect(PermissionService.canViewFullDashboard(role), isTrue);
      expect(PermissionService.canViewAllCustomers(role), isTrue);
      expect(PermissionService.canCreateCustomer(role), isTrue);
      expect(PermissionService.canEditCustomer(role), isTrue);
      expect(PermissionService.canDeleteCustomer(role), isTrue);
      expect(PermissionService.canCreateTransaction(role), isTrue);
      expect(PermissionService.canRecordPayment(role), isTrue);
      expect(PermissionService.canManageSalesmen(role), isTrue);
      expect(PermissionService.canManageUsers(role), isTrue);
      expect(PermissionService.canViewAuditLogs(role), isTrue);
      expect(PermissionService.canViewReports(role), isTrue);
      expect(PermissionService.canManageSettings(role), isTrue);
    });

    test('Manager has operational access but cannot manage users or system settings', () {
      const role = UserRole.manager;
      expect(PermissionService.canViewFullDashboard(role), isTrue);
      expect(PermissionService.canViewAllCustomers(role), isTrue);
      expect(PermissionService.canCreateCustomer(role), isTrue);
      expect(PermissionService.canCreateTransaction(role), isTrue);
      expect(PermissionService.canRecordPayment(role), isTrue);
      expect(PermissionService.canManageSalesmen(role), isTrue);
      expect(PermissionService.canViewReports(role), isTrue);

      // Forbidden
      expect(PermissionService.canManageUsers(role), isFalse);
      expect(PermissionService.canViewAuditLogs(role), isFalse);
      expect(PermissionService.canManageSettings(role), isFalse);
    });

    test('Salesman has sales and customer creation permissions but cannot record settlements or view logs', () {
      const role = UserRole.salesman;
      expect(PermissionService.canCreateCustomer(role), isTrue);
      expect(PermissionService.canCreateTransaction(role), isTrue);

      // Forbidden
      expect(PermissionService.canRecordPayment(role), isFalse);
      expect(PermissionService.canManageSalesmen(role), isFalse);
      expect(PermissionService.canManageUsers(role), isFalse);
      expect(PermissionService.canViewAuditLogs(role), isFalse);
      expect(PermissionService.canManageSettings(role), isFalse);
    });

    test('Cashier has settlement and billing access but cannot manage salesmen or users', () {
      const role = UserRole.cashier;
      expect(PermissionService.canCreateTransaction(role), isTrue);
      expect(PermissionService.canRecordPayment(role), isTrue);
      expect(PermissionService.canViewPaymentHistory(role), isTrue);

      // Forbidden
      expect(PermissionService.canCreateCustomer(role), isFalse);
      expect(PermissionService.canManageSalesmen(role), isFalse);
      expect(PermissionService.canManageUsers(role), isFalse);
      expect(PermissionService.canViewAuditLogs(role), isFalse);
    });
  });
}
