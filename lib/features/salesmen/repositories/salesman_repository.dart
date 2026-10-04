import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/salesman_model.dart';
import '../../logs/repositories/audit_log_repository.dart';
import '../../auth/models/user_model.dart';
import '../../../core/services/permission_service.dart';
import '../../organizations/models/organization_model.dart';
import '../../../core/services/tenant_path_resolver.dart';

class SalesmanRepository {
  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepo;
  final Organization _org;
  final TenantPathResolver _pathResolver;

  SalesmanRepository({
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
      _pathResolver.salesmenCollection(_org);

  /// Stream all salesmen
  Stream<List<Salesman>> streamSalesmen({bool activeOnly = false}) {
    Query<Map<String, dynamic>> query = _collection;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Salesman.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  /// Get single salesman by ID
  Future<Salesman?> getSalesmanById(String salesmanId) async {
    final doc = await _collection.doc(salesmanId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Salesman.fromMap(doc.data()!, doc.id);
  }

  /// Create new salesman profile and account for login (Firestore-only)
  Future<Salesman> createSalesman({
    required String name,
    required String email,
    required String password,
    String phone = '',
    required String adminUid,
    required String adminName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Verify global email uniqueness
    final existingUser = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      throw Exception('This email is already registered.');
    }

    final docRef = _collection.doc();
    final now = DateTime.now();

    final salesman = Salesman(
      id: docRef.id,
      userId: docRef.id,
      name: name.trim(),
      phone: phone.trim(),
      email: cleanEmail,
      organizationId: _org.id,
      isActive: true,
      createdAt: now,
      totalSales: 0.0,
      totalCollected: 0.0,
      outstandingBalance: 0.0,
      customerCount: 0,
      transactionCount: 0,
    );

    // 1. Create salesman profile under organizations/{orgId}/salesmen/{docId}
    await docRef.set(salesman.toMap());

    // 2. Create user login document in 'users' collection with credentials
    final appUser = AppUser(
      uid: docRef.id,
      name: name.trim(),
      email: cleanEmail,
      phone: phone.trim(),
      password: password.trim(),
      organizationId: _org.id,
      role: UserRole.salesman,
      status: 'active',
      isActive: true,
      createdAt: now,
      createdBy: adminUid,
    );

    await _firestore.collection('users').doc(docRef.id).set(appUser.toMap());

    // 3. Mirror into organizations/{orgId}/users/{docId}
    await _pathResolver
        .usersCollection(_org)
        .doc(docRef.id)
        .set(appUser.toMap());

    await _auditLogRepo.logAction(
      userId: adminUid,
      userName: adminName,
      action: 'CREATE_SALESMAN',
      module: 'Salesmen',
      entityId: docRef.id,
      description: '$adminName created salesman login account for $name ($cleanEmail)',
    );

    return salesman;
  }

  /// Update salesman details
  Future<void> updateSalesman({
    required String salesmanId,
    required String name,
    required String phone,
    String email = '',
    required String adminUid,
    required String adminName,
  }) async {
    await _collection.doc(salesmanId).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditLogRepo.logAction(
      userId: adminUid,
      userName: adminName,
      action: 'UPDATE_SALESMAN',
      module: 'Salesmen',
      entityId: salesmanId,
      description: '$adminName updated details for salesman $name',
    );
  }

  /// Toggle salesman active status
  Future<void> setSalesmanActiveStatus({
    required String salesmanId,
    required String name,
    required bool isActive,
    required String adminUid,
    required String adminName,
  }) async {
    await _collection.doc(salesmanId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditLogRepo.logAction(
      userId: adminUid,
      userName: adminName,
      action: isActive ? 'ENABLE_SALESMAN' : 'DISABLE_SALESMAN',
      module: 'Salesmen',
      entityId: salesmanId,
      description: '$adminName ${isActive ? "activated" : "deactivated"} salesman $name',
    );
  }
}
