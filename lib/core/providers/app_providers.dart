import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/customers/models/customer_model.dart';
import '../../features/customers/repositories/customer_repository.dart';
import '../../features/customers/services/customer_import_service.dart';
import '../../features/transactions/models/transaction_model.dart';
import '../../features/transactions/repositories/transaction_repository.dart';
import '../../features/payments/models/payment_model.dart';
import '../../features/payments/repositories/payment_repository.dart';
import '../../features/salesmen/models/salesman_model.dart';
import '../../features/salesmen/repositories/salesman_repository.dart';
import '../../features/logs/models/audit_log_model.dart';
import '../../features/logs/repositories/audit_log_repository.dart';
import '../../features/dashboard/models/dashboard_metrics_model.dart';
import '../../features/dashboard/repositories/dashboard_repository.dart';
import '../../features/settings/models/business_settings_model.dart';
import '../../features/organizations/models/organization_model.dart';
import '../services/tenant_path_resolver.dart';

// Firebase Instances
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Tenant Path Resolver
final tenantPathResolverProvider = Provider<TenantPathResolver>((ref) {
  return TenantPathResolver(firestore: ref.watch(firestoreProvider));
});

// Current Authenticated User State (Firestore-based)
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser == null) return Stream.value(null);

  if (authUser.isSuperAdmin) {
    return Stream.value(authUser);
  }

  // Stream the user document so org & profile are always current
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return AppUser.fromMap(doc.data()!, doc.id);
  });
});

/// Stream the active organization's document
final currentOrgDocProvider = StreamProvider<Organization?>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider).asData?.value;
  if (userProfile == null || userProfile.organizationId.isEmpty || userProfile.isSuperAdmin) {
    return Stream.value(null);
  }

  return ref
      .watch(firestoreProvider)
      .collection('organizations')
      .doc(userProfile.organizationId)
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return Organization.fromMap(doc.data()!, doc.id);
  });
});

// Current Active Organization Context
// Returns null if the user has no valid organization assigned or is Super Admin
final currentOrgProvider = Provider<Organization?>((ref) {
  final userProfileAsync = ref.watch(currentUserProfileProvider);
  if (userProfileAsync.isLoading || !userProfileAsync.hasValue) return null;

  final userProfile = userProfileAsync.value;
  if (userProfile == null || userProfile.organizationId.isEmpty || userProfile.isSuperAdmin) {
    return null;
  }

  final orgDoc = ref.watch(currentOrgDocProvider).asData?.value;
  if (orgDoc != null) return orgDoc;

  return Organization(
    id: userProfile.organizationId,
    name: userProfile.organizationId,
    status: userProfile.status,
    createdAt: DateTime.now(),
  );
});

/// All organizations stream for Super Admin
final allOrganizationsStreamProvider = StreamProvider<List<Organization>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('organizations')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Organization.fromMap(doc.data(), doc.id)).toList());
});

/// All users stream for Super Admin to inspect Admins and Salesmen across tenants
final allUsersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList());
});

// Repositories wired with Organization Context
final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final org = ref.watch(currentOrgProvider) ?? Organization.unassigned;
  return AuditLogRepository(
    firestore: ref.watch(firestoreProvider),
    org: org,
    pathResolver: ref.watch(tenantPathResolverProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firestore: ref.watch(firestoreProvider),
    auditLogRepo: AuditLogRepository(
      firestore: ref.watch(firestoreProvider),
      pathResolver: ref.watch(tenantPathResolverProvider),
    ),
  );
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final org = ref.watch(currentOrgProvider) ?? Organization.unassigned;
  return CustomerRepository(
    firestore: ref.watch(firestoreProvider),
    auditLogRepo: ref.watch(auditLogRepositoryProvider),
    org: org,
    pathResolver: ref.watch(tenantPathResolverProvider),
  );
});

final customerImportServiceProvider = Provider<CustomerImportService>((ref) {
  return CustomerImportService(
    customerRepository: ref.watch(customerRepositoryProvider),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final org = ref.watch(currentOrgProvider) ?? Organization.unassigned;
  return TransactionRepository(
    firestore: ref.watch(firestoreProvider),
    auditLogRepo: ref.watch(auditLogRepositoryProvider),
    org: org,
    pathResolver: ref.watch(tenantPathResolverProvider),
  );
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final org = ref.watch(currentOrgProvider) ?? Organization.unassigned;
  return PaymentRepository(
    firestore: ref.watch(firestoreProvider),
    auditLogRepo: ref.watch(auditLogRepositoryProvider),
    org: org,
    pathResolver: ref.watch(tenantPathResolverProvider),
  );
});

final salesmanRepositoryProvider = Provider<SalesmanRepository>((ref) {
  final org = ref.watch(currentOrgProvider) ?? Organization.unassigned;
  return SalesmanRepository(
    firestore: ref.watch(firestoreProvider),
    auditLogRepo: ref.watch(auditLogRepositoryProvider),
    org: org,
    pathResolver: ref.watch(tenantPathResolverProvider),
  );
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final org = ref.watch(currentOrgProvider) ?? Organization.unassigned;
  return DashboardRepository(
    firestore: ref.watch(firestoreProvider),
    org: org,
    pathResolver: ref.watch(tenantPathResolverProvider),
  );
});

// Stream Providers with Smart In-Memory Caching (Zero Keystroke Stream Re-subscriptions)
final customersStreamProvider = StreamProvider.autoDispose.family<List<Customer>, String?>((ref, searchQuery) {
  // Wait until org is resolved — prevents race condition causing permission-denied
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const Stream.empty();

  final link = ref.keepAlive();
  Timer? timer;
  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(const Duration(minutes: 5), () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  return ref.watch(customerRepositoryProvider).streamCustomers(searchQuery: searchQuery);
});

final transactionsStreamProvider = StreamProvider.autoDispose<List<InvoiceTransaction>>((ref) {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const Stream.empty();

  final link = ref.keepAlive();
  Timer? timer;
  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(const Duration(minutes: 3), () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  return ref.watch(transactionRepositoryProvider).streamTransactions();
});

final paymentsStreamProvider = StreamProvider.autoDispose<List<PaymentRecord>>((ref) {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const Stream.empty();

  final link = ref.keepAlive();
  Timer? timer;
  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(const Duration(minutes: 3), () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  return ref.watch(paymentRepositoryProvider).streamPayments();
});

final salesmenStreamProvider = StreamProvider<List<Salesman>>((ref) {
  // Wait until org is resolved before streaming salesmen
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const Stream.empty();

  return ref.watch(salesmanRepositoryProvider).streamSalesmen();
});

final auditLogsStreamProvider = StreamProvider.autoDispose.family<List<AuditLog>, String?>((ref, moduleFilter) {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const Stream.empty();

  return ref.watch(auditLogRepositoryProvider).streamLogs(moduleFilter: moduleFilter);
});

final dashboardMetricsStreamProvider = StreamProvider.autoDispose<DashboardMetrics>((ref) {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const Stream.empty();

  final link = ref.keepAlive();
  Timer? timer;
  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(const Duration(minutes: 2), () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  return ref.watch(dashboardRepositoryProvider).streamDashboardMetrics();
});

// Settings & Theme State
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final businessSettingsProvider = StreamProvider<BusinessSettings>((ref) {
  final currentOrg = ref.watch(currentOrgProvider);
  // Wait for org resolution
  if (currentOrg == null) return const Stream.empty();

  final pathResolver = ref.watch(tenantPathResolverProvider);
  return pathResolver.businessSettingsDoc(currentOrg).snapshots().map((doc) {
    if (doc.exists && doc.data() != null) {
      return BusinessSettings.fromMap(doc.data()!);
    }
    return BusinessSettings(
      businessName: currentOrg.isTest ? 'MPM Test Store (Sandbox)' : 'Malappuram Store',
      organizationId: currentOrg.id,
      updatedAt: DateTime.now(),
    );
  });
});
