import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/organizations/models/organization_model.dart';

/// Centralized Firestore path and collection resolver for multi-tenancy.
///
/// All organizations use the uniform structure:
/// organizations/{organizationId}/customers
/// organizations/{organizationId}/transactions
/// organizations/{organizationId}/payments
/// organizations/{organizationId}/salesmen
/// organizations/{organizationId}/users
/// organizations/{organizationId}/logs
/// organizations/{organizationId}/settings
class TenantPathResolver {
  final FirebaseFirestore? _customFirestore;

  TenantPathResolver({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  /// Specific Organization document reference
  DocumentReference<Map<String, dynamic>> organizationDoc(String orgId) {
    return _firestore.collection('organizations').doc(orgId);
  }

  /// Organizations collection reference
  CollectionReference<Map<String, dynamic>> organizationsCollection() {
    return _firestore.collection('organizations');
  }

  /// Customers collection reference
  CollectionReference<Map<String, dynamic>> customersCollection(Organization org) {
    return _firestore
        .collection('organizations')
        .doc(org.id)
        .collection('customers');
  }

  /// Transactions collection reference
  CollectionReference<Map<String, dynamic>> transactionsCollection(Organization org) {
    return _firestore
        .collection('organizations')
        .doc(org.id)
        .collection('transactions');
  }

  /// Payments collection reference
  CollectionReference<Map<String, dynamic>> paymentsCollection(Organization org) {
    return _firestore
        .collection('organizations')
        .doc(org.id)
        .collection('payments');
  }

  /// Salesmen collection reference
  CollectionReference<Map<String, dynamic>> salesmenCollection(Organization org) {
    return _firestore
        .collection('organizations')
        .doc(org.id)
        .collection('salesmen');
  }

  /// Users subcollection reference inside organization
  CollectionReference<Map<String, dynamic>> usersCollection(Organization org) {
    return _firestore
        .collection('organizations')
        .doc(org.id)
        .collection('users');
  }

  /// Audit Logs collection reference inside organization
  CollectionReference<Map<String, dynamic>> auditLogsCollection(Organization org) {
    return _firestore
        .collection('organizations')
        .doc(org.id)
        .collection('logs');
  }

  /// Business Settings document reference
  DocumentReference<Map<String, dynamic>> businessSettingsDoc(Organization org) {
    return _firestore
        .collection('organizations')
        .doc(org.id)
        .collection('settings')
        .doc('business');
  }

  /// Invoice Counter document reference
  DocumentReference<Map<String, dynamic>> invoiceCounterDoc(Organization org) {
    return _firestore
        .collection('organizations')
        .doc(org.id)
        .collection('settings')
        .doc('counters');
  }

  // String Path Resolvers
  String customersCollectionPath(Organization org) =>
      'organizations/${org.id}/customers';

  String customerDocPath(Organization org, String id) =>
      'organizations/${org.id}/customers/$id';

  String transactionsCollectionPath(Organization org) =>
      'organizations/${org.id}/transactions';

  String transactionDocPath(Organization org, String id) =>
      'organizations/${org.id}/transactions/$id';

  String paymentsCollectionPath(Organization org) =>
      'organizations/${org.id}/payments';

  String paymentDocPath(Organization org, String id) =>
      'organizations/${org.id}/payments/$id';

  String salesmenCollectionPath(Organization org) =>
      'organizations/${org.id}/salesmen';

  String salesmanDocPath(Organization org, String id) =>
      'organizations/${org.id}/salesmen/$id';

  String usersCollectionPath(Organization org) =>
      'organizations/${org.id}/users';

  String userDocPath(Organization org, String id) =>
      'organizations/${org.id}/users/$id';

  String auditLogsCollectionPath(Organization org) =>
      'organizations/${org.id}/logs';

  String auditLogDocPath(Organization org, String id) =>
      'organizations/${org.id}/logs/$id';

  String businessSettingsDocPath(Organization org) =>
      'organizations/${org.id}/settings/business';

  String invoiceCounterDocPath(Organization org) =>
      'organizations/${org.id}/settings/counters';
}
