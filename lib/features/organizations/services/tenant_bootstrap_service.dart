import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/organization_model.dart';
import '../../auth/models/user_model.dart';
import '../../settings/models/business_settings_model.dart';
import '../../../core/services/permission_service.dart';

class TenantBootstrapService {
  final FirebaseFirestore _firestore;

  TenantBootstrapService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Ensures both 'mpm' (Production) and 'test' (Test) organization documents
  /// exist in the root 'organizations' collection.
  Future<void> bootstrapOrganizations() async {
    final batch = _firestore.batch();

    final mpmRef = _firestore.collection('organizations').doc(Organization.mpmOrgId);
    final mpmDoc = await mpmRef.get();
    if (!mpmDoc.exists) {
      batch.set(mpmRef, Organization.mpm.toMap());
    }

    final testRef = _firestore.collection('organizations').doc(Organization.testOrgId);
    final testDoc = await testRef.get();
    if (!testDoc.exists) {
      batch.set(testRef, Organization.test.toMap());
    }

    // Also ensure test business settings exist in organizations/test/settings/business
    final testSettingsRef = _firestore
        .collection('organizations')
        .doc(Organization.testOrgId)
        .collection('settings')
        .doc('business');
    final testSettingsDoc = await testSettingsRef.get();
    if (!testSettingsDoc.exists) {
      final defaultTestSettings = BusinessSettings(
        businessName: 'MPM Test Store',
        address: 'Test Environment, Malappuram, Kerala',
        phone: '9947245526',
        email: 'test@mpmconnect.com',
        organizationId: Organization.testOrgId,
        updatedAt: DateTime.now(),
      );
      batch.set(testSettingsRef, defaultTestSettings.toMap());
    }

    await batch.commit();
    debugPrint('TenantBootstrapService: Organizations bootstrap complete.');
  }

  /// Provisions standard test organization accounts in Firestore if they don't already exist.
  Future<List<String>> provisionTestAccounts() async {
    final testAccounts = [
      AppUser(
        uid: 'test-admin-uid',
        name: 'Test Admin',
        email: 'test-admin@mpmconnect.com',
        phone: '9999900001',
        role: UserRole.admin,
        isActive: true,
        organizationId: Organization.testOrgId,
        createdAt: DateTime.now(),
      ),
      AppUser(
        uid: 'test-manager-uid',
        name: 'Test Manager',
        email: 'test-manager@mpmconnect.com',
        phone: '9999900002',
        role: UserRole.manager,
        isActive: true,
        organizationId: Organization.testOrgId,
        createdAt: DateTime.now(),
      ),
      AppUser(
        uid: 'test-salesman-uid',
        name: 'Test Salesman',
        email: 'test-salesman@mpmconnect.com',
        phone: '9999900003',
        role: UserRole.salesman,
        isActive: true,
        organizationId: Organization.testOrgId,
        createdAt: DateTime.now(),
      ),
      AppUser(
        uid: 'test-cashier-uid',
        name: 'Test Cashier',
        email: 'test-cashier@mpmconnect.com',
        phone: '9999900004',
        role: UserRole.cashier,
        isActive: true,
        organizationId: Organization.testOrgId,
        createdAt: DateTime.now(),
      ),
    ];

    final createdEmails = <String>[];
    for (final account in testAccounts) {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: account.email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        await _firestore.collection('users').doc(account.uid).set(account.toMap());
        createdEmails.add(account.email);
      }
    }

    return createdEmails;
  }
}
