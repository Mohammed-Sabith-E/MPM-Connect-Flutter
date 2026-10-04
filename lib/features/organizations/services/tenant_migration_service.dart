import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organization_model.dart';

class MigrationReport {
  final Map<String, int> totalCountByCollection;
  final Map<String, int> missingOrgCountByCollection;
  final bool isDryRun;
  final DateTime executedAt;

  MigrationReport({
    required this.totalCountByCollection,
    required this.missingOrgCountByCollection,
    required this.isDryRun,
    required this.executedAt,
  });

  int get totalDocuments => totalCountByCollection.values.fold(0, (a, b) => a + b);
  int get totalMissingOrg => missingOrgCountByCollection.values.fold(0, (a, b) => a + b);

  @override
  String toString() {
    final mode = isDryRun ? '[DRY RUN - NO WRITES]' : '[MIGRATION APPLIED]';
    final lines = [
      '--- Multi-Tenant Migration Report $mode ---',
      'Executed At: $executedAt',
      'Total documents inspected: $totalDocuments',
      'Documents lacking organizationId: $totalMissingOrg',
      'Breakdown by collection:',
    ];
    for (final entry in totalCountByCollection.entries) {
      final col = entry.key;
      final total = entry.value;
      final missing = missingOrgCountByCollection[col] ?? 0;
      lines.add('  - $col: $total total ($missing missing organizationId)');
    }
    return lines.join('\n');
  }
}

class TenantMigrationService {
  final FirebaseFirestore _firestore;

  static const List<String> legacyRootCollections = [
    'customers',
    'transactions',
    'payments',
    'salesmen',
    'users',
    'auditLogs',
  ];

  TenantMigrationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Dry-run inspection: Inspects all legacy root collections and counts
  /// documents that lack the 'organizationId' field without modifying anything.
  Future<MigrationReport> dryRunStampMpmOrg() async {
    final totalCount = <String, int>{};
    final missingCount = <String, int>{};

    for (final col in legacyRootCollections) {
      final snapshot = await _firestore.collection(col).get();
      totalCount[col] = snapshot.docs.length;
      int missing = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('organizationId') ||
            data['organizationId'] == null ||
            (data['organizationId'] as String).isEmpty) {
          missing++;
        }
      }
      missingCount[col] = missing;
    }

    return MigrationReport(
      totalCountByCollection: totalCount,
      missingOrgCountByCollection: missingCount,
      isDryRun: true,
      executedAt: DateTime.now(),
    );
  }

  /// Safe, idempotent, non-destructive batch stamp:
  /// Updates documents that do NOT have 'organizationId' to have 'organizationId: Organization.mpmOrgId' ('mpm').
  /// Uses Firestore WriteBatch in chunks up to [batchSize] (max 500 per Firestore limits).
  Future<MigrationReport> stampMpmOrgBatch({int batchSize = 400}) async {
    final totalCount = <String, int>{};
    final updatedCount = <String, int>{};

    for (final col in legacyRootCollections) {
      final snapshot = await _firestore.collection(col).get();
      totalCount[col] = snapshot.docs.length;

      final docsToUpdate = <DocumentSnapshot>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('organizationId') ||
            data['organizationId'] == null ||
            (data['organizationId'] as String).isEmpty) {
          docsToUpdate.add(doc);
        }
      }

      updatedCount[col] = docsToUpdate.length;

      // Commit in chunks of batchSize
      for (var i = 0; i < docsToUpdate.length; i += batchSize) {
        final end = (i + batchSize < docsToUpdate.length) ? i + batchSize : docsToUpdate.length;
        final chunk = docsToUpdate.sublist(i, end);

        final batch = _firestore.batch();
        for (final doc in chunk) {
          batch.update(doc.reference, {'organizationId': Organization.mpmOrgId});
        }
        await batch.commit();
      }
    }

    return MigrationReport(
      totalCountByCollection: totalCount,
      missingOrgCountByCollection: updatedCount,
      isDryRun: false,
      executedAt: DateTime.now(),
    );
  }
}
