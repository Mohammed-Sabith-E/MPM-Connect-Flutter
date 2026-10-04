import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../models/customer_model.dart';
import '../services/customer_import_service.dart';
import '../../logs/repositories/audit_log_repository.dart';
import '../../organizations/models/organization_model.dart';
import '../../../core/services/tenant_path_resolver.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepo;
  final Organization _org;
  final TenantPathResolver _pathResolver;

  CustomerRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepo,
    Organization? org,
    TenantPathResolver? pathResolver,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _org = org ?? Organization.mpm,
        _pathResolver = pathResolver ?? TenantPathResolver(firestore: firestore),
        _auditLogRepo = auditLogRepo ??
            AuditLogRepository(
              firestore: firestore,
              org: org,
              pathResolver: pathResolver,
            );

  CollectionReference<Map<String, dynamic>> get _collection =>
      _pathResolver.customersCollection(_org);

  /// Stream list of customers with search and filters
  Stream<List<Customer>> streamCustomers({
    String? searchQuery,
    String? salesmanId,
    bool? hasOutstandingOnly,
    bool? isOverdueOnly,
  }) {
    Query<Map<String, dynamic>> query = _collection.where('isActive', isEqualTo: true);

    if (salesmanId != null && salesmanId.isNotEmpty) {
      query = query.where('assignedSalesmanId', isEqualTo: salesmanId);
    }

    return query.snapshots().map((snapshot) {
      var customers = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .toList();

      // In-memory multi-field search (Customer Code, Name, Phone, Normalized Phone)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryClean = searchQuery.toLowerCase().trim();
        final queryNormalized = PhoneNormalizer.normalize(queryClean);
        customers = customers.where((c) {
          final phoneNorm = c.normalizedPhone ?? PhoneNormalizer.normalize(c.phone);
          return c.name.toLowerCase().contains(queryClean) ||
              c.phone.contains(queryClean) ||
              (queryNormalized.isNotEmpty && phoneNorm.contains(queryNormalized)) ||
              c.customerCode.toLowerCase().contains(queryClean);
        }).toList();
      }

      if (hasOutstandingOnly == true) {
        customers = customers.where((c) => c.balance > 0).toList();
      }

      if (isOverdueOnly == true) {
        final now = DateTime.now();
        customers = customers.where((c) {
          if (c.balance <= 0 || c.oldestUnpaidDate == null) return false;
          return now.difference(c.oldestUnpaidDate!).inDays > 7;
        }).toList();
      }

      // Sort by name alphabetically
      customers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return customers;
    });
  }

  /// Get single customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    final doc = await _collection.doc(customerId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Customer.fromMap(doc.data()!, doc.id);
  }

  /// Generates the next sequential unique customer code in series (e.g. CUST-0001)
  Future<String> getNextCustomerCode() async {
    final countSnapshot = await _collection.count().get();
    final nextCodeNumber = (countSnapshot.count ?? 0) + 1;
    return 'CUST-${nextCodeNumber.toString().padLeft(4, '0')}';
  }

  /// Create a new customer
  Future<Customer> createCustomer({
    required String name,
    String phone = '',
    String address = '',
    String notes = '',
    String? assignedSalesmanId,
    String? assignedSalesmanName,
    required String createdBy,
    required String createdByName,
    String? customCustomerCode,
  }) async {
    // Unique series code
    final customerCode = customCustomerCode ?? await getNextCustomerCode();

    final docRef = _collection.doc();
    final now = DateTime.now();

    final customer = Customer(
      id: docRef.id,
      customerCode: customerCode,
      name: name.trim(),
      phone: phone.trim(),
      normalizedPhone: PhoneNormalizer.normalize(phone),
      organizationId: _org.id,
      address: address.trim(),
      notes: notes.trim(),
      totalInvoiced: 0.0,
      totalPaid: 0.0,
      balance: 0.0,
      assignedSalesmanId: assignedSalesmanId,
      assignedSalesmanName: assignedSalesmanName,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
    );

    await docRef.set(customer.toMap());

    await _auditLogRepo.logAction(
      userId: createdBy,
      userName: createdByName,
      action: 'CREATE_CUSTOMER',
      module: 'Customers',
      entityId: docRef.id,
      description: '$createdByName created customer $name ($customerCode)',
    );

    return customer;
  }

  /// Update customer details
  Future<void> updateCustomer({
    required String customerId,
    required String name,
    String phone = '',
    String address = '',
    String notes = '',
    String? assignedSalesmanId,
    String? assignedSalesmanName,
    required String updatedBy,
    required String updatedByName,
  }) async {
    final docRef = _collection.doc(customerId);

    await docRef.update({
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'notes': notes.trim(),
      'assignedSalesmanId': assignedSalesmanId,
      'assignedSalesmanName': assignedSalesmanName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditLogRepo.logAction(
      userId: updatedBy,
      userName: updatedByName,
      action: 'UPDATE_CUSTOMER',
      module: 'Customers',
      entityId: customerId,
      description: '$updatedByName updated customer details for $name',
    );
  }

  /// Deactivate customer
  Future<void> deactivateCustomer({
    required String customerId,
    required String customerName,
    required String userId,
    required String userName,
  }) async {
    await _collection.doc(customerId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditLogRepo.logAction(
      userId: userId,
      userName: userName,
      action: 'DEACTIVATE_CUSTOMER',
      module: 'Customers',
      entityId: customerId,
      description: '$userName deactivated customer $customerName',
    );
  }

  /// Fetches all active customers for in-memory duplicate lookup and search
  Future<List<Customer>> getAllActiveCustomersLightweight() async {
    final snapshot = await _collection.where('isActive', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Customer.fromMap(doc.data(), doc.id)).toList();
  }

  /// Bulk creates customers using chunked Firestore WriteBatches (<= 400 docs per batch).
  /// Generates sequential CUST-XXXX codes, performs duplicate-safe writes,
  /// updates progress, and creates an audit log entry.
  Future<BatchImportResult> batchCreateCustomers({
    required String importBatchId,
    required List<ImportCandidate> candidates,
    required int totalSkippedCount,
    required int totalInvalidCount,
    String? assignedSalesmanId,
    String? assignedSalesmanName,
    required String createdBy,
    required String createdByName,
    void Function(int processed, int total)? onProgress,
  }) async {
    if (candidates.isEmpty) {
      return BatchImportResult(
        isSuccess: true,
        totalAttempted: 0,
        importedCount: 0,
        skippedCount: totalSkippedCount,
        invalidCount: totalInvalidCount,
        failedCount: 0,
        importBatchId: importBatchId,
      );
    }

    final total = candidates.length;
    int importedCount = 0;
    int failedCount = 0;
    final List<String> errors = [];

    // Query current count to guarantee uninterrupted sequential CUST-XXXX numbering
    final countSnapshot = await _collection.count().get();
    int runningCodeNumber = countSnapshot.count ?? 0;

    // Firestore batch limit is 500 operations. We chunk into 400.
    const chunkSize = 400;
    for (int i = 0; i < candidates.length; i += chunkSize) {
      final chunk = candidates.sublist(
        i,
        (i + chunkSize > candidates.length) ? candidates.length : i + chunkSize,
      );

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final candidate in chunk) {
        runningCodeNumber++;
        final customerCode = 'CUST-${runningCodeNumber.toString().padLeft(4, '0')}';
        final docRef = _collection.doc();

        final customer = Customer(
          id: docRef.id,
          customerCode: customerCode,
          name: candidate.name,
          phone: candidate.rawPhone,
          normalizedPhone: candidate.normalizedPhone,
          organizationId: _org.id,
          address: '',
          notes: '',
          totalInvoiced: 0.0,
          totalPaid: 0.0,
          balance: 0.0,
          assignedSalesmanId: assignedSalesmanId,
          assignedSalesmanName: assignedSalesmanName,
          isActive: true,
          createdAt: now,
          updatedAt: now,
          createdBy: createdBy,
        );

        batch.set(docRef, customer.toMap());
      }

      try {
        await batch.commit();
        importedCount += chunk.length;
        onProgress?.call(importedCount, total);
      } catch (e) {
        failedCount += chunk.length;
        errors.add('Failed to write batch starting at index $i: $e');
        debugPrint('Batch write error: $e');
      }
    }

    // Immutable audit log
    await _auditLogRepo.logAction(
      userId: createdBy,
      userName: createdByName,
      action: 'BULK_CUSTOMER_IMPORT',
      module: 'Customers',
      entityId: importBatchId,
      description: '$createdByName imported $importedCount customers ($totalSkippedCount skipped, $totalInvalidCount invalid)',
      metadata: {
        'importBatchId': importBatchId,
        'importedCount': importedCount,
        'skippedCount': totalSkippedCount,
        'invalidCount': totalInvalidCount,
        'failedCount': failedCount,
        'assignedSalesmanId': assignedSalesmanId,
        'assignedSalesmanName': assignedSalesmanName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    return BatchImportResult(
      isSuccess: failedCount == 0,
      totalAttempted: total,
      importedCount: importedCount,
      skippedCount: totalSkippedCount,
      invalidCount: totalInvalidCount,
      failedCount: failedCount,
      importBatchId: importBatchId,
      errors: errors,
    );
  }
}
