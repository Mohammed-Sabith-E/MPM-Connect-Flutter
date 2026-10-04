import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/audit_log_model.dart';
import '../../organizations/models/organization_model.dart';
import '../../../core/services/tenant_path_resolver.dart';

class AuditLogRepository {
  final Organization _org;
  final TenantPathResolver _pathResolver;

  AuditLogRepository({
    FirebaseFirestore? firestore,
    Organization? org,
    TenantPathResolver? pathResolver,
  })  : _org = org ?? Organization.mpm,
        _pathResolver = pathResolver ?? TenantPathResolver(firestore: firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _pathResolver.auditLogsCollection(_org);

  /// Creates an immutable audit log record
  Future<void> logAction({
    required String userId,
    required String userName,
    required String action,
    required String module,
    required String entityId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final logId = const Uuid().v4();
      final log = AuditLog(
        id: logId,
        userId: userId,
        userName: userName,
        action: action,
        module: module,
        entityId: entityId,
        description: description,
        organizationId: _org.id,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _collection.doc(logId).set(log.toMap());
    } catch (e) {
      // Audit log failures should not crash user operations, but be captured in console
      debugPrint('Audit logging failed: $e');
    }
  }

  /// Appends audit log inside an existing Firestore transaction
  void logActionWithTransaction(
    Transaction transaction, {
    required String userId,
    required String userName,
    required String action,
    required String module,
    required String entityId,
    required String description,
    Map<String, dynamic>? metadata,
  }) {
    final logId = const Uuid().v4();
    final logDoc = _collection.doc(logId);
    final log = AuditLog(
      id: logId,
      userId: userId,
      userName: userName,
      action: action,
      module: module,
      entityId: entityId,
      description: description,
      organizationId: _org.id,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    transaction.set(logDoc, log.toMap());
  }

  /// Stream audit logs for admin viewer
  Stream<List<AuditLog>> streamLogs({
    String? moduleFilter,
    String? userFilter,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _collection;

    return query.snapshots().map((snapshot) {
      var logs = snapshot.docs.map((doc) => AuditLog.fromMap(doc.data(), doc.id)).toList();

      if (moduleFilter != null && moduleFilter.isNotEmpty && moduleFilter.toLowerCase() != 'all') {
        logs = logs.where((l) => l.module.toLowerCase() == moduleFilter.toLowerCase()).toList();
      }
      if (userFilter != null && userFilter.isNotEmpty) {
        logs = logs.where((l) => l.userName.toLowerCase() == userFilter.toLowerCase()).toList();
      }

      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (logs.length > limit) {
        logs = logs.sublist(0, limit);
      }
      return logs;
    });
  }
}
