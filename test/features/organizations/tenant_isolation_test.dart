import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/services/tenant_path_resolver.dart';
import 'package:mpm_connect/features/organizations/models/organization_model.dart';
import 'package:mpm_connect/features/customers/models/customer_model.dart';
import 'package:mpm_connect/features/auth/models/user_model.dart';
import 'package:mpm_connect/core/services/permission_service.dart';

void main() {
  const mpmOrgId = 'org_a8f93c10b72e';
  const zoboticOrgId = 'org_5e4d2a91f803';

  final mpmOrg = Organization(
    id: mpmOrgId,
    name: 'MPM',
    status: 'active',
    createdAt: DateTime(2024, 1, 1),
  );

  final zoboticOrg = Organization(
    id: zoboticOrgId,
    name: 'Zobotic',
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
  );

  group('Organization Model & ID Validation Tests', () {
    test('Validates org_<12hex> format correctly', () {
      expect(Organization.isValidOrgId('org_a8f93c10b72e'), isTrue);
      expect(Organization.isValidOrgId('org_5e4d2a91f803'), isTrue);
      expect(Organization.isValidOrgId('org_1c7b9e403d5f'), isTrue);

      // Invalid formats
      expect(Organization.isValidOrgId('mpm'), isFalse);
      expect(Organization.isValidOrgId('zobotic'), isFalse);
      expect(Organization.isValidOrgId('test'), isFalse);
      expect(Organization.isValidOrgId('org_123'), isFalse);
      expect(Organization.isValidOrgId('org_xyz123456789'), isFalse);
    });

    test('generateOrgId generates valid org_<12hex> ID', () {
      final generatedId = Organization.generateOrgId();
      expect(Organization.isValidOrgId(generatedId), isTrue);
      expect(generatedId.startsWith('org_'), isTrue);
      expect(generatedId.length, equals(16)); // 'org_' (4) + 12 hex chars = 16
    });

    test('Organization properties deserialize correctly', () {
      final map = {
        'organizationId': 'org_a8f93c10b72e',
        'name': 'MPM',
        'status': 'active',
        'createdAt': '2024-01-01T00:00:00.000Z',
      };
      final org = Organization.fromMap(map, 'org_a8f93c10b72e');
      expect(org.id, equals('org_a8f93c10b72e'));
      expect(org.name, equals('MPM'));
      expect(org.status, equals('active'));
      expect(org.isActive, isTrue);
    });
  });

  group('TenantPathResolver Uniform Organization Path Routing Tests', () {
    final resolver = TenantPathResolver();

    test('MPM routes strictly to organizations/org_a8f93c10b72e/...', () {
      expect(resolver.customersCollectionPath(mpmOrg), equals('organizations/$mpmOrgId/customers'));
      expect(resolver.customerDocPath(mpmOrg, 'cust-1'), equals('organizations/$mpmOrgId/customers/cust-1'));
      expect(resolver.transactionsCollectionPath(mpmOrg), equals('organizations/$mpmOrgId/transactions'));
      expect(resolver.transactionDocPath(mpmOrg, 'tx-1'), equals('organizations/$mpmOrgId/transactions/tx-1'));
      expect(resolver.paymentsCollectionPath(mpmOrg), equals('organizations/$mpmOrgId/payments'));
      expect(resolver.paymentDocPath(mpmOrg, 'pmt-1'), equals('organizations/$mpmOrgId/payments/pmt-1'));
      expect(resolver.salesmenCollectionPath(mpmOrg), equals('organizations/$mpmOrgId/salesmen'));
      expect(resolver.salesmanDocPath(mpmOrg, 'sm-1'), equals('organizations/$mpmOrgId/salesmen/sm-1'));
      expect(resolver.usersCollectionPath(mpmOrg), equals('organizations/$mpmOrgId/users'));
      expect(resolver.userDocPath(mpmOrg, 'usr-1'), equals('organizations/$mpmOrgId/users/usr-1'));
      expect(resolver.auditLogsCollectionPath(mpmOrg), equals('organizations/$mpmOrgId/logs'));
      expect(resolver.auditLogDocPath(mpmOrg, 'log-1'), equals('organizations/$mpmOrgId/logs/log-1'));
      expect(resolver.businessSettingsDocPath(mpmOrg), equals('organizations/$mpmOrgId/settings/business'));
      expect(resolver.invoiceCounterDocPath(mpmOrg), equals('organizations/$mpmOrgId/settings/counters'));
    });

    test('Zobotic routes strictly to organizations/org_5e4d2a91f803/...', () {
      expect(resolver.customersCollectionPath(zoboticOrg), equals('organizations/$zoboticOrgId/customers'));
      expect(resolver.customerDocPath(zoboticOrg, 'cust-2'), equals('organizations/$zoboticOrgId/customers/cust-2'));
      expect(resolver.transactionsCollectionPath(zoboticOrg), equals('organizations/$zoboticOrgId/transactions'));
      expect(resolver.transactionDocPath(zoboticOrg, 'tx-2'), equals('organizations/$zoboticOrgId/transactions/tx-2'));
      expect(resolver.paymentsCollectionPath(zoboticOrg), equals('organizations/$zoboticOrgId/payments'));
      expect(resolver.paymentDocPath(zoboticOrg, 'pmt-2'), equals('organizations/$zoboticOrgId/payments/pmt-2'));
      expect(resolver.salesmenCollectionPath(zoboticOrg), equals('organizations/$zoboticOrgId/salesmen'));
      expect(resolver.salesmanDocPath(zoboticOrg, 'sm-2'), equals('organizations/$zoboticOrgId/salesmen/sm-2'));
      expect(resolver.usersCollectionPath(zoboticOrg), equals('organizations/$zoboticOrgId/users'));
      expect(resolver.userDocPath(zoboticOrg, 'usr-2'), equals('organizations/$zoboticOrgId/users/usr-2'));
      expect(resolver.auditLogsCollectionPath(zoboticOrg), equals('organizations/$zoboticOrgId/logs'));
      expect(resolver.auditLogDocPath(zoboticOrg, 'log-2'), equals('organizations/$zoboticOrgId/logs/log-2'));
      expect(resolver.businessSettingsDocPath(zoboticOrg), equals('organizations/$zoboticOrgId/settings/business'));
      expect(resolver.invoiceCounterDocPath(zoboticOrg), equals('organizations/$zoboticOrgId/settings/counters'));
    });
  });

  group('Cross-Tenant Data Isolation & Serialization Tests', () {
    test('MPM customer serializes with organizationId org_a8f93c10b72e', () {
      final customer = Customer(
        id: 'cust-1',
        name: 'MPM Customer',
        phone: '9876543210',
        address: 'Karathode',
        customerCode: 'CUST-001',
        organizationId: mpmOrgId,
        balance: 1000.0,
        totalInvoiced: 2000.0,
        totalPaid: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final map = customer.toMap();
      expect(map['organizationId'], equals(mpmOrgId));
    });

    test('Zobotic customer can have the same phone number in isolation', () {
      final zoboticCustomer = Customer(
        id: 'cust-2',
        name: 'Zobotic Customer',
        phone: '9876543210', // Allowed: same phone in different orgs
        address: 'Calicut',
        customerCode: 'CUST-001',
        organizationId: zoboticOrgId,
        balance: 500.0,
        totalInvoiced: 500.0,
        totalPaid: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final map = zoboticCustomer.toMap();
      expect(map['organizationId'], equals(zoboticOrgId));
      expect(map['phone'], equals('9876543210'));
    });

    test('User serialization and organization binding', () {
      final mpmAdmin = AppUser(
        uid: 'uid-admin-mpm',
        name: 'MPM Admin',
        email: 'admin@mpm.com',
        phone: '9947245526',
        organizationId: mpmOrgId,
        role: UserRole.admin,
        status: 'active',
        createdAt: DateTime.now(),
      );
      final map = mpmAdmin.toMap();
      expect(map['organizationId'], equals(mpmOrgId));
      expect(map['status'], equals('active'));
      expect(map['role'], equals('admin'));
    });
  });
}
